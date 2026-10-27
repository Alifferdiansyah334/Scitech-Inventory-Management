package com.example.app_inventory

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sims/app_updates")
        val updates = AppUpdates(this, channel)
        channel.setMethodCallHandler { call, result -> updates.handle(call, result) }
    }
}
