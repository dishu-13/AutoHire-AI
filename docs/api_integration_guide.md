# API Integration Guide

## No-Cost Job Sources

The free version calls public job APIs directly from Flutter:

```text
Flutter app -> Remotive public API
Flutter app -> Arbeitnow public API
```

Current sources:

- Himalayas India/worldwide remote jobs API.
- The Muse public jobs API filtered to India.
- Jobicy APAC remote jobs API.
- RemoteOK public remote jobs API.
- We Work Remotely RSS feed.
- Remotive: remote jobs API.
- Arbeitnow: public job board API.
- Optional Adzuna India API when `ADZUNA_APP_ID` and `ADZUNA_APP_KEY` are
  supplied at build time.

The app de-duplicates roles, sorts by latest publish date, and shows the source name on each job card. The apply button opens the original listing URL.

The ranking is India-first: India/INR listings rank above general remote roles,
then APAC/worldwide remote roles, then recent posts and listings that mention
quick screening, contract, client, or fast feedback language.

## Adding More Sources

Add more free sources in:

```text
lib/services/jobs_api_service.dart
```

Prefer:

- Official public APIs.
- RSS feeds.
- Partner feeds.

Avoid scraping sites unless the source explicitly allows it. Many job portals block scraping or disallow reuse in their terms.

Do not scrape Naukri, LinkedIn, Indeed, or similar closed platforms unless you
have a written API/partner agreement. Add them only through official APIs.

## Resume Tailoring

The no-cost app does not call an external AI provider.

Instead, `lib/services/ai_resume_service.dart` runs a local ATS-style optimizer that:

- Extracts keywords from the target job description.
- Scores keyword coverage and resume structure.
- Suggests missing keywords and measurable proof points.
- Generates a tailored resume section and cover letter draft.

This keeps the app free and avoids exposing AI API keys in client code.

## Optional Paid Upgrade

If you later want stronger AI output or backend job ingestion, use the existing `functions/` folder as a starting point. That upgrade should use:

- Firebase Cloud Functions or another backend.
- A backend-held AI API key.
- Firestore `jobs` collection.
- Scheduled ingestion.

That path can require billing, so it is intentionally not used in the current no-cost build.
