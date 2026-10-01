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
    │   │   ├── tokens/                     colour, type, spacing, radius, sizing
    │   │   ├── responsive/                 breakpoints, window class, two-column reflow
    │   │   ├── theme.dart                  turns tokens into light/dark themes
    │   │   └── widgets/                    badge · status dot · section header · snackbar
    │   ├── navigation/                     AppFrame · AppSection · bottom tabs · side menu · profile menu
    │   ├── di/service_locator.dart         every registration, one file
    │   ├── routing/                        GoRouter · routes · deep links
    │   ├── network/
    │   │   ├── api_service.dart            transport only — no endpoint paths
    │   │   └── auth_interceptor.dart       Bearer token on every request
    │   └── storage/secure_storage_service.dart  Keychain / Keystore
    ├── features/            auth · dashboard · holdings · orders · education · tax · settings · notifications · alerts · splash
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
`core/` must never import from `features/` — with exactly two exceptions, both
composition roots whose entire job is to name every feature once:
`di/service_locator.dart` and `routing/app_router.dart`. A router has to know
the screens it routes to. Nothing else in `core/` may import a feature.

**Why `ApiConstants` stays in `core/`.** The senior's objection was that
`ApiService` exposed `login()`, `balance()` and `registerDevice()` — core held
*behaviour* for every feature, so core changed whenever a feature did. That is
gone: `ApiService` is transport only. What remains in core is a table of path
strings that nothing in `core/` imports. Keeping every endpoint visible in one
file is worth more day to day than the last inch of separation, and the cost
is bounded — a new endpoint adds one line here and one call in that feature's
service, and nowhere else. Raise it if the senior disagrees; do not quietly
scatter the paths again.

**Routing and deep links.** `core/routing/` owns every path; screens never
navigate themselves. A push payload is `{'route': ..., 'id': ...}`, and
`DeepLinkParser` turns it into a location:

- `AppRoutes.deepLinkable` — routes a payload may name. Anything else is
  dropped, so a notification can never open a pre-auth screen.
- `AppRoutes.idInPath` — routes declared `<path>/:id`. Their id becomes a path
  segment and is validated first, because a segment is pasted into the URL.
  Everything else takes its id as `?id=`, which `Uri` escapes for free.

Adding a `:id` route means adding it to **both** sets. Miss `idInPath` and the
router silently fails to match — the tap opens nothing, with no error.

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
   `design_system/` — use `Theme.of(context)`. Colours live only in
   `tokens/app_colors.dart` and text styles only in `tokens/app_typography.dart`;
   `theme.dart` is the one file that reads them.
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
12. Comments explain **why**, never what. **One line. Two only if one truly
    cannot hold it.** This project is being learned from by students in grades
    7–10 alongside being built, so write for that reader: plain, simple
    English, short words, short sentences, no jargon, nothing that reads like
    a generated summary. Use `///` for public APIs. If a comment needs a
    paragraph, the explanation belongs in `docs/`, not in the code.
    **Naming (variables, functions, classes) should be natural and specific —
    the way a person describes what something does — not generic placeholders
    like `data1`, `temp`, or `handleThing`.** Avoid Flutter/CS jargon a
    grades-7–10 reader would not know — `Rail`, `Shell`, `WindowClass` — in
    favour of everyday words: `SideMenu`, `AppFrame`, `ScreenSize`. **A file's
    name is its class's name in `snake_case`, always** — `AppFrame` lives in
    `app_frame.dart`, never `nav_shell.dart`. Renaming a class means renaming
    its file (and its test file) in the same change; a class and its file
    disagreeing is always a bug, not a style choice.
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
  | grep -v design_system/                         # rule 5  → expect nothing
