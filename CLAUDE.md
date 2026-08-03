# CLAUDE.md — ActivoTrade

Context for AI assistants and new contributors. Read fully before changing code.

## What this is

Flutter mobile client for ActivoTrade (wealth management), plus a mock backend
for local development.

```
activotrade_app-main/
├── app/          Flutter application (package: activotrade_app)
├── mock_api/     Hono + SQLite mock backend (port 3000)
├── docs/         STUDY_GUIDE.md/.pdf, PR_IMPLEMENTATION.md
└── .agents/      Official Flutter + Dart agent skills (instructions only)
```

## Commands

Run from `app/`:

| Task | Command |
|---|---|
| Install deps | `flutter pub get` |
| Regenerate localizations | `flutter gen-l10n` |
| Format | `dart format lib test` |
| Analyze | `flutter analyze` — must report **zero** issues |
| Test | `flutter test` — must be **green** |
| Auto-fix lints | `dart fix --apply` |
| Run | `flutter run` (emulator + mock API running) |
| Target another backend | `flutter run --dart-define-from-file=config/env_staging.json` |

Backend: `npm install && node server.js` in `mock_api/`.
Credentials: **demo / password123**. API docs: `http://localhost:3000/docs`.

**Definition of done for any change:** `flutter gen-l10n && dart format lib test
&& flutter analyze && flutter test` all clean, plus a manual pass on the
affected screen.

## Architecture

