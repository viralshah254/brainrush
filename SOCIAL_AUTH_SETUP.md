# 🔐 Social Authentication Setup Guide

## ✅ What's Been Done

1. ✅ Updated all Firebase and auth packages to latest versions
2. ✅ Resolved CocoaPods GoogleUtilities conflict (now using 8.1.0)
3. ✅ Successfully installed all pods
4. ✅ Added iOS Info.plist configuration templates
5. ✅ Added Android manifest configuration
6. ✅ Created strings.xml for Android Facebook config
7. ✅ Smart authentication UI with platform detection
8. ✅ Code compiles successfully

## 🚀 What You Need to Do Now

To get social logins working, you need to configure each provider in their respective developer consoles.

---

## 1️⃣ Google Sign In Setup

### Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **mind-rush-15036**
3. Go to **Authentication** → **Sign-in method**
4. Click on **Google** → **Enable** → **Save**

### iOS Configuration
5. Download the **updated** `GoogleService-Info.plist`:
   - In Firebase Console → Project Settings → Your iOS App
   - Download the plist file (it will now include `CLIENT_ID` and `REVERSED_CLIENT_ID`)
6. Replace `/ios/Runner/GoogleService-Info.plist` with the new one
7. Open `/ios/Runner/Info.plist` and update:
   ```xml
   <!-- Replace this line: -->
   <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
   <!-- With your actual REVERSED_CLIENT_ID from GoogleService-Info.plist -->
   ```

### Android Configuration
- ✅ Already configured! Google Sign In works automatically on Android with Firebase

---

## 2️⃣ Apple Sign In Setup