grep -rn "Text('" lib/ --include=*.dart | grep -v l10n   # rule 6  → expect nothing
grep -rn "debugPrint" lib/ -B2 | grep -c kDebugMode      # rule 11 → matches count
grep -rln "package:dio\|dart:convert" lib/features/*/*cubit.dart  # rule 9 → nothing
awk '/^[ \t]*\/\/\//{n=0; next} /^[ \t]*\/\//{n++; if(n>1) print FILENAME": "FNR; next} {n=0}' \
  $(find lib test -name '*.dart' ! -name 'app_localizations*.dart' \
    ! -name 'firebase_options.dart')               # rule 12 → 103 today
```

That last one prints every `//` comment that runs past one line. It skips `///`
doc comments, which the rule allows, and the two generated files, which are
never hand-edited — without those two exclusions it printed several hundred
false hits and was useless in practice. It stands at **103 today**, all in
`auth/`, `notifications/` and `routing/`; `core/design_system/`,
`core/navigation/` and `features/dashboard/` are clean. Run it before every
commit and make sure your own files add nothing to that number.

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

## The docs, and the rules that keep them honest

This file is loaded into every session, so it stays short. Everything else sits
in `docs/`.

**Only two things are ever the truth: the code, and this file.** Every other
document describes them, and a description goes stale. This file is the one
that must never be wrong, because it is trusted before the code is read.

### What exists, and who reads it

| File | Reader | Rule |
|---|---|---|
| `CLAUDE.md` | every AI session, every new contributor | must be true; update it in the same change |
| `docs/STUDY_GUIDE.md` | learners, start to finish | teaches **why**. Plain words — the readers are beginners |
| `docs/STUDY_GUIDE.pdf` | the same learners, offline | generated by `docs/build-pdf.sh` |
| `docs/INTERACTIVE_GUIDE.html` | someone with the code already open | code and explanation side by side, with line numbers. 15 tabs; tab 15 is the app frame |
| `docs/PATHSHALA.html` | grades 7–10 students, in Hinglish | 16 lessons, each with an animated scene, line-by-line code, a file/function table and a quiz. Hand-written; quotes code with line numbers as of 2026-09-25, so recheck a lesson when a file it quotes changes |
| `docs/DOCS.html` | anyone searching across everything | generated by `docs/build-docs.py` |
| `docs/SENIOR_REVIEW_SOURCE.md` | nobody routinely — it is a record | **never paraphrase.** Edit the status column only |
| `docs/reference/01`–`05`, `07`–`08` | someone looking up one class or method | per-file API reference |
| `docs/BACKEND_ASKS_FRIDAY.md` | the Friday meeting | delete after the meeting |

### Four rules

**1. One *fact*, one home. Formats may repeat.**
The responsive layer is explained in both the study guide and the interactive
guide, on purpose — two readers, two ways of reading. That is fine. What is not
fine is a *number or decision* living in two places, because one will change and
the other will not. When a fact changes, say out loud which documents hold it.

**2. Generated files are regenerated, never hand-edited — but not on every change.**
`STUDY_GUIDE.pdf` and `DOCS.html` are built from `STUDY_GUIDE.md`,
`docs/reference/` and `docs/source/`.

**Neither is in git, and nor is anything else under `docs/`.** `.gitignore` has
carried a bare `docs` line since the first commit, so a clone gets no
documentation at all and the only copy of any document is on the machine that
wrote it. That is why code once travelled between laptops as root-level
markdown. Whether to track `docs/` is a team decision; until it is made, treat
every document here as local to this checkout.

Rebuilding after every edit is waste. Rebuild on a trigger instead:

| Rebuild | Do not rebuild |
|---|---|
| Before anyone reads it — a session with the students, sending it to the senior or the CTO | a typo or a reworded sentence |
| A chapter or tab was added, or a whole feature changed | one line moved |
| A **fact** changed — a number, a file path, a decision | formatting |

```bash
cd docs && ./build-pdf.sh      # needs pandoc + xelatex; Git Bash or WSL on Windows
cd docs && python3 build-docs.py
```

**The condition that makes this safe: the build must stamp itself.** Neither
script does yet — checked, October 2026. Without a stamp, "rebuild when it
matters" quietly becomes "never rebuild", and a reader cannot tell a current
document from one that predates three features. That is how `STUDY_GUIDE.pdf`
fell two generations behind with nobody noticing.

So each build should print, on its first page or header:

> *Built from STUDY_GUIDE.md on 2026-10-14 · covers Chapters 1–29*

`build-pdf.sh` already pipes the markdown through Python before pandoc, so the
line can be injected there. `build-docs.py` needs the same in its header. Until
that exists, **rebuild on every content change**, because a silent stale doc is
worse than a wasted build.

The interactive guide is different: it is written by hand, not generated, so it
is current the moment it is saved. It needs no rebuild — only the discipline of
rule 1 when a fact it holds changes elsewhere.

**3. A document with no reader is deleted, not archived.**
An archive is a place where wrong things stay alive. If nobody reads it, remove
it.

**4. Before removing or merging a doc, ask who reads it.**
This was got wrong three times in one session — the PDF, the interactive guide
and `DOCS.html` were each proposed for deletion on the assumption nobody used
them. All three had readers. If the answer is not known, ask; do not advise.

### Pending — decided, not yet done

- **`docs/source/` is not complete.** The build prints how many notes are
  missing; it is 19 of 90 today, all of them under `features/auth/` and
  `features/notifications/`. Every file in `core/`, `design_system/`,
  `core/navigation/` and `features/dashboard/` is annotated.
- **`01_CORE.md` still lists `BiometricService` under `core/security/`.** It
  moved to `features/auth/data/services/`. `00_INDEX.md` is fixed; §12 of
  `01_CORE.md` is not.
- **Never ship code between machines as a markdown file.** Two root-level
  documents did exactly that, holding whole copies of `theme.dart` and the
  token files as "select all, delete, paste" instructions. The review caught
  them and they are gone. Use a branch.
- **Decide whether `docs/` should be tracked.** It is ignored today, so none of
  the readers in the table above can actually reach what they are listed as
  reading. Ask the senior; changing `.gitignore` binds the whole team, so
  rule 15 applies.
- **Line endings: there is no `.gitattributes`, and it has already cost us.**
  The repo has no line-ending policy and `core.autocrlf` is unset, so git keeps
  whatever bytes it is handed. Source files are committed as LF, but an edit
  made on Windows rewrote seventeen of them as CRLF — one extra byte on every
  line. Nothing looked different on screen, yet every line counted as changed,
  turning a 260-line change into a 4,900-line diff no reviewer could read.
  `* text=auto eol=lf` fixes it for good, but it binds the team, so ask the
  senior. Until then, run both of these before committing:

  ```bash
  git diff --shortstat
  git diff -w --shortstat
  ```

  Two numbers far apart means the diff is mostly line endings. Fix it by
  stripping `\r` **only** from text files git already reports as modified.
  Never run such a command across the whole repo: PNG, `.ico` and every other
  binary holds `\r` as real data and would be destroyed.

### `docs/source/` — kept, and how it actually works

Decided: it stays. Learners read it, and the per-file format is the one they say
they follow most easily.

Two things about it were stated wrongly earlier and are worth correcting, because
they change what "keeping it up to date" means:

- **The code is never stale.** `build_source()` in `build-docs.py` reads every
  `.dart` file under `app/lib/` at build time, numbers the lines, and prints
  them. A page can never show a version of a file that no longer exists.
- **A page exists for every file, annotated or not.** Where
  `docs/source/<path>.md` is missing, the page still builds and says *"Line-by-line
  notes for this file have not been written yet."* The build prints how many are
  missing. So nothing is invisible — it is only unexplained.

**Only the notes can go stale, and only a missing note is a gap.** Adding a file
to `lib/` therefore means adding one note here, and the build tells you if you
forgot.

Naming: replace `/` with `__` and `.dart` with `.md`. So
`core/design_system/responsive/app_window_class.dart` →
`docs/source/core__design_system__responsive__app_window_class.md`. Getting this
wrong produces a file the build silently ignores.

Format: a `**Job:**` line, a short intro, then `## Line X–Y — heading` sections,
each with the code quoted and then explained. Explain the **syntax** as well as
the intent — the readers are learning Dart from this code.

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
- **Guessing a width instead of measuring one.** The funds cards were given a
  hardcoded "a card needs 120px" threshold. It was wrong twice — once on a real
  tablet, once in the tests — because the width a card needs depends on the
  font, the locale (`142.850,20 €` is longer than `€142,850.20`) and the
  reader's text-size setting, none of which a constant can know. It now measures
  the real strings with a `TextPainter`, so overflow is arithmetically
  impossible rather than merely unlikely. Prefer measuring over guessing
  anywhere text drives layout.
- **Widget-test fonts are not device fonts.** Every glyph in a widget test is a
  fixed-width box, far wider than real type. A test that asserts a layout turns
  over at a specific pixel width is asserting the test font, not the device.
  Assert the rule and the invariant instead — here, that no amount is ever cut.
- **Overflowing text raises nothing.** A `RenderFlex` overflow throws in debug,
  so `expect(tester.takeException(), isNull)` catches it. Text that spills past
  its box does not throw, and `find.text()` still finds a clipped string in
  full. Assert `RenderParagraph.didExceedMaxLines`, or compare painted bounds.
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
- **Config:** no full URLs in endpoint constants. `AppConfig` owns the base URL;
  `ApiConstants` holds relative paths. Environments are compile-time, via
  `--dart-define-from-file=config/env_*.json`, never a hardcoded host.

### What is and is not a secret

| File | Contains | Commit? |
|---|---|---|
| `firebase_options.dart` | project identifiers | ✅ yes |
| `firebase-messaging-sw.js` | the same identifiers, for the browser | ✅ yes |
| `google-services.json` / `GoogleService-Info.plist` | the same, for mobile | ✅ yes |
| `firebase-service-account.json` | **Admin SDK private key** | 🔴 **never** |

Firebase's own documentation is explicit that API keys restricted to Firebase
services are not secrets. Protection comes from Security Rules and App Check,
not from hiding an identifier that ships inside every client bundle.

The service account key is different in kind: it can send to every device in the
project. It stays on the server, gitignored, always.

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

A plugin with no test-mode implementation must have its method channel mocked,
or the test **hangs** rather than fails — `flutter_secure_storage` is the one
that has caught us.

**A behaviour worth fixing is worth a test.** A fix shipped without one is a fix
the next refactor will quietly undo.

## Backend endpoints

| Method | Path | Notes |
|---|---|---|
| POST | `/api/auth/login` | `{username, password}` → `{success, accessToken, refreshToken, user}`; 401 on bad credentials |
| POST | `/api/auth/refresh` | `{refreshToken}` → a **new pair**; carries no `user` field |
| GET | `/api/user/balance` | Bearer required |
| GET | `/api/user/performance?range=1D\|1W\|1M\|1Y` | Bearer required; default `1Y`, anything else 400. `{currency, range, asOf, baseline, candles: [{time, open, high, low, close}]}`. 1D = 5-minute, 1W = hourly, 1M/1Y = daily (weekdays). `baseline` is the value just before the first candle; change = last close − baseline. Cash flows were dropped as not needed, so a deposit would show as gain. The mock slices `mock_api/data/portfolio_chart.json`, a small ChatGPT-made sample (30 daily, 24 hourly, 25 five-minute candles, values ~10,000). Restart the server after replacing it. Running `scripts/build_portfolio_chart.js` would overwrite it with the older generated set |
| POST | `/api/user/register-device` | `{fcmToken, deviceId, platform, deviceName}`. Replaced `/api/user/register-token`, which now 404s |
| POST | `/api/notify/send` | `{username, title, body}` — push trigger |

**Both tokens rotate on every refresh** — persisting only the new access token
breaks the next refresh. Treat them as opaque: never parse one client-side.

⚠️ **The mock does not issue real JWTs.** The senior's note describes
HMAC-SHA256 signed tokens with 1-hour / 30-day lifetimes, but
`mock_api/middleware/auth.js` returns `activotrade_mock_jwt_token_for_<userId>`
— a prefix, no signature, no expiry — and `package.json` has no JWT library.
`routes/auth.js` also compares `user.passwordHash === password` in plaintext.

Consequence: the access token never expires locally, so **AuthInterceptor's
refresh-on-401 path is never exercised against the mock.** That code is covered
by unit tests only. Ask before assuming the mock behaves like production.

## Current state

Keep this section true. A stale entry here is worse than no entry: it is loaded
into every session and is trusted before the code is read.

**Built and wired:**

- **Auth** — password login, secure token storage, `AuthInterceptor` with
  refresh-on-401 behind a retry lock, `TokenRefresher`, auto-login from a stored
  session, biometric unlock with explicit opt-in (`biometric_onboarding_screen`,
  `locked_screen`).
- **Session + routing** — `AppAuthCubit` lives above `MaterialApp`; `go_router`
  redirects off it. Deep links parse a push payload into a location, with
  `/alerts/:id` as the one id route.
- **Push** — `firebase_core` + `firebase_messaging` +
  `flutter_local_notifications`. Foreground banner, tap handling from all three
  entry points, permission dialog, permanently-denied state with an **Open
  settings** MethodChannel, and a re-check on app resume. Android, iOS and web.
- **Design system** — `tokens/` (colour, type, spacing, radius, sizing,
  opacity), `responsive/` (breakpoints, window class, `AdaptiveTwoColumn`),
  `theme.dart` (explicit light and dark `ColorScheme`s), and the shared widgets
  `AppBadge`, `StatusDot`, `SectionHeader`, `SpacedColumn`/`EqualWidthRow`,
  `AppSnackBar`. A test asserts WCAG AA contrast on every pair and every tone.
- **Dashboard console** — `NetWorthCard`, performance panel, `FundsBreakdown`
  (three `StatCard`s that reflow from their own measured width), `QuickLinksCard`.
  **The card figures are hardcoded placeholders**, though `DashboardCubit` and
  `DashboardService.balance()` exist and work. The chart uses the mock API.
- **Performance chart** — TradingView Lightweight Charts v5.2.1 (Apache 2.0,
  bundled in `app/assets/chart/`; keep the TradingView logo on) in a WebView
  (`webview_flutter` + `webview_flutter_web`). `PerformanceCubit` loads a
  `PerformanceRange` (1D/1W/1M/1Y, starts on 1Y) and drops a slow answer for a
  range the user already left. `PerformancePanel` = `PerformanceRangeSelector`
  (a `SegmentedButton`) + `PerformanceSummary` (change €/% and High, computed in
  `PerformanceHistory`) + `PerformanceChart`, or a spinner / error with Retry.
  Candle times are the market's wall clock stored as UTC, so the phone's
  timezone never shifts 09:00. `PerformanceChartPage` builds one HTML string
  (nothing is sent after load, because on web Dart cannot call into the iframe),
  escapes every `<` in the data, and waits for a real size before drawing, or
  the chart comes out blank. Checked on the web release build; **not yet on
  Android or iOS**. The range buttons sit under the total, not in the header
  row as in the design.
- **App frame** — `core/navigation/`. `AppFrame` wraps every signed-in screen:
  a `NavigationBar` below 768px, a hand-built `SideMenu` above it,
  and a profile menu (avatar initials, sign out). On a phone the profile menu
  sits in the header; on a sidebar layout it moves to the bottom of `SideMenu`
  instead. Tax & Fiscal and Settings sit in `SideMenu`; on a phone they move
  into the profile menu and open as a sub-page with a back arrow, because the
  bottom bar cannot show "no tab selected". Routing is one
  `StatefulShellRoute.indexedStack` with a branch per `AppSection`, in enum
  order — the frame turns a branch index straight back into a section.
  Holdings, Orders, Education, Tax and Settings are `ComingSoon` placeholders,
  wired so nothing is dead.
- **`SideMenu` is deliberately not a `NavigationRail`, and that cost something.**
  A rail fills the height it is given and will not scroll its own destinations,
  so six rows plus the brand block and the avatar did not fit a phone held
  sideways (844×390). The rail version needed a `LayoutBuilder`, a
  `ConstrainedBox(minHeight:)` and an `IntrinsicHeight` to survive that; plain
  rows in an `Expanded` + `SingleChildScrollView` do it with none of them.
  `NavigationRail(extended: true)` would have solved the icon-beside-label half
  of this, so the height problem is the real reason — not the layout.

  **What the swap cost:** a rail announced each entry to a screen reader for
  free, including which one is current. Hand-built rows do not, so `_NavRow`
  carries its own `Semantics` with `button`, `selected`, `label`, **`onTap`
  and `excludeSemantics: true`**. The last two go together:
  `excludeSemantics` stops the inner `Text` being read a second time, but it
  also hides the `InkWell`'s tap, so without `onTap` a TalkBack double-tap
  opens nothing. Review caught each half in turn; a test in
  `app_frame_test.dart` now checks the tap action. Rule 7 is the general form
  of this: replacing a Material widget means taking over every job it was
  doing silently, and accessibility is the one nobody notices is missing.
- **The side menu is 256px wide, so the page gets less room.** Two columns are
  chosen from the width the page body really has, measured by
  `AdaptiveTwoColumn`, not from the window: `AppBreakpoints.twoColumnBody`
  (879 = 1024 − 80 − 1px divider − 64px of gaps). That is the body width the
  console had at a 1024px window beside the old 80px rail, so the columns are
  no narrower than what was approved. With the 256px menu, two columns now
  start at a 1200px window; below that the cards stack, so 1024–1199px
  landscape iPads get one column. That is deliberate — do not "fix" it to 703. `ScreenSize` still sorts windows (`AppBreakpoints.expanded`,
  1024) but no longer decides columns.
- **No app bar anywhere in the frame.** `PageHeader`
  (`design_system/widgets/`) is a plain row inside the page instead: title
  left, buttons right, back arrow when needed. A Material `AppBar` is a band
  across the whole window, so on a tablet it ran above `SideMenu` and the menu
  began halfway down the screen. The header and the page body both pad
  themselves with `ScreenSize.pageGap`, which is the only reason the title
  lines up with the first card. Three consequences worth knowing: `AppFrame`
  now owns a `SafeArea` for both layouts, because no app bar is clearing the
  notch; the console's greeting is the header's **title**
  (`Welcome back, {name}`), which is why `dashboard_screen.dart` no longer
  renders one; and the page (`shell`) is wrapped in
  `Semantics(container: true)`. The page's route hides from screen readers
  everything drawn before it. An `AppBar` is drawn after the body, so it was
  never hit, but the header and `SideMenu` are drawn first, and without the
  fence TalkBack could reach only the page and the bottom bar.
- **iOS CI** — `.github/workflows/ios-build.yml` compiles on a macOS runner,
  launches the app on a simulator, and uploads a screenshot. Manual trigger or
  an `ios-test-*` tag only; macOS minutes bill at 10x.
- EN/ES localization throughout, unit + widget tests.

**Not built:** real content behind Holdings, Orders, Education, Tax & Fiscal and
Settings; real data in the console cards; a real performance API; release
signing and minification. No Apple Developer account yet, so no device install,
no TestFlight, no real iOS push.

The old `DashboardBody` and `PortfolioSummaryCard` have been removed; the console
cards are the only dashboard presentation.

## Roadmap

Build in this order — each step unblocks the next.

1. **Real console data.** Replace the placeholder figures with `DashboardCubit`
   state, and add an error state the user can act on. The cards already take
   pre-formatted strings, so this is a wiring change, not a layout one.
2. **Performance chart** — built on the mock API (Lightweight Charts in a
   WebView). Its two packages still need the senior's sign-off (rule 15), and
   it needs a device check on Android and iOS.
3. **Data layer.** Introduce repositories between Cubits and services once a
   second data source or caching appears — Flutter's guidance recommends
   abstract repository classes so environments can swap implementations. Today
   they would be pass-through classes, so they are deliberately deferred.
4. **Release** — signing, minification, and the Apple Developer enrolment that
   device testing depends on.

## Before proposing changes

- Prefer no change: if existing code is production quality, say so.
- Only add a package with a stated engineering reason.
- Do not restructure the architecture without a measurable benefit.
- Validate against `flutter analyze` and `flutter test` before claiming success.

### Checked, or assumed?

Every wrong answer this project has produced came from the same place: an
answer given from memory when verification was one step away. The fix is not to
think harder, it is to look.

- **Say which one it is.** Label a claim *checked* or *assumed*. The reader
  needs to know what to trust.
- **A claim about a relationship needs both sides read.** "These two overlap",
  "this is dead", "nothing uses this" — open both files first. Grep is not a
  reading.
- **A number that describes rendered text is measured, not chosen.** Entry M8.
- **A claim about behaviour needs an observation.** Entry M3.
- **Ask for output rather than guessing at it.** `flutter analyze`, `git status`
  and a browser console have settled more questions here than any amount of
  reasoning, and they settle them in one round instead of three.

One question catches most of this before it costs anything: **"is that checked,
or assumed?"**
