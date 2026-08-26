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
  <Feature>Service   the feature's only network entry point; owns its paths
       ↓             and turns DioException into the feature's own exception
  ApiService          transport only: base URL, timeouts, AuthInterceptor
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
    ├── core/                     shared by two or more features, nothing else
    │   ├── auth/                 AppAuthCubit · User · TokenRefresher
    │   ├── config/app_config.dart          baseUrl · environment · timeouts
    │   ├── constants/api_constant.dart     every path, grouped by feature
    │   ├── design_system/
    │   │   ├── theme.dart                  light/dark + semantic colour tokens
    │   │   └── widgets/app_snack_bar.dart  shared UI components
    │   ├── di/service_locator.dart         every registration, one file
    │   ├── network/
    │   │   ├── api_service.dart            transport only — no endpoint paths
    │   │   └── auth_interceptor.dart       Bearer token on every request
    │   └── storage/secure_storage_service.dart  Keychain / Keystore
    ├── features/
    │   └── <feature>/
    │       ├── <feature>_cubit.dart    business logic, no transport types
    │       ├── <feature>_state.dart    states; re-exports the failure reason
    │       ├── domain/                 failure reason enum + typed exception
    │       ├── data/
    │       │   ├── models/             request/response DTOs
    │       │   └── services/           only network entry point; owns paths
    │       ├── widgets/
    │       └── <feature>_screen.dart   assembly only
    ├── l10n/           app_en.arb · app_es.arb (sources) + generated Dart
    └── main.dart
```

**`core/` vs `features/`:** would two features both use it? Yes → `core/`.
`core/` must never import from `features/`.

**Why `ApiConstants` stays in `core/`.** The senior's objection was that
`ApiService` exposed `login()`, `balance()` and `registerDevice()` — core held
*behaviour* for every feature, so core changed whenever a feature did. That is
gone: `ApiService` is transport only. What remains in core is a table of path
strings that nothing in `core/` imports. Keeping every endpoint visible in one
file is worth more day to day than the last inch of separation, and the cost
is bounded — a new endpoint adds one line here and one call in that feature's
service, and nowhere else. Raise it if the senior disagrees; do not quietly
scatter the paths again.

**Where a type belongs inside a feature.** `data/services/` is the only place
that may name a transport type; `domain/` holds the vocabulary both sides
share; the Cubit sits above both and knows neither Dio nor JSON. The tell that
a boundary has leaked is an import: `package:dio` or `dart:convert` in a Cubit
means work is happening one layer too high.

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
9. Only `ApiService` touches the network, and only a feature's own
   `data/services/` class calls it — no Cubit holds an `ApiService`. Paths come
   from `ApiConstants`, and a feature's service is the only thing allowed to
   read the constants belonging to that feature. Only `SecureStorageService`
   touches secure storage; only `BiometricService` touches `local_auth`.
   Transport types stop at `data/services/`: a service catches `DioException`
   and rethrows the feature's own exception (`AuthException`,
   `NotificationException`), and the Cubit switches on `.reason`. Likewise
   `SecureStorageService` takes and returns a `User`, so the
   `jsonEncode`/`jsonDecode` pair lives there and not in a Cubit.
10. Trailing commas everywhere; `dart format` clean.
11. `debugPrint` only inside `if (kDebugMode)`. Never `print`.
12. Comments explain **why**, never what. Max ~2 lines. Use `///` for public APIs.
13. A feature never reaches into another feature. If signing in has to trigger
    something in notifications, the *listener* lives in notifications and
    watches `AppAuthCubit` — auth must not know notifications exists.
14. No dead registrations. If a Cubit is in `service_locator` it must be used by
    a screen. Ship it wired or do not ship it.
15. No new package, CI workflow, or analyzer rule without asking first. These
    bind the whole team, not just the author.

### How these get checked

`flutter analyze` catches none of 2, 3, 12, 13 or 14. Before opening a PR:

```bash
grep -rn "Widget _build" lib/                      # rule 2  → expect nothing
wc -l lib/features/*/[a-z]*screen.dart             # rule 3  → each under ~150
grep -rn "Color(0x\|Colors\.\|TextStyle(" lib/ \
  | grep -v design_system/theme.dart               # rule 5  → expect nothing
grep -rn "Text('" lib/ --include=*.dart | grep -v l10n   # rule 6  → expect nothing
grep -rn "debugPrint" lib/ -B2 | grep -c kDebugMode      # rule 11 → matches count
grep -rln "package:dio\|dart:convert" lib/features/*/*cubit.dart  # rule 9 → nothing
```

For rule 13, a Cubit constructor taking another Cubit from a different feature
is the smell. For rule 14, cross-check `service_locator.dart` registrations
against actual `getIt<...>()` call sites.

### Standing review findings

Raised by the senior and not yet resolved. Do not re-litigate them in code —
they need a decision first:

- **Repositories and use-cases.** The senior's architecture review asks for
  them; the *Architecture* section above deliberately defers them, citing
  Flutter's own guidance. **These two documents currently contradict each
  other.** Whoever resolves it should update this file in the same change.
