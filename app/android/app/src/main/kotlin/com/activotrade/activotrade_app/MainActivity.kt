package com.activotrade.activotrade_app

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth shows the system biometric prompt as a fragment, which requires
// a FragmentActivity host. Extending FlutterActivity crashes on authenticate().
class MainActivity : FlutterFragmentActivity()
