# Contributing to Crucue

Thank you for your interest in contributing to Crucue.

This document covers the conventions, workflow, and standards expected for contributions to this repository.

---

## Development setup

See [`docs/setup_local_development.md`](docs/setup_local_development.md) for the full local development guide.

**Quick start:**
```bash
flutter pub get
cd functions && npm install
flutter run
```

---

## Code conventions

### Dart / Flutter

- **State management**: Riverpod throughout. No `setState` on `StatelessWidget` hybrids. No `BLoC` or `GetX`.
- **Architecture**: Features live in `lib/features/{feature}/`. Shared services in `lib/core/services/`. Models in `lib/shared/models/`.
- **AI calls**: All AI inference routes through the `AiEngine` interface. Never call Cloud Functions directly from UI code — use `CloudFunctionsService` or the registered `aiEngineProvider`.
- **Firestore**: All reads and writes go through `FirestoreService`. Never call `FirebaseFirestore.instance` directly from views or feature screens.
- **Colors**: Use `CrucueTokens` or `Theme.of(context).colorScheme.*` / `Theme.of(context).hintColor`. Never hardcode `Color(0xff...)` in widget files.
- **Navigation**: Use `navigateTo(Widget)` from `helper_methods.dart`. GoRouter is defined in `app/router.dart` but is not yet the active navigation system.
- **Analyze before committing**: `flutter analyze` must pass with 0 errors.

### Branding

- **In-app wordmarks**: `assets/Logos/crucue_logo_orange.png` (light backgrounds) and `crucue_logo_white.png` (dark backgrounds). Use [`CrucueBrandLogo`](lib/core/branding/crucue_brand_logo.dart) so aspect ratio stays correct (`BoxFit.contain`).
- **Launcher / store icons**: Source tree in [`app-launcher/`](app-launcher/) — sync into `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/AppIcon.appiconset/` when icons change (see [`docs/setup_local_development.md`](docs/setup_local_development.md)).

### TypeScript (Cloud Functions)

- All new AI callables must check `request.auth` and return structured errors on auth failure.
- Use `process.env.GEMMA4_API_KEY` — never hardcode API keys.
- Run `cd functions && npm run build` before deploying.

---

## Branching

- `main` — stable, deployable
- `feat/your-feature` — feature branches
- `fix/your-fix` — bug fix branches

---

## Pull requests

1. Keep PRs focused. One feature or fix per PR.
2. Write a clear description of what changed and why.
3. `flutter analyze` must pass.
4. Include any doc updates if architecture or APIs changed.
5. PRs that remove the Gemma 4 backend dependency or add client-side AI API keys will not be merged.

---

## Security

If you discover a security vulnerability, please follow the process in [`SECURITY.md`](SECURITY.md). Do not open a public issue.

---

## Questions

Open an issue with the `question` label or contact the team at `support@crucue.app`.
