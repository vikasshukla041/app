# ActivoTrade — Flutter app

Wealth-management mobile client. This package contains the Flutter
application; the companion mock backend lives in [`../mock_api`](../mock_api).

## Quick start

```bash
# 1. Backend (separate terminal, from ../mock_api)
npm install && node server.js          # http://localhost:3000

# 2. App (from this directory)
flutter pub get
flutter gen-l10n
flutter run                            # Android emulator or iOS simulator
```

Test credentials: **demo / password123**

The Android emulator reaches the host machine at `10.0.2.2`, so the default
base URL is `http://10.0.2.2:3000`. Point the app at any other backend
without touching code:

```bash
flutter run --dart-define=BASE_URL=https://staging.activotrade.example
```

## Checks

```bash
dart format lib test
flutter analyze          # must report zero issues
flutter test             # must be green
```

CI runs all three on every push and pull request
(see [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml)).

## Architecture

```
Screen (assembly only)
  └─ Widgets (UI + input capture)
       └─ Cubit (business logic, emits states)
            └─ ApiService (sole network gateway)
                 └─ Dio + AuthInterceptor → backend
Token → SecureStorageService (Keychain / Keystore)
```

State management is **flutter_bloc (Cubit)** — the ViewModel role in
Flutter's [recommended architecture](https://docs.flutter.dev/app-architecture).
Code is organized **feature-first**: everything a feature owns lives in
`lib/features/<feature>/`, with cross-feature infrastructure in `lib/core/`.

```
lib/
├── core/          constants · design_system · network · storage
├── features/      auth (screen · cubit · state · models · widgets) · dashboard
├── l10n/          app_en.arb · app_es.arb  (sources) + generated Dart
└── main.dart
```

### Conventions

- Business logic lives in Cubits; widgets only display state and capture input.
- Navigation and snackbars happen in a `BlocListener`/`BlocConsumer`, never in a builder.
- The Cubit has no `BuildContext`, so it emits an `AuthFailureReason`; the screen
  turns that into a localized message. Adding a reason requires updating the enum,
  both `.arb` files and the screen's exhaustive `switch` (the compiler enforces it).
- No hardcoded colours, text styles or user-visible strings — use `Theme.of(context)`
  and `AppLocalizations`.
- Dependencies are constructor-injected: `ClassName({Dep? dep}) : _dep = dep ?? Dep();`
- Edit `.arb` files only, then run `flutter gen-l10n`; never hand-edit the generated
  `app_localizations*.dart`.

## Testing

`flutter_test` · [`bloc_test`](https://pub.dev/packages/bloc_test) ·
[`mocktail`](https://pub.dev/packages/mocktail) — no code generation.

| Suite | Covers |
|---|---|
| `test/features/auth/auth_cubit_test.dart` | login contract: success, malformed payloads, re-entry guard, 401/429/5xx, unexpected errors |
| `test/features/auth/models/user_test.dart` | defensive `User.fromJson` parsing |
| `test/features/auth/widgets/login_form_test.dart` | reactive UI: loading disables inputs, trimming, disabled biometrics |
| `test/core/network/auth_interceptor_test.dart` | Bearer header attached only when a token exists |
| `test/widget_test.dart` | app boots to the login screen |

## Status

Implemented: login flow, secure token storage, Bearer interceptor, EN/ES
localization, Material 3 light/dark theming, accessibility labels.

Not yet built: session management and token refresh, auto-login, biometrics
(`local_auth`), real dashboard data, push notifications, `go_router`.
