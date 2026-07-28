# ActivoTrade App

ActivoTrade is a wealth management mobile application engineered with Flutter.
---

## Repository Structure

```text
app/                             <-- activotrade_app
├── lib/
│   ├── core/                    <-- Global shared resources
│   │   ├── constants/           <-- Colors, API endpoints
│   │   ├── design_system/       <-- Theme, tokens, typography
│   │   ├── network/             <-- HTTP Client, JWT interceptor
│   │   ├── security/            <-- SecureStorage, local_auth biometrics
│   │   └── router/              <-- Router configurations
│   └── features/                <-- Feature-first modules
│       ├── auth/                <-- Login UI, JWT controller, biometrics
│       ├── notifications/       <-- FCM token registration & handlers
│       ├── funding/             <-- Feature 1
│       ├── dashboard/           <-- Feature 2
│       └── portfolio/           <-- Feature 3
└── pubspec.yaml
```

Each feature module inside lib/features/<feature_name>/ must follow this structure:

```text
lib/features/<feature_name>/
├── <feature_name>_screen.dart        # Screen assembly (~50–100 lines)
├── <feature_name>_cubit.dart         # Business logic & state management
├── <feature_name>_state.dart         # State declarations
└── widgets/                          # Extracted sub-widgets
    ├── portfolio_summary_card.dart   # Individual, modular sub-widget
    ├── asset_allocation_card.dart
    └── position_item_tile.dart
```