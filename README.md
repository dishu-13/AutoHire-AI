# AutoHire AI

Flutter Android app for job discovery, AI resume tailoring, and application tracking.

## What is included

- Jobs: live India-friendly and remote job APIs, search suggestions, filters, job detail view, save jobs, apply links, tracker entry.
- Resume AI: paste or upload `.txt`, local ATS tailoring, suggestions, PDF export.
- Dashboard: saved/applied jobs, status tracking, success-rate analytics, timeline.
- Profile: name/email, resume editor, dark mode, logout.
- Architecture: `provider` with `AppState` as the central reactive store.

## Setup

Read the guides in `docs/`:

- `docs/api_integration_guide.md`
- `docs/firebase_setup.md`
- `docs/production_architecture.md`
- `docs/run_and_build_guide.md`

The current app is structured for the no-cost Firebase Spark path: Auth, Firestore user data, live public job APIs, and local resume tailoring. Cloud Functions are optional future upgrade code, not required to run this version.
