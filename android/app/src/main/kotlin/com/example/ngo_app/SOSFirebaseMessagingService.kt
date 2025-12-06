package com.example.ngo_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class SOSFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "SOSMessagingService"
        private const val SOS_CHANNEL_ID = "sos_alert_channel"
        private const val SOS_NOTIFICATION_ID = 999
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "Message received from: ${remoteMessage.from}")

        val data = remoteMessage.data
        Log.d(TAG, "Message data: $data")
        Log.d(TAG, "Message notification: ${remoteMessage.notification?.title}")

        // Check if this is an SOS alert (from data payload)
        val type = data["type"] ?: ""

        if (type == "sos_alert") {
            Log.d(TAG, "SOS Alert received! Launching full-screen activity directly...")
            
            // Wake up the device
            wakeUpDevice()
            
            // Launch the SOS activity DIRECTLY - don't show notification
            launchSOSAlertActivity(data)
            
            // Also show notification as backup
            showFullScreenNotification(data)
            
            // Return to prevent default notification handling
            return
        }
        
        // For non-SOS messages, use default handling
        super.onMessageReceived(remoteMessage)
    }

    private fun wakeUpDevice() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "ngo_app:sos_wake_lock"
            )
            wakeLock.acquire(10000L) // 10 seconds
            Log.d(TAG, "Device wake lock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to wake device: ${e.message}")
        }
    }

    private fun launchSOSAlertActivity(data: Map<String, String>) {
        try {
            val intent = Intent(this, SOSAlertActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP

                putExtra("sosId", data["sosId"] ?: "")
                putExtra("volunteerId", data["volunteerId"] ?: "")
                putExtra("volunteerName", data["volunteerName"] ?: "Unknown")
                putExtra("volunteerPhone", data["volunteerPhone"] ?: "")
                putExtra("emergencyType", data["emergencyType"] ?: "Emergency")
                putExtra("address", data["address"] ?: "Unknown location")
                putExtra("latitude", data["latitude"] ?: "")
                putExtra("longitude", data["longitude"] ?: "")
            }
            
            startActivity(intent)
            Log.d(TAG, "SOS Alert activity launched directly")
        } catch (e: Exception) {
            Log.e(TAG, "Error launching SOS alert activity: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun showFullScreenNotification(data: Map<String, String>) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Create notification channel for Android O+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    SOS_CHANNEL_ID,
                    "SOS Emergency Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Critical SOS emergency alerts"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
                    setBypassDnd(true)
                    lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                    setSound(
                        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                }
                notificationManager.createNotificationChannel(channel)
            }

            // Create intent for the full-screen activity
            val fullScreenActivityIntent = Intent(this, SOSAlertActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_NO_USER_ACTION

                putExtra("sosId", data["sosId"] ?: "")
                putExtra("volunteerId", data["volunteerId"] ?: "")
                putExtra("volunteerName", data["volunteerName"] ?: "Unknown")
                putExtra("volunteerPhone", data["volunteerPhone"] ?: "")
                putExtra("emergencyType", data["emergencyType"] ?: "Emergency")
                putExtra("address", data["address"] ?: "Unknown location")
                putExtra("latitude", data["latitude"] ?: "")
                putExtra("longitude", data["longitude"] ?: "")
            }

            val fullScreenPendingIntent = PendingIntent.getActivity(
                this,
                0,
                fullScreenActivityIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val volunteerName = data["volunteerName"] ?: "Unknown"
            val emergencyType = data["emergencyType"] ?: "Emergency"
            val address = data["address"] ?: "Unknown location"

            // Build the notification
            val notification = NotificationCompat.Builder(this, SOS_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("🚨 EMERGENCY SOS ALERT")
                .setContentText("$volunteerName needs help!")
                .setStyle(NotificationCompat.BigTextStyle()
                    .bigText("$volunteerName needs help!\n$emergencyType\n📍 $address"))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .setOngoing(true)
                .setVibrate(longArrayOf(0, 500, 200, 500, 200, 500))
                .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .setContentIntent(fullScreenPendingIntent)
                .build()

            // Show the notification - this will trigger the full-screen intent
            notificationManager.notify(SOS_NOTIFICATION_ID, notification)
            Log.d(TAG, "Full-screen notification shown")

        } catch (e: Exception) {
            Log.e(TAG, "Error showing full-screen notification: ${e.message}")
            e.printStackTrace()
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")
        // Token refresh is handled by the Flutter app
    }
}
