package com.sparkbytekh.tilomnov

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var callChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tilomnov/call")
        callChannel?.setMethodCallHandler { call, result ->
            if (call.method != "update") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val args = call.arguments as? Map<*, *>
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
        super.onNewIntent(intent)
        if (intent.action == "tilomnov.RETURN_TO_CALL") callChannel?.invokeMethod("return", null)
    }
}
