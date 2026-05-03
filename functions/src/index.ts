import crypto from "node:crypto";

import admin from "firebase-admin";
import { defineSecret, defineString } from "firebase-functions/params";
import { logger, setGlobalOptions } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();

setGlobalOptions({
  region: "asia-south1",
  maxInstances: 10,
  timeoutSeconds: 120,
  memory: "512MiB"
});

const openAiApiKey = defineSecret("OPENAI_API_KEY");
const ingestToken = defineSecret("INGEST_TOKEN");
const aiApiBaseUrl = defineString("AI_API_BASE_URL", {
  default: "https://api.openai.com/v1"
});
const aiModel = defineString("AI_MODEL", {
  default: "gpt-4.1-mini"
});

type JobRecord = {
  source: string;
  sourceJobId: string;
  title: string;
  company: string;
  location: string;
  url: string;
  description: string;
  category: string;
  publishedAt: string;
  salary?: string;
  salaryMin?: number;
  salaryMax?: number;
};

type ResumeRequest = {
  resumeText?: string;
  targetJobDescription?: string;
  templateStyle?: string;
};

const db = admin.firestore();
const maxResumeCharacters = 20000;
const maxJobDescriptionCharacters = 15000;
const dailyAiLimit = 25;

export const ingestJobsScheduled = onSchedule(
  {
    schedule: "every 2 hours",
    timeZone: "Asia/Kolkata"
  },
  async () => {
    await ingestJobs();
  }
);

export const ingestJobsNow = onRequest(
  {
    secrets: [ingestToken],
    cors: true
  },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({ error: "Use POST." });
      return;
    }

    const expectedToken = ingestToken.value();
    const providedToken = request.header("x-ingest-token") ?? "";
    if (!expectedToken || providedToken !== expectedToken) {
      response.status(401).json({ error: "Invalid ingest token." });
      return;
    }

    const result = await ingestJobs();
    response.json(result);
  }
);

export const tailorResume = onRequest(
  {
    secrets: [openAiApiKey],
    cors: true,
    timeoutSeconds: 120
  },
  async (request, response) => {
    if (request.method === "OPTIONS") {
      response.status(204).send("");
      return;
    }
    if (request.method !== "POST") {
      response.status(405).json({ error: "Use POST." });
      return;
    }

    const idToken = parseBearerToken(request.header("authorization"));
    if (!idToken) {
      response.status(401).json({ error: "Missing Firebase ID token." });
      return;
    }

    let uid: string;
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      uid = decodedToken.uid;
    } catch {
      response.status(401).json({ error: "Invalid Firebase ID token." });
      return;
    }

    const body = request.body as ResumeRequest;
    const resumeText = body.resumeText?.trim() ?? "";
    const targetJobDescription = body.targetJobDescription?.trim() ?? "";
    const templateStyle = body.templateStyle?.trim() || "Modern ATS";

    if (!resumeText || !targetJobDescription) {
      response.status(400).json({
        error: "resumeText and targetJobDescription are required."
      });
      return;
    }

    if (resumeText.length > maxResumeCharacters ||
      targetJobDescription.length > maxJobDescriptionCharacters) {
      response.status(413).json({
        error: "Resume or job description is too long."
      });
      return;
    }

    const allowed = await consumeAiQuota(uid);
    if (!allowed) {
      response.status(429).json({
        error: "Daily AI tailoring limit reached. Try again tomorrow."
      });
      return;
    }

    try {
      const result = await callAiResumeService({
        resumeText,
        targetJobDescription,
        templateStyle
      });
      response.json(result);
    } catch (error) {
      logger.error("AI tailoring failed", error);
      response.status(502).json({
        error: "AI tailoring failed. Please try again."
      });
    }
  }
);

async function ingestJobs(): Promise<{ fetched: number; written: number }> {
  const sourceResults = await Promise.allSettled([
    fetchRemotiveJobs(),
    fetchArbeitnowJobs()
  ]);

  const jobs = sourceResults.flatMap((result) => {
    if (result.status === "fulfilled") {
      return result.value;
    }
    logger.error("Job source failed", result.reason);
    return [];
  });

  const uniqueJobs = dedupeJobs(jobs).slice(0, 400);
  let written = 0;

  for (let index = 0; index < uniqueJobs.length; index += 450) {
    const batch = db.batch();
    const chunk = uniqueJobs.slice(index, index + 450);
    for (const job of chunk) {
      const id = stableJobId(job);
      const ref = db.collection("jobs").doc(id);
      batch.set(
        ref,
        {
          ...job,
          id,
          active: true,
          lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        { merge: true }
      );
      written += 1;
    }
    await batch.commit();
  }

  await db.collection("system").doc("jobIngestion").set(
    {
      fetched: jobs.length,
      written,
      sources: sourceResults.map((result, index) => ({
        source: index === 0 ? "remotive" : "arbeitnow",
        ok: result.status === "fulfilled",
        count: result.status === "fulfilled" ? result.value.length : 0,
        error: result.status === "rejected" ? String(result.reason) : null
      })),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    { merge: true }
  );

  logger.info("Job ingestion complete", { fetched: jobs.length, written });
  return { fetched: jobs.length, written };
}

async function consumeAiQuota(uid: string): Promise<boolean> {
  const today = new Date().toISOString().slice(0, 10);
  const ref = db.collection("aiUsage").doc(`${uid}_${today}`);

  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const count = Number(snapshot.data()?.count ?? 0);
    if (count >= dailyAiLimit) {
      return false;
    }
    transaction.set(
      ref,
      {
        uid,
        day: today,
        count: count + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      },
      { merge: true }
    );
    return true;
  });
}

