# SOS Emergency Alert Sound & Vibration Setup Guide

## Overview
This guide explains how to set up emergency alert sounds and vibration for SOS notifications that work even when the device is closed/locked.

## Features Implemented
✅ 10-second emergency sound playback
✅ Continuous vibration pattern for 10 seconds
✅ Works when app is in foreground, background, or closed
✅ Custom emergency sound support
✅ Maximum priority notifications

## Setup Steps

### 1. Add Emergency Sound File

You need to add an actual emergency alert sound file in two locations:

#### For Assets (Flutter)
1. Download an emergency alert sound (MP3 format, 2-3 seconds duration)
2. Save it as `emergency_alert.mp3`
3. Place it in: `assets/emergency_alert.mp3`

#### For Android Raw Resources (Notifications)
1. Use the same or another emergency sound file
2. Save it as `emergency_alert.mp3`
3. Place it in: `android/app/src/main/res/raw/emergency_alert.mp3`

**Free Sound Sources:**
- https://pixabay.com/sound-effects/search/emergency/
- https://freesound.org/search/?q=emergency+alert
- https://www.zapsplat.com/ (requires free account)

**Recommended Sound Characteristics:**
- Format: MP3
- Duration: 2-3 seconds (will loop)
- Volume: High/Maximum
- Type: Siren, alarm, or alert sound
- Bitrate: 128kbps or higher

### 2. Install Dependencies

Run the following command to install the new packages:

```bash
flutter pub get
```

New packages added:
- `audioplayers: ^6.1.0` - For playing custom emergency sounds
- `vibration: ^2.0.0` - For device vibration control

### 3. Deploy Cloud Functions

The Cloud Functions have been updated to send proper emergency notifications:

```bash
firebase deploy --only functions:onSOSCreated
```

### 4. Permissions (Already Configured)

The following permissions are already in AndroidManifest.xml:
- ✅ `VIBRATE` - For device vibration
- ✅ `POST_NOTIFICATIONS` - For showing notifications
- ✅ `USE_FULL_SCREEN_INTENT` - For showing alerts on locked screen
- ✅ `WAKE_LOCK` - For waking up the device
- ✅ `DISABLE_KEYGUARD` - For showing over lock screen

## How It Works

### When App is Running (Foreground)
1. SOS notification received
2. Emergency sound plays for 10 seconds (looping)
3. Device vibrates in pattern: 500ms ON, 200ms OFF (repeated)
4. Full-screen alert dialog appears
5. Sound/vibration stops after 10 seconds or when dismissed

### When App is in Background/Closed
1. Firebase Cloud Messaging delivers high-priority notification
2. Android system shows notification with:
   - Custom emergency sound from raw resources
   - Vibration pattern configured in notification
   - Full-screen intent (shows on locked screen)
3. User can tap to open app and view SOS details

## Emergency Sound Behavior

### Audio Playback
- **Duration**: 10 seconds total
- **Mode**: Looping (2-3 second sound repeats)
- **Volume**: Maximum (1.0)
- **Stops when**:
  - 10 seconds elapsed
  - User dismisses alert
  - `stopEmergencySound()` called

### Vibration Pattern
- **Duration**: 10 seconds total
- **Pattern**: 500ms vibrate, 200ms pause (repeated ~13 times)
- **Amplitude**: Maximum (255)
- **Stops when**:
  - 10 seconds elapsed
  - Sound stops
  - User dismisses alert

## Testing

### Test Emergency Alert in Foreground
1. Keep app open
2. Create an SOS alert from a volunteer device
3. NGO devices should:
   - Play emergency sound loudly
   - Vibrate continuously
   - Show full-screen alert
   - Stop after 10 seconds

### Test Emergency Alert in Background
1. Close or minimize the app
2. Create an SOS alert
3. Device should:
   - Wake up and show notification
   - Play emergency sound
   - Vibrate
   - Show on lock screen

### Test Emergency Alert When Device is Locked
1. Lock the device
2. Create an SOS alert
3. Device should:
   - Turn on screen
   - Show notification on lock screen
   - Play sound and vibrate
   - Allow opening app from lock screen

## Troubleshooting

### Sound Not Playing
**Problem**: Emergency sound doesn't play
**Solutions**:
1. Check if sound file exists in `android/app/src/main/res/raw/emergency_alert.mp3`
2. Ensure file name is exactly `emergency_alert.mp3` (lowercase, no spaces)
3. Verify file is valid MP3 format
4. Check device volume is not muted
5. Try rebuilding the app: `flutter clean && flutter build apk`

### No Vibration
**Problem**: Device doesn't vibrate
**Solutions**:
1. Check device settings - vibration might be disabled globally
2. Verify app has VIBRATE permission
3. Test on physical device (emulators may not support vibration)
4. Check if device has vibration motor (some tablets don't)

### Notification Not Showing on Lock Screen
**Problem**: Notification doesn't appear when device is locked
**Solutions**:
1. Enable "Show on lock screen" in device notification settings
2. Check if "Do Not Disturb" mode is enabled
3. Verify USE_FULL_SCREEN_INTENT permission is granted
4. Some manufacturers (Samsung, Xiaomi) require additional settings

### Sound Plays Too Long or Too Short
**Problem**: Sound duration is incorrect
**Solutions**:
1. Check the emergency sound file duration
2. Adjust the delay in `_playEmergencyAlertSound()` method
3. Modify the loop count in `_startEmergencyVibration()`

## Customization

### Change Sound Duration
Edit `notification_service.dart`:
```dart
// Change from 10 to desired seconds
Future.delayed(const Duration(seconds: 10), () {
  _stopEmergencyAlertSound();
});
```

### Change Vibration Pattern
Edit `notification_service.dart`:
```dart
// Current: 500ms vibrate, 200ms pause
await Vibration.vibrate(duration: 500, amplitude: 255);
await Future.delayed(const Duration(milliseconds: 200));

// Example: Longer vibration
await Vibration.vibrate(duration: 1000, amplitude: 255);
await Future.delayed(const Duration(milliseconds: 300));
```

### Use Different Sound
Replace `emergency_alert.mp3` with your preferred sound file (keep the same name).

## Channel Configuration

The SOS notification channel is configured with:
- **ID**: `sos_alerts_channel`
- **Name**: SOS Alerts
- **Importance**: Max
- **Priority**: Max
- **Sound**: Custom (emergency_alert.mp3)
- **Vibration**: Custom pattern
- **LED Light**: Red (#E53935)
- **Visibility**: Public (shows on lock screen)
- **Category**: Alarm

## Notes

1. **Battery Optimization**: The app may need to be excluded from battery optimization to ensure reliable delivery when device is sleeping.

2. **Manufacturer Restrictions**: Some manufacturers (Xiaomi, Huawei, OnePlus) have aggressive battery management that might affect background notifications.

3. **iOS**: For iOS devices, emergency sounds work slightly differently. The sound file should be in AIFF format and placed in iOS resources.

4. **Testing**: Always test on real devices as emulators have limited sound and vibration support.

## Code References

- **Notification Service**: `lib/services/notification_service.dart`
  - `_playEmergencyAlertSound()` - Sound playback
  - `_startEmergencyVibration()` - Vibration control
  - `stopEmergencySound()` - Manual stop

- **Cloud Functions**: `functions/index.js`
  - `onSOSCreated` - Sends emergency notifications

- **Assets**: `assets/emergency_alert.mp3`
- **Android Resources**: `android/app/src/main/res/raw/emergency_alert.mp3`
