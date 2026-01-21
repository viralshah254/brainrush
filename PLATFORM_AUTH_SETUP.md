# 🔧 Platform-Specific Authentication Setup

## Quick Setup Guide for Apple, Google & Facebook Sign-In

---

## 🍎 Apple Sign In (iOS Only)

### **Step 1: Enable in Xcode**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select `Runner` target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" button
5. Add "Sign In with Apple"

### **Step 2: Apple Developer Console**
1. Go to https://developer.apple.com/account
2. Navigate to "Certificates, Identifiers & Profiles"
3. Select your app's identifier
4. Enable "Sign In with Apple" capability
5. Save changes

**Done!** Apple Sign In is now ready to use on iOS.

---

## 🔵 Google Sign In (iOS & Android)

### **For iOS:**

#### **Step 1: Get OAuth Client ID**
1. Go to Firebase Console
2. Authentication → Sign-in method
3. Enable Google
4. Note the iOS Client ID

#### **Step 2: Update Info.plist**
Add to `ios/Runner/Info.plist`:
```xml
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### **For Android:**

#### **Step 1: Get SHA-1 Fingerprint**
```bash
cd android
./gradlew signingReport
```

Copy both **debug** and **release** SHA-1 fingerprints.

#### **Step 2: Add to Firebase**
1. Firebase Console → Project Settings
2. Under "Your apps" → Select Android app
3. Click "Add fingerprint"
4. Add both debug and release SHA-1
5. Download new `google-services.json`
6. Replace `android/app/google-services.json`

#### **Step 3: Verify Configuration**
`android/app/google-services.json` should exist with your app's package name.

---

## 📘 Facebook Sign In (iOS & Android)

### **Step 1: Create Facebook App**
1. Go to https://developers.facebook.com/
2. Click "Create App"
3. Select "Consumer" → "Next"
4. Enter app name: "MindRush"
5. Note your **App ID** and **App Secret**

### **Step 2: Add Facebook Login**
1. In your Facebook App dashboard
2. Add Product → "Facebook Login"
3. Choose "iOS" and "Android" platforms

### **For iOS:**

#### **Update Info.plist**
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>fb[YOUR_APP_ID]</string>
    </array>
  </dict>
</array>

<key>FacebookAppID</key>
<string>[YOUR_APP_ID]</string>

<key>FacebookClientToken</key>
<string>[YOUR_CLIENT_TOKEN]</string>

<key>FacebookDisplayName</key>
<string>MindRush</string>

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>fbapi</string>
  <string>fb-messenger-share-api</string>
</array>
```

#### **Add to Facebook Dashboard**
1. Facebook App → Settings → Basic
2. Add Bundle ID: `com.dvtechventures.mindrush`

### **For Android:**

#### **Step 1: Get Key Hash**
```bash
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
```
(Password: `android`)

#### **Step 2: Update AndroidManifest.xml**
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <!-- ... existing code ... -->
    
    <meta-data 
        android:name="com.facebook.sdk.ApplicationId" 
        android:value="@string/facebook_app_id"/>
    
    <meta-data
        android:name="com.facebook.sdk.ClientToken"
        android:value="@string/facebook_client_token"/>
    
    <activity 
        android:name="com.facebook.FacebookActivity"
        android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
        android:label="@string/app_name" />
    
    <activity
        android:name="com.facebook.CustomTabActivity"
        android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="@string/fb_login_protocol_scheme" />
        </intent-filter>
    </activity>
</application>
```

#### **Step 3: Create strings.xml**
Create or update `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">MindRush</string>
    <string name="facebook_app_id">[YOUR_APP_ID]</string>
    <string name="facebook_client_token">[YOUR_CLIENT_TOKEN]</string>
    <string name="fb_login_protocol_scheme">fb[YOUR_APP_ID]</string>