Follows [Flutter's official architecture guidance](https://docs.flutter.dev/app-architecture/recommendations):
a UI layer and a data layer, unidirectional data flow, immutable models,
constructor dependency injection.

```
UI layer
  Screen        assembly + navigation only
  Widgets       display state, capture input — no logic
       ↓ user intent            ↑ states
  Cubit         all business logic (the ViewModel role)
       ↓
Data layer
  ApiService    sole network gateway (Dio + AuthInterceptor)
  SecureStorageService / BiometricService   platform services
       ↓
  Backend
```

State management is **flutter_bloc (Cubit)** — Flutter's guidance treats the
choice of observable as preference; what matters is that logic lives outside
widgets. Do not introduce a second state-management library.

Deliberately **not** used, per the same guidance: a domain layer with use-case
classes ("in very large apps, use-cases are useful, but in most apps they add
unnecessary overhead"). Add one only when logic is duplicated across Cubits.

## Layout

```
app/
├── config/                       env_dev.json · env_staging.json · env_prod.json
└── lib/
    ├── core/
    │   ├── config/app_config.dart          baseUrl · environment · timeouts
    │   ├── constants/api_constant.dart     relative paths only
    │   ├── design_system/
    │   │   ├── theme.dart                  light/dark + semantic colour tokens
    │   │   └── widgets/app_snack_bar.dart  shared UI components
    │   ├── network/
    │   │   ├── api_service.dart
    │   │   └── auth_interceptor.dart       Bearer token on every request
    │   ├── security/biometric_service.dart local_auth wrapper
    │   └── storage/secure_storage_service.dart  Keychain / Keystore
    ├── features/
    │   ├── auth/       screen · cubit · state · models/ · widgets/
    │   └── dashboard/
    ├── l10n/           app_en.arb · app_es.arb (sources) + generated Dart
    └── main.dart
```

**`core/` vs `features/`:** would two features both use it? Yes → `core/`.
`core/` must never import from `features/`.

## Rules

1. Business logic lives in Cubits. Widgets display state and capture input.
2. Extract widgets into classes — never `_buildXxx()` helper methods.
3. Screens stay assembly-only (~50–150 lines).
4. Prefer `StatelessWidget`; use `StatefulWidget` only to own disposable
   resources, and always dispose them.
5. No hardcoded `Color(...)`, `Colors.x` or `TextStyle(...)` outside
   `theme.dart` — use `Theme.of(context)`.
6. No hardcoded user-visible strings — everything through `AppLocalizations`.
7. `Semantics` goes *inside* each interactive widget, so no call site can omit it.
8. Constructor injection with production defaults:
   `ClassName({Dep? dep}) : _dep = dep ?? Dep();`
9. Only `ApiService` touches the network. Only `SecureStorageService` touches
   secure storage. Only `BiometricService` touches `local_auth`.
10. Trailing commas everywhere; `dart format` clean.
11. `debugPrint` only inside `if (kDebugMode)`. Never `print`.
12. Comments explain **why**, never what. Max ~2 lines. Use `///` for public APIs.

## Conventions worth knowing

- **Errors:** a Cubit has no `BuildContext`, so it cannot localize. It emits
  `AuthFailure(AuthFailureReason.x)`; the screen maps the reason to a localized
  string in an exhaustive `switch`. Adding a reason therefore requires the enum,
  both `.arb` files, and that switch — the compiler enforces the third.
- **Snackbars:** `AppSnackBar.warning/.error`. Connectivity problems are
  warnings (the user can retry); account problems are errors.
- **Semantic colours:** Material 3 has an error role but no warning role, so
  `AppSemanticColors` (a `ThemeExtension`) defines a warning container/on-container
  token pair. Never hardcode amber.
- **Localization:** edit `.arb` files only, then `flutter gen-l10n`. Never
  hand-edit `app_localizations*.dart`. English is the template; both files must
  hold identical keys.
- **Models:** immutable, `Equatable`, with a defensive static `fromJson` that
  returns `null` on malformed input rather than throwing. Network responses are
  untrusted input — narrow them with pattern matching before use.
- **Biometrics:** `local_auth` proves the device owner is present; it does not
  authenticate against the backend. Biometric login therefore *unlocks a session
  a password login created earlier* and can never be the first login.
- **Emulator networking:** `10.0.2.2:3000` is the host's localhost. Cleartext
  HTTP is enabled only in `android/app/src/debug/AndroidManifest.xml`; release
  builds are HTTPS-only.
- **Login payload:** keys are lowercase `username` / `password` (case-sensitive;
  a mismatch returns HTTP 400, not 401).
- **Android:** `MainActivity` extends `FlutterFragmentActivity` and the launch
  themes are `Theme.AppCompat.*` — both required by `local_auth`. minSdk 24.

## Testing

`flutter_test` + [`bloc_test`](https://pub.dev/packages/bloc_test) +
[`mocktail`](https://pub.dev/packages/mocktail). **No code generation** — do not
introduce `mockito` or `build_runner`; `mocktail` needs neither.

Test each layer separately and prefer fakes over real dependencies. Cubit tests
assert the exact state sequence; widget tests assert what the user sees.

```
test/
├── core/network/auth_interceptor_test.dart
├── core/security/biometric_service_test.dart
├── features/auth/auth_cubit_test.dart
├── features/auth/models/user_test.dart
├── features/auth/widgets/login_form_test.dart
└── widget_test.dart
```

Widget tests must `await tester.pumpAndSettle()` after `pumpWidget` — the
localization delegates resolve asynchronously and the first frame renders before
they are ready.

## Backend endpoints

| Method | Path | Notes |
|---|---|---|
| POST | `/api/auth/login` | `{username, password}` → `{success, token, user}`; 401 on bad credentials |
| GET | `/api/user/balance` | Bearer required |
| POST | `/api/user/register-token` | FCM registration |
| POST | `/api/notify/send` | Push trigger |

Token format is an opaque string, not a real JWT — never parse it client-side.

## Current state

Implemented: password login, secure token storage, Bearer interceptor,
biometric unlock with explicit opt-in, EN/ES localization, Material 3 light/dark
theming, accessibility labels, unit + widget tests.

Not built: session management and token refresh, auto-login, dashboard data,
push notifications, declarative routing, release signing and minification.

## Roadmap

Build in this order — each step unblocks the next.

1. **Session layer.** A long-lived `SessionCubit` above `MaterialApp`, plus an
   `onError` handler in `AuthInterceptor` (401 → clear storage, force logout).
   Everything below depends on it; building the dashboard first means building
   it twice.
2. **Declarative routing** with [`go_router`](https://pub.dev/packages/go_router)
   (officially recommended), with session-driven redirects replacing
   `Navigator.pushReplacement`.
3. **Data layer.** Introduce repositories between Cubits and services once a
   second data source or caching appears — Flutter's guidance recommends
   abstract repository classes so environments can swap implementations. Today
   they would be pass-through classes, so they are deliberately deferred.
4. **Dashboard** with real data via `ApiService.balance()`.
5. **Push notifications** (`firebase_core` + `firebase_messaging`).

## Before proposing changes

- Prefer no change: if existing code is production quality, say so.
- Only add a package with a stated engineering reason.
- Do not restructure the architecture without a measurable benefit.
- Validate against `flutter analyze` and `flutter test` before claiming success.
