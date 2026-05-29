package com.lablio.app

import androidx.activity.OnBackPressedCallback
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channel = "com.lablio.app/nav"
    private var lastBackPress = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val mc = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)

        onBackPressedDispatcher.addCallback(
            this,
            object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    val now = System.currentTimeMillis()
                    if (now - lastBackPress < 2000L) {
                        // Second press within 2 s → exit immediately.
                        finishAffinity()
                    } else {
                        // First press → let Flutter decide (pop screen or show snackbar).
                        lastBackPress = now
                        mc.invokeMethod("back", null)
                    }
                }
            }
        )
    }
}