</resources>
```

#### **Step 4: Add to Facebook Dashboard**
1. Facebook App → Settings → Basic
2. Add Package Name: `com.dvtechventures.mindrush`
3. Add Key Hash (from Step 1)

---

## 🔥 Firebase Console Setup

### **Enable Authentication Providers**
1. Go to Firebase Console
2. Select your project: `mind-rush-15036`
3. Navigate to "Authentication" → "Sign-in method"
4. Enable the following:
   - ✅ Email/Password
   - ✅ Google
   - ✅ Facebook (add App ID and App Secret)
   - ✅ Apple (iOS only)

---

## 📝 Quick Checklist

### **iOS Setup:**
- [ ] Enable "Sign In with Apple" in Xcode capabilities
- [ ] Add Apple Sign In to Apple Developer Console
- [ ] Add Google Client ID to Info.plist
- [ ] Add Facebook App ID to Info.plist
- [ ] Test on physical device (simulator has limitations)

### **Android Setup:**
- [ ] Add SHA-1 fingerprints to Firebase
- [ ] Download and place google-services.json
- [ ] Add Facebook meta-data to AndroidManifest.xml
- [ ] Create strings.xml with Facebook credentials
- [ ] Add Facebook Key Hash to Facebook Dashboard
- [ ] Test on physical device or emulator

### **Firebase Setup:**
- [ ] Enable Email/Password authentication
- [ ] Enable Google authentication
- [ ] Enable Facebook authentication (with credentials)
- [ ] Enable Apple authentication

---

## 🧪 Testing

### **On iOS:**
```bash
flutter run
```

### **On Android:**
```bash
flutter run
```

### **Test Each Provider:**
1. **Apple Sign In**: iOS only, needs physical device
2. **Google Sign In**: Both platforms, works on simulators
3. **Facebook Sign In**: Both platforms, works on simulators
4. **Email/Password**: Both platforms, works everywhere

---

## 🔐 Environment Variables (Optional)

For better security, you can store credentials in environment variables:

**Create `.env` file:**
```
FACEBOOK_APP_ID=your_app_id
FACEBOOK_CLIENT_TOKEN=your_client_token
GOOGLE_CLIENT_ID=your_client_id
```

**Add to .gitignore:**
```
.env
```

**Note**: The current implementation uses direct configuration for simplicity.

---

## 🚨 Common Issues & Solutions

### **Issue: Apple Sign In not working on simulator**
**Solution**: Apple Sign In requires a physical device. Test on real iOS device.

### **Issue: Google Sign In fails with "DEVELOPER_ERROR"**
**Solution**: 
1. Check SHA-1 is added to Firebase
2. Verify package name matches
3. Re-download google-services.json

### **Issue: Facebook Sign In fails**
**Solution**:
1. Verify App ID in strings.xml
2. Check Key Hash is correct
3. Ensure app is in "Live" mode on Facebook Dashboard

### **Issue: "PlatformException" on sign-in**
**Solution**: 
1. Run `flutter clean`
2. Run `flutter pub get`
3. For iOS: `cd ios && pod install`
4. Rebuild app

---

## 📱 Production Setup

### **Before Release:**

#### **iOS:**
1. Get production certificate
2. Enable "Sign In with Apple" for production
3. Update OAuth redirect URIs in Firebase

#### **Android:**
1. Generate release keystore
2. Get release SHA-1 fingerprint
3. Add to Firebase Console
4. Update google-services.json

#### **Facebook:**
1. Switch app to "Live" mode
2. Complete App Review if required
3. Add production OAuth redirects

---

## 📞 Support

### **Documentation Links:**
- Firebase Auth: https://firebase.google.com/docs/auth
- Google Sign In: https://pub.dev/packages/google_sign_in
- Apple Sign In: https://pub.dev/packages/sign_in_with_apple
- Facebook Auth: https://pub.dev/packages/flutter_facebook_auth

### **Firebase Console:**
- Project: mind-rush-15036
- Console: https://console.firebase.google.com/

---

**Status:** Configuration Required  
**Priority:** High (Needed for production)  
**Est. Time:** 30-45 minutes per platform  
**Next Step:** Follow checklist above! 🚀






