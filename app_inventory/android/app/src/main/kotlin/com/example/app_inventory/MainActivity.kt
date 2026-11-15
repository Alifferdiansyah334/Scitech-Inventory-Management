package com.example.app_inventory

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var keyboardInsets: KeyboardInsets? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sims/app_updates")
        val updates = AppUpdates(this, channel)
        channel.setMethodCallHandler { call, result -> updates.handle(call, result) }
        val keyboard = KeyboardInsets(window.decorView)
        keyboardInsets = keyboard
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "sims/keyboard_insets")
            .setStreamHandler(keyboard)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        keyboardInsets?.dispose()
        keyboardInsets = null
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "sims/keyboard_insets")
            .setStreamHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
