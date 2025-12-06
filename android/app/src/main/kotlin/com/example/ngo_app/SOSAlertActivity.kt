package com.example.ngo_app

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class SOSAlertActivity : AppCompatActivity() {

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var isVibrating = false

    companion object {
        private const val SOS_NOTIFICATION_ID = 999
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Cancel the notification since we're showing the activity
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(SOS_NOTIFICATION_ID)

        // Show on lock screen and turn screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        // Make fullscreen
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        )

        setContentView(R.layout.activity_sos_alert)

        // Get data from intent
        val volunteerName = intent.getStringExtra("volunteerName") ?: "Unknown"
        val emergencyType = intent.getStringExtra("emergencyType") ?: "Emergency"
        val address = intent.getStringExtra("address") ?: "Unknown location"
        val sosId = intent.getStringExtra("sosId") ?: ""
        val volunteerId = intent.getStringExtra("volunteerId") ?: ""
        val volunteerPhone = intent.getStringExtra("volunteerPhone") ?: ""

        // Update UI
        findViewById<TextView>(R.id.alertTitle).text = "🚨 SOS ALERT"
        findViewById<TextView>(R.id.volunteerName).text = volunteerName
        findViewById<TextView>(R.id.emergencyType).text = emergencyType
        findViewById<TextView>(R.id.address).text = address

        // Start alarm sound and vibration
        startAlarm()
        startVibration()

        // OK button - dismiss alert and open app
        findViewById<Button>(R.id.btnAcknowledge).setOnClickListener {
            stopAlarm()
            stopVibration()
            
            // Open main app with SOS details
            val mainIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("sosId", sosId)
                putExtra("volunteerId", volunteerId)
                putExtra("volunteerName", volunteerName)
                putExtra("volunteerPhone", volunteerPhone)
                putExtra("emergencyType", emergencyType)
                putExtra("address", address)
                putExtra("type", "sos_alert")
                putExtra("fromSOSAlert", true)
            }
            startActivity(mainIntent)
            finish()
        }

        // Dismiss button - just close the alert
        findViewById<Button>(R.id.btnDismiss).setOnClickListener {
            stopAlarm()
            stopVibration()
            finish()
        }
    }

    private fun startAlarm() {
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(this@SOSAlertActivity, alarmUri)
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAlarm() {
        mediaPlayer?.let {
            if (it.isPlaying) {
                it.stop()
            }
            it.release()
        }
        mediaPlayer = null
    }

    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        isVibrating = true
        
        // Create a repeating vibration pattern
        val pattern = longArrayOf(0, 500, 200, 500, 200, 500, 500)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun stopVibration() {
        if (isVibrating) {
            vibrator?.cancel()
            isVibrating = false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
        stopVibration()
    }

    override fun onBackPressed() {
        // Prevent back button from dismissing the alert
        // User must tap one of the buttons
    }
}
