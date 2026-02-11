# Firebase Setup Checklist for Agri Expert

Use this checklist to ensure all Firebase components are properly configured.

## Firebase Project Setup
- [ ] Create Firebase project at https://console.firebase.google.com
- [ ] Project name: `agri-expert`
- [ ] Google Analytics: Optional (can skip)
- [ ] Copy Project ID (you'll need this)

## Firebase Authentication (Phone)
- [ ] Go to: Firebase Console → Authentication
- [ ] Click "Sign-in method" tab
- [ ] Find "Phone" and toggle it ON
- [ ] Add test phone numbers (up to 50 for development)
  - [ ] Test numbers list:
    - 9876543210
    - 8765432109
    - 7654321098
- [ ] Copy the "Phone Number Authentication Code Provider"

## Android Configuration
- [ ] Go to: Firebase Console → Project Settings
- [ ] Click "Android" tab
- [ ] Register Android app:
  - [ ] Package name: `com.example.agri_expert_app`
  - [ ] Click "Register app"
  - [ ] Download `google-services.json`
  - [ ] Place file in: `mobile/android/app/`
  - [ ] Click "Next" through remaining steps

## iOS Configuration
- [ ] Go to: Firebase Console → Project Settings
- [ ] Click "iOS" tab
- [ ] Register iOS app:
  - [ ] Bundle ID: `com.example.agriExpertApp`
  - [ ] Click "Register app"
  - [ ] Download `GoogleService-Info.plist`
  - [ ] Place file in: `mobile/ios/Runner/`

## Run FlutterFire Configuration
```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```
- [ ] Select Firebase project: `agri-expert`
- [ ] Select platforms: Android, iOS (as applicable)
- [ ] Verify `lib/firebase_options.dart` is updated

## Firestore Setup (for data storage)
- [ ] Go to: Firebase Console → Firestore Database
- [ ] Click "Create database"
- [ ] Start in test mode (for development)
- [ ] Select region: `asia-south1` (India) or nearest
- [ ] Create

## Security Rules (Firestore)
- [ ] Go to: Firestore Database → Rules
- [ ] Replace default rules with:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```
- [ ] Publish rules

## Dependencies Check
- [ ] Flutter project dependencies installed: `flutter pub get`
- [ ] pubspec.yaml contains:
  - [ ] firebase_core
  - [ ] firebase_auth
  - [ ] cloud_firestore
  - [ ] geolocator
  - [ ] http

## Testing Setup
- [ ] Run app: `flutter run`
- [ ] Login screen displays
- [ ] Enter test phone number
- [ ] Receive OTP (check Firebase Console or automatic)
- [ ] Login successful → Dashboard appears

## Final Validation
- [ ] User can login with phone + OTP
- [ ] User can logout from dashboard
- [ ] Location permission can be requested
- [ ] Soil form can be filled
- [ ] Data saves to Firestore

## Troubleshooting Notes
- If Firebase not initializing: Check firebase_options.dart credentials
- If OTP not sending: Verify phone auth is enabled in Firebase Console
- If Firestore errors: Check security rules and database creation

## Ready to Run?
Once all items are checked, you can run:
```bash
cd c:\Users\anushka\Agri_Expert\mobile
flutter run
```

Happy coding! 🌾
