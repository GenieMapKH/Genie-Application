package com.sparkbytekh.tilomnov

import android.app.KeyguardManager
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.ProgressBar
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var callChannel: MethodChannel? = null
    private var incomingCallId: String? = null
    private var pendingCallId: String? = null
    private var startupCover: View? = null
    private val startupHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prepareCallIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tilomnov/call")
        callChannel?.setMethodCallHandler { call, result ->
            if (call.method == "unlock") {
                unlockForNavigation(result)
                return@setMethodCallHandler
            }
            if (call.method != "update") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val args = call.arguments as? Map<*, *>
                val phase = args?.get("phase")
                if (phase == "incoming" ||
                    (pendingCallId != null && pendingCallId == args?.get("id") &&
                        (phase == "connecting" || phase == "active"))) {
                    incomingCallId = args?.get("id") as? String
                }
                else if (phase != "connecting" && phase != "active") incomingCallId = null
                if (args?.get("screenVisible") != true) incomingCallId = null
                showIncomingOverLockScreen(incomingCallId != null && incomingCallId == args?.get("id"))
                finishCallStartup()
                val service = Intent(this, CallAudioService::class.java)
                if (args?.get("phase") == "active") {
                    service.putExtra("name", args["name"] as? String)
                    service.putExtra("title", args["title"] as? String)
                    service.putExtra("returnLabel", args["returnLabel"] as? String)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(service)
                    else startService(service)
                } else if (args?.get("phase") == "ended" || args?.get("phase") == "idle") {
                    stopService(service)
                }
                result.success(null)
            } catch (error: Exception) {
                result.error("call_service", "Background call service could not start", null)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        prepareCallIntent(intent)
        super.onNewIntent(intent)
        if (intent.action == "tilomnov.RETURN_TO_CALL") callChannel?.invokeMethod("return", null)
    }

    private fun prepareCallIntent(intent: Intent) {
        val payload = try { JSONObject(intent.getStringExtra("payload") ?: "{}") }
            catch (_: Exception) { JSONObject() }
        val id = payload.optString("callId")
        val opensCall = (intent.action == "SELECT_NOTIFICATION" ||
            intent.action == "SELECT_FOREGROUND_NOTIFICATION") &&
            payload.optString("type") == "call_incoming" && id.isNotBlank()
        if (!opensCall) {
            incomingCallId = null
            showIncomingOverLockScreen(false)
            finishCallStartup()
            return
        }
        if (incomingCallId != id) {
            pendingCallId = id
            // Resume Flutter without showing the previous screen over the keyguard.
            setStartupContentHidden(true)
            startupHandler.removeCallbacksAndMessages(null)
            startupHandler.postDelayed({
                if (pendingCallId == id) {
                    incomingCallId = null
                    showIncomingOverLockScreen(false)
                    finishCallStartup()
                }
            }, 45_000)
        }
        showIncomingOverLockScreen(true)
    }

    private fun finishCallStartup() {
        pendingCallId = null
        startupHandler.removeCallbacksAndMessages(null)
        setStartupContentHidden(false)
    }

    private fun setStartupContentHidden(hidden: Boolean) {
        val root = findViewById<ViewGroup>(android.R.id.content) ?: return
        root.getChildAt(0)?.importantForAccessibility = if (hidden) View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            else View.IMPORTANT_FOR_ACCESSIBILITY_AUTO
        if (hidden && startupCover == null) {
            startupCover = FrameLayout(this).apply {
                setBackgroundColor(Color.BLACK)
                isClickable = true
                isFocusable = true
                addView(ProgressBar(context), FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.CENTER))
            }
            root.addView(startupCover, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        } else if (!hidden) {
            startupCover?.let { root.removeView(it) }
            startupCover = null
        }
    }

    override fun onDestroy() {
        startupHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun unlockForNavigation(result: MethodChannel.Result) {
        fun unlocked() {
            incomingCallId = null
            showIncomingOverLockScreen(false)
            result.success(true)
        }
        val keyguard = getSystemService(KeyguardManager::class.java)
        if (!keyguard.isKeyguardLocked) unlocked()
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            keyguard.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                override fun onDismissSucceeded() = unlocked()
                override fun onDismissCancelled() { result.success(false) }
                override fun onDismissError() { result.success(false) }
            })
        } else result.success(false)
    }

    private fun showIncomingOverLockScreen(show: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(show)
            setTurnScreenOn(show)
        } else {
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (show) window.addFlags(flags) else window.clearFlags(flags)
        }
    }
}
