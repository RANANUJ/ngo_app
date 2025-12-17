#!/bin/bash

# Emergency Sound Download Script
# This script helps you download a free emergency alert sound

echo "Emergency Alert Sound Setup"
echo "============================"
echo ""
echo "OPTION 1: Download from Pixabay (Recommended)"
echo "---------------------------------------------"
echo "1. Visit: https://pixabay.com/sound-effects/search/emergency/"
echo "2. Search for: 'emergency alert' or 'siren'"
echo "3. Download a suitable sound (MP3 format)"
echo "4. Rename to: emergency_alert.mp3"
echo ""
echo "OPTION 2: Download from Freesound"
echo "---------------------------------"
echo "1. Visit: https://freesound.org/search/?q=emergency+alert"
echo "2. Find a suitable emergency sound"
echo "3. Download in MP3 format"
echo "4. Rename to: emergency_alert.mp3"
echo ""
echo "OPTION 3: Direct Link (Example)"
echo "-------------------------------"
echo "Download this emergency siren sound:"
echo "https://pixabay.com/sound-effects/search/emergency/"
echo ""
echo "Installation Steps:"
echo "==================="
echo "1. After downloading, rename the file to: emergency_alert.mp3"
echo "2. Copy to: assets/emergency_alert.mp3"
echo "3. Copy to: android/app/src/main/res/raw/emergency_alert.mp3"
echo "4. Run: flutter pub get"
echo "5. Rebuild app: flutter clean && flutter run"
echo ""
echo "Recommended Sound Characteristics:"
echo "- Duration: 2-3 seconds"
echo "- Format: MP3"
echo "- Volume: High"
echo "- Type: Siren, alarm, or alert sound"
echo ""

# For Linux/Mac users, uncomment below to download a sample sound
# wget -O emergency_alert.mp3 "https://example.com/emergency-sound.mp3"
# cp emergency_alert.mp3 assets/
# cp emergency_alert.mp3 android/app/src/main/res/raw/
