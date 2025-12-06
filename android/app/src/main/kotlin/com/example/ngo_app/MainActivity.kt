package com.example.ngo_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SOS_CHANNEL = "com.example.ngo_app/sos_alert"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showSOSAlert" -> {
                    val data = call.arguments as? Map<String, Any?> ?: emptyMap()
                    showSOSAlertActivity(data)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showSOSAlertActivity(data: Map<String, Any?>) {
        val intent = Intent(this, SOSAlertActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            
            putExtra("sosId", data["sosId"]?.toString() ?: "")
            putExtra("volunteerId", data["volunteerId"]?.toString() ?: "")
            putExtra("volunteerName", data["volunteerName"]?.toString() ?: "Unknown")
            putExtra("volunteerPhone", data["volunteerPhone"]?.toString() ?: "")
            putExtra("emergencyType", data["emergencyType"]?.toString() ?: "Emergency")
            putExtra("address", data["address"]?.toString() ?: "Unknown location")
            putExtra("latitude", data["latitude"]?.toString() ?: "")
            putExtra("longitude", data["longitude"]?.toString() ?: "")
        }
        startActivity(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if launched from SOS alert notification
        handleSOSIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleSOSIntent(intent)
    }

    private fun handleSOSIntent(intent: Intent?) {
        intent?.let {
            if (it.getBooleanExtra("fromSOSAlert", false)) {
                // SOS alert was acknowledged, can pass data to Flutter if needed
                val sosId = it.getStringExtra("sosId")
                // Handle the SOS navigation in Flutter via method channel if needed
            }
        }
    }
}