### Apple Developer Console
1. Go to [Apple Developer](https://developer.apple.com)
2. **Identifiers** → Select your app ID: `com.dvtechventures.mindrush`
3. **Sign In with Apple** → Check ✅ Enable
4. Click **Edit** → Configure if needed
5. Save changes

### Firebase Console
6. Go to Firebase Console → **Authentication** → **Sign-in method**
7. Click on **Apple** → **Enable**
8. You'll need to configure:
   - **Services ID**: Create in Apple Developer (e.g., `com.dvtechventures.mindrush.signin`)
   - **Team ID**: Found in Apple Developer Account (top right)
   - **Key ID** and **Private Key**: Create in Apple Developer → Keys → Create New Key
9. Save

### iOS Configuration
- ✅ Already configured! The iOS app has Sign In with Apple capability

---

## 3️⃣ Facebook Sign In Setup

### Facebook Developer Console
1. Go to [Facebook Developers](https://developers.facebook.com)
2. Create a new app or select existing:
   - **App Type**: Consumer
   - **App Name**: MindRush
3. In Dashboard, note your **App ID** and **App Secret**
4. Go to **Settings** → **Basic**:
   - **Display Name**: MindRush
   - **App Domains**: (leave empty for mobile)
   - **Privacy Policy URL**: `https://www.dvtechventures.com/TandCs`
5. Click **Add Platform** → **iOS**:
   - **Bundle ID**: `com.dvtechventures.mindrush`
   - Enable **Single Sign On**: Yes
6. Click **Add Platform** → **Android**:
   - **Package Name**: `com.dvtechventures.mindrush`
   - **Class Name**: `.MainActivity`
   - Add your **Key Hashes** (see below)
7. **Facebook Login** → **Settings**:
   - Enable **iOS** and **Android**
   - **Valid OAuth Redirect URIs**: (Auto-configured)

### Get Android Key Hash
```bash
# Debug Key Hash
keytool -exportcert -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  | openssl sha1 -binary | openssl base64

# Password: android (if asked)

# Release Key Hash (when you have your release keystore)
keytool -exportcert -alias your-key-alias \
  -keystore /path/to/your-keystore.jks \
  | openssl sha1 -binary | openssl base64
```

### Get Facebook Client Token
8. In Facebook Developer Console → **Settings** → **Advanced**
9. Find **Security** → **Client Token** (copy this)

### iOS Configuration
10. Open `/ios/Runner/Info.plist`
11. Replace these values:
    ```xml
    <!-- Replace these: -->
    <string>fbYOUR-FACEBOOK-APP-ID</string>
    <string>YOUR-FACEBOOK-APP-ID</string>
    <string>YOUR-FACEBOOK-CLIENT-TOKEN</string>
    
    <!-- With your actual values from Facebook Developer Console -->
    <string>fb123456789012345</string>  <!-- fb + App ID -->
    <string>123456789012345</string>     <!-- App ID -->
    <string>abc123def456ghi789</string>  <!-- Client Token -->
    ```

### Android Configuration
12. Open `/android/app/src/main/res/values/strings.xml`
13. Replace these values:
    ```xml
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
    ```

### Firebase Console
14. Go to Firebase Console → **Authentication** → **Sign-in method**
15. Click on **Facebook** → **Enable**
16. Enter your **App ID** and **App Secret** from Facebook
17. Copy the **OAuth redirect URI** from Firebase
18. Go back to Facebook Developer → **Facebook Login** → **Settings**
19. Add the OAuth redirect URI to **Valid OAuth Redirect URIs**
20. Save both Firebase and Facebook settings

---

## 📱 Testing

### To Test on iOS Simulator
```bash
cd /Users/v/Desktop/Apps/mind_rush/mind_rush
flutter run -d "iPhone 15 Pro"
```

### To Test on Physical iOS Device
```bash
# Connect your iPhone via USB
flutter run -d "Your iPhone Name"
```

### To Test on Android Emulator
```bash
flutter run -d emulator-5554
```

### To Test on Physical Android Device
```bash
# Enable USB Debugging on your Android phone
flutter run -d "Your Phone Model"
```

---

## 🧪 What to Test

For each authentication method:

### Email/Password ✅
- [x] Sign up with email
- [x] Sign in with email
- [x] Forgot password
- [x] First-time user → Age collection
- [x] Returning user → Home screen

### Google Sign In
- [ ] Click "Continue with Google"
- [ ] Select Google account
- [ ] First-time → Age collection
- [ ] Returning → Home screen

### Apple Sign In (iOS only)
- [ ] Click "Continue with Apple"
- [ ] Authenticate with Face ID/Touch ID
- [ ] First-time → Age collection
- [ ] Returning → Home screen

### Facebook Sign In
- [ ] Click "Continue with Facebook"
- [ ] Log in to Facebook
- [ ] Grant permissions
- [ ] First-time → Age collection
- [ ] Returning → Home screen

---

## 🐛 Troubleshooting

### Google Sign In Errors

**"channel-error"**
- ✅ FIXED! This was due to GoogleUtilities conflict (now resolved)
- If still occurs: Make sure you downloaded the updated `GoogleService-Info.plist`

**"No client ID"**
- Download the latest `GoogleService-Info.plist` from Firebase Console
- Make sure Google Sign In is enabled in Firebase Console

### Apple Sign In Errors

**"Not available"**
- Apple Sign In only works on iOS 13+
- Must test on physical device or iOS Simulator (not Mac Catalyst)
- Make sure Apple Sign In is enabled in Apple Developer Console

### Facebook Sign In Errors

**"MissingPluginException"**
- ✅ FIXED! Pods are now properly installed
- If still occurs: Run `cd ios && pod install && cd ..`

**"Invalid key hash"**
- Generate your Android key hash using the command above
- Add it to Facebook Developer Console → Settings → Basic → Key Hashes

**"App not set up"**
- Make sure Facebook app is in "Live" mode (not Development)
- Add Facebook App ID and Client Token to platform files

---

## 📋 Quick Checklist

### Firebase Console
- [ ] Google Sign In: Enabled
- [ ] Apple Sign In: Enabled (with Services ID, Team ID, Key)
- [ ] Facebook Sign In: Enabled (with App ID, App Secret, OAuth URI)

### Apple Developer Console
- [ ] App ID has Sign In with Apple capability
- [ ] Services ID created and configured
- [ ] Auth Key created and downloaded

### Facebook Developer Console
- [ ] App created with iOS and Android platforms
- [ ] Bundle IDs and Package Names added
- [ ] Key Hashes added (Android)
- [ ] App in "Live" mode

### iOS Configuration
- [ ] Updated GoogleService-Info.plist with OAuth credentials
- [ ] Replaced REVERSED_CLIENT_ID in Info.plist
- [ ] Replaced Facebook App ID in Info.plist
- [ ] Replaced Facebook Client Token in Info.plist

### Android Configuration
- [ ] Firebase configuration is set up (google-services.json exists)
- [ ] Replaced Facebook App ID in strings.xml
- [ ] Replaced Facebook Client Token in strings.xml

---

## 🎉 When Complete

Once you've completed all configurations:

1. Clean and rebuild:
```bash
flutter clean
cd ios && pod install && cd ..
flutter pub get
flutter run
```

2. Test all sign-in methods
3. Verify first-time users go to age collection
4. Verify returning users go directly to home

---

## 📞 Need Help?

### Firebase Issues
- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [FlutterFire Docs](https://firebase.flutter.dev)

### Google Sign In Issues
- [Google Sign In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [iOS Setup Guide](https://developers.google.com/identity/sign-in/ios/start)

### Apple Sign In Issues
- [Sign In with Apple Docs](https://developer.apple.com/sign-in-with-apple/)
- [Flutter Plugin](https://pub.dev/packages/sign_in_with_apple)

### Facebook Sign In Issues
- [Facebook Login Docs](https://developers.facebook.com/docs/facebook-login)
- [Flutter Plugin](https://pub.dev/packages/flutter_facebook_auth)

---

**Status**: 🟡 Configured (pending provider credentials)  
**Last Updated**: January 14, 2026  
**Next Step**: Configure Firebase, Apple, and Facebook credentials

