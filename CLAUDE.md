# CLAUDE.md — ActivoTrade

Context for AI assistants working in this repo. Read fully before proposing changes.

## What this is

Flutter mobile app for ActivoTrade (wealth management) plus a mock backend for
local development. Login flow is complete and reviewed; the rest is roadmap.

```
activotrade_app-main/
├── app/        Flutter application (package: activotrade_app)
├── mock_api/   Hono + SQLite mock backend (port 3000)
└── docs/       STUDY_GUIDE.md / .pdf — beginner walkthrough of the codebase
```

## Commands

Run from `app/`:

| Task | Command |
|---|---|
| Install deps | `flutter pub get` |
| Regenerate localizations | `flutter gen-l10n` |
| Static analysis | `flutter analyze` (must be zero issues) |
| Tests | `flutter test` (11 tests, must be green) |
| Run | `flutter run` (Android emulator; mock API must be running) |
| Point at another backend | `flutter run --dart-define=BASE_URL=https://...` |

Mock backend, from `mock_api/`: `npm install` then `node server.js`.
Test credentials: **demo / password123**.

## Architecture (do not redesign)

```
Screen (assembly only)
  └─ Widgets (UI + input capture only)
       └─ Cubit (all business logic, emits states)
            └─ ApiService (only class that talks to the network)
                 └─ Dio + AuthInterceptor → mock backend
Token → SecureStorageService (Keychain / Keystore)
```

State management is **flutter_bloc (Cubit)**. Do not introduce Provider,
Riverpod, GetX, Repository pattern, UseCases, or Clean Architecture layers —
these were explicitly rejected as unnecessary for this project's size.

## Mandatory coding rules (company standard)

1. Screens 50–100 lines (max 150–200); screens only assemble widgets.
2. **No `_buildXxx()` helper methods** — extract a real `StatelessWidget` into
   `widgets/` instead.
3. Business logic never in widgets. UI never calls Dio or storage directly.
4. **No hardcoded `Color(...)`, `Colors.x`, or `TextStyle(...)`** — use
   `Theme.of(context)` / `ActivoTradeTheme` / `AppSemanticColors`.
5. **No hardcoded user-visible strings** — everything through `AppLocalizations`.
6. Prefer `StatelessWidget`; `StatefulWidget` only to own disposable resources.
7. Trailing commas everywhere; `dart format` compatible.
8. Dependencies are constructor-injected: `ClassName({Dep? dep}) : _dep = dep ?? Dep();`
9. `Semantics` goes *inside* each interactive widget, never at the call site.
10. Feature-first: never mix files between features.

## Layout

```
app/lib/
├── core/
│   ├── constants/api_constant.dart      baseUrl (--dart-define), paths, timeouts
│   ├── design_system/theme.dart         ActivoTradeTheme + AppSemanticColors ext
│   ├── network/api_service.dart         login(), balance()
│   ├── network/auth_interceptor.dart    attaches Bearer token per request
│   └── storage/secure_storage_service.dart   save/get/deleteToken
├── features/
│   ├── auth/  auth_screen · auth_cubit · auth_state · widgets/
│   └── dashboard/dashboard_screen.dart  (placeholder)
├── l10n/  app_en.arb · app_es.arb (SOURCES) + generated app_localizations*.dart
└── main.dart
app/test/  features/auth/auth_cubit_test.dart · core/network/auth_interceptor_test.dart · widget_test.dart
```

## Conventions worth knowing

- **Errors:** the cubit has no `BuildContext`, so it cannot localize. It emits
  `AuthFailure(AuthFailureReason.x)`; `auth_screen.dart` maps the reason to a
  localized string in an exhaustive `switch`. Adding a reason therefore requires
  edits in three places: enum, both `.arb` files, and that switch (the compiler
  enforces the third).
- **Snackbar severity:** network / serverUnavailable → warning colors
  (`AppSemanticColors`, a ThemeExtension because M3 has no warning role);
  credentials / tooManyAttempts / generic → `colorScheme.errorContainer`.
- **Localization:** edit `.arb` files only, then `flutter gen-l10n`. Never
  hand-edit `app_localizations*.dart` (generated, but committed intentionally).
- **Emulator networking:** `10.0.2.2:3000` is the host's localhost. Cleartext
  HTTP is enabled **only** in `android/app/src/debug/AndroidManifest.xml`.
- **Logging:** `debugPrint` must stay wrapped in `if (kDebugMode)`.
- **Payload contract:** login body keys are lowercase `username` / `password`
  (case-sensitive; a mismatch returns HTTP 400, not 401).
- **Testing:** `bloc_test` + `mocktail` only. No codegen, no other mock libs.

## Backend endpoints (mock_api)

| Method | Path | Notes |
|---|---|---|
| POST | `/api/auth/login` | `{username, password}` → `{success, token, user}`; 401 on bad creds |
| GET | `/api/user/balance` | Bearer required |
| POST | `/api/user/register-token` | FCM token registration |
| POST | `/api/notify/send` | Push trigger |

OpenAPI docs at `http://localhost:3000/docs`. Token format:
`activotrade_mock_jwt_token_for_<userId>` (opaque string, not a real JWT).

## Current state

Done: login flow end-to-end, secure token storage, Bearer interceptor,
EN/ES localization, M3 theming with light/dark, accessibility, 11 tests,
re-entry guard against double submits.

Not built yet: session management, refresh token, auto-login, biometrics
(`local_auth`), real dashboard data, push notifications, `go_router`.

## Roadmap (build in this order)

1. **Session layer** — long-lived `SessionCubit` above `MaterialApp`, plus
   `onError` in `AuthInterceptor` (401 → force logout). Everything below
   depends on this; building the dashboard first means building it twice.
2. **go_router** with session-driven redirects (replaces `pushReplacement`).
3. **Dashboard** with real data via `ApiService.balance()`.
4. **Biometrics** — `local_auth`; requires `MainActivity` to extend
   `FlutterFragmentActivity` on Android. Enable the existing
   `BiometricsButton` only when hardware supports it AND a token is stored.
5. Push notifications (`firebase_core` + `firebase_messaging`).

## Before proposing changes

- Verify against `flutter analyze` and `flutter test` — both must stay clean.
- Prefer no change: if existing code is production quality, say so.
- Explain WHY in comments (max 2 lines); never narrate WHAT the code does.
- Don't add packages without a strong, stated engineering reason.
