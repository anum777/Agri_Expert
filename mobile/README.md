$env:Path += ";C:\src\flutter\bin"
flutter --version[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")git --versionMobile Flutter App for Agri Expert

## Features

- **Phone Number Authentication** (OTP-based) with Firebase
- Location-based geolocation
- Soil parameter input form
- Prediction history stored in Firestore
- Dashboard with user authentication state

## Setup & Run Instructions

### Step 1: Install Flutter
Download and install Flutter from https://flutter.dev

Verify installation:
```bash
flutter --version
```

### Step 2: Clone/Navigate to Project
```bash
cd c:\Users\anushka\Agri_Expert\mobile
```

### Step 3: Install Dependencies
```bash
flutter pub get
```

### Step 4: Set Up Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Create a Project** → Name it `agri-expert`
3. Enable Google Analytics (optional)

### Step 5: Configure Firebase Phone Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Phone**
3. Add your test phone numbers (for development/testing)

For Android:
- Go to **Project Settings** → **Android** → Add your app package name (usually `com.example.agri_expert_app`)
- Download the `google-services.json` file
- Place it in: `android/app/google-services.json`

For iOS:
- Go to **Project Settings** → **iOS** → Add your app bundle ID
- Download the `GoogleService-Info.plist` file
- Place it in: `ios/Runner/GoogleService-Info.plist`

### Step 6: Auto-Configure Firebase (Recommended)

```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

Select:
- Project: `agri-expert`
- Platforms: Android, iOS (or just your target platform)

This will automatically update `lib/firebase_options.dart`

### Step 7: Run the App

**On Emulator/Simulator:**
```bash
flutter emulators --launch <emulator_name>
flutter run
```

**On Physical Device:**
```bash
flutter run
```

### Step 8: Test Phone Authentication

1. Enter a test phone number (e.g., `9876543210`)
2. Click "Send OTP"
3. In Firebase Console → Authentication → Use the test phone number to get the OTP
4. Enter the 6-digit OTP
5. You should be logged in and see the Dashboard

## Project Architecture

- **Firebase Phone Auth**: OTP-based authentication
- **Firestore**: User profiles and prediction history storage
- **Geolocator**: GPS coordinates for location
- **HTTP**: API calls to backend (TODO)

## File Structure

```
mobile/
├── lib/
│   ├── main.dart                 # App entry, AuthScreen, navigation
│   ├── firebase_options.dart     # Firebase config (auto-generated)
│   └── services/
│       └── firebase_service.dart # Firebase auth & Firestore methods
├── pubspec.yaml                  # Dependencies
└── android/                       # Android configuration
└── ios/                          # iOS configuration
```

## Next Steps

1. Test login with phone number
2. Implement location permission & OpenWeatherMap API integration
3. Connect to FastAPI backend for crop recommendations
4. Add crop prediction history UI
5. Test on real device

## Troubleshooting

**"MissingPluginException"** → Run `flutter clean && flutter pub get && flutter run`

**Phone number not recognized** → Ensure format is `10 digits`, without country code (will be added as `+91`)

**Firebase not initialized** → Check that `firebase_options.dart` is properly configured with your Firebase credentials

## Testing Credentials (for Firebase Console)

After enabling Phone Authentication:
1. Go to Firebase Console → Authentication → Settings
2. Add test phone numbers (up to 50)
3. Auto-generate 6-digit OTP from console for testing