- **`freezed` / required dependencies.** Also from that review, also in
  tension — with the no-code-generation rule under *Testing*, and with rule 8.

## Where the rest of the history lives

This file is loaded into every session, so it stays short. The detail sits in
`docs/` and should be read when the work touches it:

| File | What it holds |
|---|---|
| `docs/SENIOR_REVIEW_SOURCE.md` | the senior's 40 PR comments + architecture verdict, verbatim, with a status column |
| `docs/reference/06_ENGINEERING_STANDARDS.md` | §1–10 plus the mistakes log M1–M7 |
| `docs/BACKEND_ASKS_FRIDAY.md` | open requests for the backend team |
| `docs/DOCS.html` | the docs SPA — Learn, Reference and Source tracks |
| `docs/STUDY_GUIDE.md` / `.pdf` | 28-chapter walkthrough of the whole app |

Do not paraphrase `SENIOR_REVIEW_SOURCE.md` — it is a record of what was said,
not a working document. Edit the status column only.

## Things that have bitten us

Each of these cost real time. Read before touching the same area.

- **Two machines, one repo.** Work happens on a second laptop as well as this
  checkout, and the two drift. Before diagnosing anything, confirm which copy
  the symptom is on. A `getUser()` that called `jsonEncode` instead of
  `jsonDecode` survived on one machine only, and read back as "no saved
  session" — every token was present, the user object alone failed to parse.
- **`FirebaseMessaging.deleteToken()` on logout.** Tried once to stop a signed
  out device receiving push. Every call minted a fresh token while the old row
  survived in `user_tokens`, so one push arrived three times and eleven dead
  rows accumulated for one account. Fully reverted. The real fix is a backend
  `DELETE /api/user/register-device`, which does not exist yet.
- **The mock's `platform` enum.** `mock_api/routes/user.js` must list `web`
  alongside `android` and `ios`, or web device registration returns 400. This
  was patched locally once and nearly went uncommitted — a fresh clone would
  have failed web push with no obvious cause. Same class of problem as the
  missing `cors()` call, which cost an afternoon.
- **Changing code to make a test pass.** A test expected `AuthLoading` from
  `setupBiometricsPostLogin`; emitting it made the test green and put the login
  form on screen behind the OS fingerprint sheet. Ask which of the two is wrong
  before editing either. This is entry M2 in the standards doc.
- **Mock Mode is easy to miss.** `mock_api/services/firebase.js` returns
  `realFcm: false` when `firebase-service-account.json` is absent, and push
  "works" in a way that does not match production. Check which mode you are in
  before concluding anything from a push test.

## Conventions worth knowing

- **Errors:** a Cubit has no `BuildContext`, so it cannot localize. It emits
  `AuthFailure(AuthFailureReason.x)`; the screen maps the reason to a localized
  string in an exhaustive `switch`. Adding a reason therefore requires the enum,
  both `.arb` files, and that switch — the compiler enforces the third.
- **Snackbars:** `AppSnackBar.success/.warning/.error`, or `.show(context,
  message, severity)` when the severity was computed elsewhere. Connectivity
  problems are warnings (the user can retry); account problems are errors.
  Presenters map a failure reason to a severity and pass it to `.show`, so
  adding a severity never breaks them.
- **Semantic colours:** Material 3 has an error role but no warning or success
  role, so `AppSemanticColors` (a `ThemeExtension`) defines warning and success
  container/on-container pairs plus `positive` for gains. Never hardcode amber
  or green.
- **Cubit lifetimes:** feature cubits are `registerFactory` — one per screen or
  dialog. `NotificationCubit` is the exception: it owns the FCM token-rotation
  subscription, which must outlive the dialog, so it is a `registerLazySingleton`
  and the dialog provides it with `BlocProvider.value` (not `create`, which
  would close it on pop).
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
| POST | `/api/auth/login` | `{username, password}` → `{success, accessToken, refreshToken, user}`; 401 on bad credentials |
| POST | `/api/auth/refresh` | `{refreshToken}` → a **new pair**; carries no `user` field |
| GET | `/api/user/balance` | Bearer required |
| POST | `/api/user/register-device` | `{fcmToken, deviceId, platform, deviceName}`. Replaced `/api/user/register-token`, which now 404s |
| POST | `/api/notify/send` | `{username, title, body}` — push trigger |

Tokens are HMAC-SHA256 JWTs: access lives 1 hour, refresh 30 days, and **both
rotate on every refresh** — persisting only the new access token breaks the
next refresh. Treat them as opaque anyway: never parse one client-side.

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
4. **Dashboard** with real data — `DashboardService.balance()` is wired; what
   remains is replacing `_PlaceholderSummaryCard` and adding an error state
   the user can act on.
5. **Push notifications** (`firebase_core` + `firebase_messaging`).

## Before proposing changes

- Prefer no change: if existing code is production quality, say so.
- Only add a package with a stated engineering reason.
- Do not restructure the architecture without a measurable benefit.
- Validate against `flutter analyze` and `flutter test` before claiming success.
