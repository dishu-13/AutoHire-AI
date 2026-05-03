# No-Cost Live Architecture

## Goal

Run the app live on the Firebase Spark/free tier with no paid backend.

The app uses:

- Firebase Authentication for Email/Password login.
- Cloud Firestore for user profile, saved jobs, tracker data, and resume history.
- Direct public job APIs from the Flutter app for live jobs.
- Local resume tailoring logic inside the app for ATS keywords, suggestions, and PDF export.

No Cloud Functions, Secret Manager, paid AI API key, or Blaze upgrade is required for this version.

## System Flow

```text
Remotive API / Arbeitnow API
        |
Flutter app HTTP client
        |
Jobs tab
```

```text
Flutter Resume screen
        |
Local ATS keyword matcher
        |
Firestore user resume history
```

```text
Firebase Auth
        |
users/{uid}
        |
savedJobs / applications / resumeResults
```

## Frontend

- Login, create account, and password reset.
- Jobs page fetches live roles from Remotive and Arbeitnow.
- Resume page uploads/pastes `.txt`, generates local ATS suggestions, exports PDF.
- Tracker page stores applications under the signed-in user.
- Dashboard reads saved jobs and application stats.
- Settings stores name, email, preferences, dark mode, and notification toggles.

## Firestore

Free-mode collections:

```text
users/{uid}
users/{uid}/savedJobs/{jobId}
users/{uid}/applications/{applicationId}
users/{uid}/resumeResults/{resultId}
```

Rules:

- A signed-in user can read/write only their own `users/{uid}` document.
- A signed-in user can read/write only their own nested saved jobs, applications, and resume results.
- Public job data is not stored in Firestore in free mode.

## Optional Future Upgrade

The `functions/` folder is left as a future paid upgrade path. Use it later only if you want:

- Scheduled backend job ingestion.
- Firestore `jobs` collection for centralized realtime jobs.
- A secure OpenAI-compatible resume proxy.
- Server-side scraping or crawling where legally allowed.

Those features usually require Firebase Blaze billing. They are not part of the current no-cost app.