async function fetchRemotiveJobs(): Promise<JobRecord[]> {
  const response = await fetch("https://remotive.com/api/remote-jobs");
  if (!response.ok) {
    throw new Error(`Remotive failed with ${response.status}`);
  }

  const payload = await response.json() as {
    jobs?: Array<Record<string, unknown>>;
  };

  return (payload.jobs ?? []).slice(0, 200).map((job) => {
    const salary = stringValue(job.salary);
    const salaryRange = parseSalaryRange(salary);
    return {
      source: "remotive",
      sourceJobId: stringValue(job.id) || stringValue(job.url),
      title: stringValue(job.title) || "Untitled role",
      company: stringValue(job.company_name) || "Unknown company",
      location: stringValue(job.candidate_required_location) || "Remote",
      url: stringValue(job.url),
      description: stringValue(job.description),
      category: stringValue(job.category) || "Remote job",
      publishedAt: normalizeDate(stringValue(job.publication_date)),
      salary,
      salaryMin: salaryRange.min,
      salaryMax: salaryRange.max
    };
  }).filter((job) => Boolean(job.url));
}

async function fetchArbeitnowJobs(): Promise<JobRecord[]> {
  const response = await fetch("https://www.arbeitnow.com/api/job-board-api");
  if (!response.ok) {
    throw new Error(`Arbeitnow failed with ${response.status}`);
  }

  const payload = await response.json() as {
    data?: Array<Record<string, unknown>>;
  };

  return (payload.data ?? []).slice(0, 200).map((job) => {
    const tags = Array.isArray(job.tags) ? job.tags.map(String) : [];
    return {
      source: "arbeitnow",
      sourceJobId: stringValue(job.slug) || stringValue(job.url),
      title: stringValue(job.title) || "Untitled role",
      company: stringValue(job.company_name) || "Unknown company",
      location: stringValue(job.location) || "Remote",
      url: stringValue(job.url),
      description: stringValue(job.description),
      category: tags[0] ?? "Job board",
      publishedAt: normalizeDate(stringValue(job.created_at))
    };
  }).filter((job) => Boolean(job.url));
}

async function callAiResumeService(input: {
  resumeText: string;
  targetJobDescription: string;
  templateStyle: string;
}) {
  const baseUrl = aiApiBaseUrl.value().replace(/\/$/, "");
  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${openAiApiKey.value()}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: aiModel.value(),
      temperature: 0.2,
      messages: [
        {
          role: "system",
          content: "You are an expert resume writer. Return strict JSON only."
        },
        {
          role: "user",
          content: [
            "Tailor this resume for the target job description.",
            `Use a ${input.templateStyle} resume style.`,
            "Improve ATS keyword alignment without inventing facts.",
            "Return JSON with keys optimizedResume, coverLetter, atsScore,",
            "keywords, suggestions.",
            "",
            "Resume:",
            input.resumeText,
            "",
            "Target job description:",
            input.targetJobDescription
          ].join("\n")
        }
      ]
    })
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`AI endpoint failed with ${response.status}: ${details}`);
  }

  const payload = await response.json() as {
    choices?: Array<{ message?: { content?: string } }>;
  };
  const content = payload.choices?.[0]?.message?.content ?? "{}";
  const parsed = parseJsonObject(content);

  return {
    optimizedResume: stringValue(parsed.optimizedResume),
    coverLetter: stringValue(parsed.coverLetter),
    atsScore: numberValue(parsed.atsScore, 75),
    keywords: stringArray(parsed.keywords),
    suggestions: stringArray(parsed.suggestions),
    generatedAt: new Date().toISOString()
  };
}

function dedupeJobs(jobs: JobRecord[]): JobRecord[] {
  const seen = new Set<string>();
  const unique: JobRecord[] = [];

  for (const job of jobs) {
    const key = `${job.company}|${job.title}|${job.location}`.toLowerCase();
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    unique.push(job);
  }

  return unique.sort((a, b) => b.publishedAt.localeCompare(a.publishedAt));
}

function stableJobId(job: JobRecord): string {
  return crypto
    .createHash("sha256")
    .update(`${job.source}:${job.sourceJobId}:${job.url}`)
    .digest("hex")
    .slice(0, 40);
}

function normalizeDate(value: string): string {
  if (!value) {
    return new Date().toISOString();
  }

  if (/^\d+$/.test(value)) {
    return new Date(Number(value) * 1000).toISOString();
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString();
}

function parseSalaryRange(salary: string): { min?: number; max?: number } {
  const values = [...salary.replace(/,/g, "").matchAll(/(\d{2,3})(?:k)?/gi)]
    .map((match) => Number(match[1]))
    .filter((value) => Number.isFinite(value))
    .map((value) => value < 1000 ? value * 1000 : value)
    .sort((a, b) => a - b);

  return {
    min: values[0],
    max: values.length > 1 ? values[values.length - 1] : undefined
  };
}

function parseBearerToken(header?: string): string | undefined {
  const match = header?.match(/^Bearer\s+(.+)$/i);
  return match?.[1];
}

function parseJsonObject(content: string): Record<string, unknown> {
  try {
    return JSON.parse(content) as Record<string, unknown>;
  } catch {
    const start = content.indexOf("{");
    const end = content.lastIndexOf("}");
    if (start >= 0 && end > start) {
      return JSON.parse(content.slice(start, end + 1)) as Record<string, unknown>;
    }
    return {};
  }
}

function stringValue(value: unknown): string {
  if (value === null || value === undefined) {
    return "";
  }
  return String(value);
}

function numberValue(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function stringArray(value: unknown): string[] {
  return Array.isArray(value) ? value.map(String) : [];
}
