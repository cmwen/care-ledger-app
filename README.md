# Care Ledger App

Care Ledger is a Flutter app for tracking family care efforts (in both directions), reviewing suggested activities weekly, and settling agreed credits fairly.

## Product Focus

- Visual timeline of what care work was done and when
- Automatic activity suggestions to reduce manual logging
- Weekly review workflow (approve/edit/reject in batch)
- Shared credit ledger with confirmation workflow
- Local-first, serverless-friendly multi-user sync direction

## Current Status

Project discovery and product definition are in progress.
Core vision and planning docs are in `docs/`:

- `docs/VISION_CARE_LEDGER.md`
- `docs/REQUIREMENTS_CARE_LEDGER_MVP.md`
- `docs/USER_STORIES_CARE_LEDGER.md`
- `docs/ROADMAP_CARE_LEDGER.md`

## Tech Stack

- Flutter (Dart)
- Android target configured
- CI/CD via GitHub Actions (`.github/workflows/`)

## Run Locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d android
```

## Android App Identity

- Dart package: `care_ledger_app`
- Android applicationId/namespace: `com.cmwen.careledgerapp`
- Android app label: `Care Ledger`

## Next Step

Start implementation from the MVP requirements and user stories, beginning with:
1. Local data model for ledger, entries, reviews, settlements
2. Weekly review UI flow
3. Auto-capture suggestion pipeline (review-first)
4. Serverless sync prototype for two participants
