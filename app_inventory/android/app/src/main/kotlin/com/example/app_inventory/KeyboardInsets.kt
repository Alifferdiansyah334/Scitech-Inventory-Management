package com.example.app_inventory

import android.os.Build
import android.view.View
import android.view.ViewTreeObserver
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.plugin.common.EventChannel

/** Flutter's pre-30 IME heuristic misses devices exposing only visible insets. */
class KeyboardInsets(private val root: View) : EventChannel.StreamHandler,
    ViewTreeObserver.OnGlobalLayoutListener {
    private var sink: EventChannel.EventSink? = null
    private var lastBottom = -1

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        lastBottom = -1
        if (Build.VERSION.SDK_INT >= 30) {
            events.success(0)
            return
        }
        root.viewTreeObserver.addOnGlobalLayoutListener(this)
        root.post { onGlobalLayout() }
    }

    override fun onGlobalLayout() {
        if (sink == null) return
        val insets = ViewCompat.getRootWindowInsets(root) ?: return
        val bottom = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
        if (bottom != lastBottom) {
            lastBottom = bottom
            sink?.success(bottom)
        }
    }

    override fun onCancel(arguments: Any?) {
        dispose()
    }

    fun dispose() {
        if (root.viewTreeObserver.isAlive) {
            root.viewTreeObserver.removeOnGlobalLayoutListener(this)
        }
        sink = null
    }
}
