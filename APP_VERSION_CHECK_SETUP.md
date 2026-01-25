# 📱 App Version Check Setup Guide

## ✅ What's Been Implemented

The app now automatically checks for updates when it starts and prompts users to update if a new version is available.

### **Features:**
- ✅ Automatic version checking on app startup
- ✅ Firebase Remote Config integration for version management
- ✅ Force update support (blocks app usage until updated)
- ✅ Optional update prompts (user can dismiss)
- ✅ Platform-specific store URLs (App Store / Play Store)
- ✅ Beautiful update dialog UI

---

## 🔧 Setup Instructions

### **1. Update Store URLs**

Edit `lib/services/version_check_service.dart` and update the store URLs:

**For iOS (App Store):**
```dart
if (Platform.isIOS) {
  // Replace YOUR_APP_ID with your actual App Store ID
  return 'https://apps.apple.com/app/idYOUR_APP_ID';
}
```

**For Android (Play Store):**
```dart
else if (Platform.isAndroid) {
  // Already configured with your package name
  return 'https://play.google.com/store/apps/details?id=com.dvtechventures.mindrush';
}
```

### **2. Set Up Firebase Remote Config**

#### **Step 1: Enable Remote Config in Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Build** → **Remote Config**
4. Click **"Get started"** if not already enabled

#### **Step 2: Add Version Parameters**

Add these parameters in Firebase Remote Config:

| Parameter Key | Data Type | Default Value | Description |
|--------------|-----------|---------------|-------------|
| `minimum_required_version` | String | `1.0.0` | Minimum app version required (e.g., `1.0.3`) |
| `force_update_enabled` | Boolean | `false` | Set to `true` to force users to update |
| `update_title` | String | `Update Required` | Title shown in update dialog |
| `update_message` | String | `A new version of MindRush is available...` | Message shown in update dialog |

#### **Step 3: Publish Remote Config**

1. After adding parameters, click **"Publish changes"**
2. The app will fetch these values on startup

---

## 🎯 How It Works

### **Version Comparison**

The service compares version strings (e.g., `1.0.3`) using semantic versioning:
- `1.0.2` < `1.0.3` → Update required
- `1.0.3` = `1.0.3` → No update needed
- `1.0.4` > `1.0.3` → No update needed

### **Update Flow**

1. **App Starts** → Version check service initializes
2. **Fetches Remote Config** → Gets minimum required version
3. **Compares Versions** → Current vs. Required
4. **Shows Dialog** → If update needed
5. **User Action**:
   - **Force Update**: User must tap "Update Now" (can't dismiss)
   - **Optional Update**: User can tap "Later" or "Update Now"

### **Force Update Mode**

When `force_update_enabled` is `true`:
- Dialog cannot be dismissed
- App navigation is blocked
- User must update to continue

---

## 📝 Example Remote Config Values

### **Scenario 1: Optional Update (Version 1.0.4 available)**

```json
{
  "minimum_required_version": "1.0.3",
  "force_update_enabled": false,
  "update_title": "Update Available",
  "update_message": "A new version of MindRush is available with bug fixes and improvements. Update now to get the latest features!"
}
```

### **Scenario 2: Force Update (Critical security fix)**

```json
{
  "minimum_required_version": "1.0.4",
  "force_update_enabled": true,
  "update_title": "Update Required",
  "update_message": "A critical update is required for security reasons. Please update now to continue using MindRush."
}
```

---

## 🧪 Testing

### **Test Optional Update**

1. Set `minimum_required_version` to a version higher than current (e.g., `1.0.4`)
2. Set `force_update_enabled` to `false`
3. Run the app
4. Update dialog should appear
5. Tap "Later" → App should continue normally

### **Test Force Update**

1. Set `minimum_required_version` to a version higher than current
2. Set `force_update_enabled` to `true`
3. Run the app
4. Update dialog should appear
5. Try to dismiss → Should not be dismissible
6. Must tap "Update Now" → Opens store

### **Test No Update Needed**

1. Set `minimum_required_version` to current version or lower
2. Run the app
3. No dialog should appear
4. App should start normally

---

## 🔍 Debugging

### **Check Current Version**

The app logs the current version on startup:
```
📱 Current app version: 1.0.3 (3)
```

### **Check Remote Config**

The app logs remote config fetch status:
```
✅ Remote config fetched successfully
```

Or if it fails:
```
⚠️ Remote config fetch failed (using defaults): [error]
```

### **Version Comparison Logs**

```
🔍 Version check: Current=[1, 0, 3], Required=[1, 0, 4]
```

---

## 📦 Dependencies Added

- `package_info_plus: ^8.0.0` - Get current app version
- `firebase_remote_config: ^5.1.3` - Fetch version requirements from Firebase

---

## 🚀 Next Steps

1. ✅ Update store URLs with your App Store ID
2. ✅ Set up Firebase Remote Config
3. ✅ Add version parameters
4. ✅ Test with different version scenarios
5. ✅ Publish your app!

---

## 💡 Tips

- **Gradual Rollout**: Start with `force_update_enabled: false` for optional updates
- **Version Format**: Use semantic versioning (e.g., `1.0.3`, not `1.0`)
- **Testing**: Use Firebase Remote Config's "Test" feature to test without affecting all users
- **Monitoring**: Check Firebase Remote Config usage in Firebase Console

---

## ❓ Troubleshooting

### **Update dialog not showing**

- Check that `minimum_required_version` is higher than current version
- Verify remote config is fetching (check logs)
- Ensure Firebase Remote Config is enabled

### **Store URL not opening**

- Verify store URLs are correct
- Check device has internet connection
- Ensure store app is installed (for deep links)

### **Force update not working**

- Verify `force_update_enabled` is set to `true` in Remote Config
- Check that remote config was fetched successfully
- Ensure dialog is using `isForceUpdate: true`

---

**🎉 Your app now has automatic version checking!**










