package com.activotrade.activotrade_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth shows the system biometric prompt as a fragment, which requires
// a FragmentActivity host. Extending FlutterActivity crashes on authenticate().
class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" ->
                        result.success(openNotificationSettings())
                    else -> result.notImplemented()
                }
            }
    }

    /// Returns false when nothing opened, so Dart can say so instead of
    /// leaving the user looking at a button that did nothing.
    private fun openNotificationSettings(): Boolean {
        // ACTION_APP_NOTIFICATION_SETTINGS needs API 26 and minSdk is 24, so
        // older devices get the app's details page — one tap further away.
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
        }

        return try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            // A device with no settings activity for this intent. Rare, but
            // crashing the app over a convenience button would be worse.
            false
        }
    }

    private companion object {
        const val CHANNEL = "activotrade/app_settings"
    }
}
