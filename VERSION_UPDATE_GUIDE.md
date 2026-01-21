# 📱 Version Update & Force Update Guide

## ⚠️ Important: Version vs Build Number

**The version check compares VERSION NUMBERS, not BUILD NUMBERS.**

- **Version Number**: `1.0.3` (in `pubspec.yaml` as `version: 1.0.3+13`)
- **Build Number**: `+13`, `+14`, etc. (the number after the `+`)

**When you increment the build number (+13 → +14), users won't be prompted to update because the version is still `1.0.3`.**

## ✅ How to Trigger Update Prompts

### **Option 1: Increment Version Number (Recommended)**

When releasing a new version:

1. **Update `pubspec.yaml`:**
   ```yaml
   version: 1.0.4+14  # Increment version (1.0.3 → 1.0.4) AND build number
   ```

2. **Update Firebase Remote Config:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Navigate to **Build** → **Remote Config**
   - Update `minimum_required_version` to `1.0.4`
   - Set `force_update_enabled` to `true` if you want to force updates
   - Click **"Publish changes"**

3. **Build and release:**
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

### **Option 2: Use Build Number for Updates (Advanced)**

If you want to use build numbers for updates, you need to:

1. **Modify the version check service** to compare build numbers
2. **Update Firebase Remote Config** with the minimum build number

However, **this is not recommended** because:
- Build numbers are platform-specific
- Version numbers are more standard
- App stores use version numbers, not build numbers

---

## 🔧 Firebase Remote Config Setup

### **Step 1: Access Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **MindRush**
3. Navigate to **Build** → **Remote Config**

### **Step 2: Add/Update Parameters**

| Parameter Key | Data Type | Value | Description |
|--------------|-----------|-------|-------------|
| `minimum_required_version` | String | `1.0.4` | Minimum app version required |
| `force_update_enabled` | Boolean | `true` | Force users to update (blocks app) |
| `update_title` | String | `Update Required` | Dialog title |
| `update_message` | String | `A new version is available...` | Dialog message |

### **Step 3: Publish Changes**

1. Click **"Publish changes"** button
2. Changes take effect within **1 hour** (or immediately if you reduce fetch interval)

---

## 🚀 Release Workflow

### **When Releasing a New Version:**

1. **Update `pubspec.yaml`:**
   ```yaml
   version: 1.0.4+14  # New version + new build
   ```

2. **Build the app:**
   ```bash
   # Android
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   ```

3. **Upload to stores:**
   - Upload to Google Play Console
   - Upload to App Store Connect

4. **After app is live in stores, update Firebase Remote Config:**
   - Set `minimum_required_version` to `1.0.4`
   - Set `force_update_enabled` to `true` (if you want to force updates)
   - Publish changes

5. **Users will be prompted to update:**
   - On next app launch
   - When app resumes from background
   - If force update is enabled, they cannot use the app until updated

---

## 📋 Version Check Flow

```
App Launches
    ↓
Check Current Version (from pubspec.yaml)
    ↓
Fetch Firebase Remote Config
    ↓
Compare: Current Version vs Minimum Required Version
    ↓
If Current < Minimum:
    ↓
Show Update Dialog
    ↓
If Force Update Enabled:
    - Block app usage
    - Dialog cannot be dismissed
    - Re-check every 2 seconds
Else:
    - User can dismiss
    - App continues
    - Check again on next launch
```

---

## 🎯 Example Scenarios

### **Scenario 1: User has 1.0.3, Store has 1.0.4**

1. Firebase Remote Config: `minimum_required_version = 1.0.4`
2. User opens app with version `1.0.3`
3. Version check: `1.0.3 < 1.0.4` → **Update required**
4. Dialog appears: "Update Required"
5. User taps "Update Now" → Opens Play Store/App Store
6. If force update: App is blocked until updated

### **Scenario 2: User has 1.0.4, Store has 1.0.4**

1. Firebase Remote Config: `minimum_required_version = 1.0.4`
2. User opens app with version `1.0.4`
3. Version check: `1.0.4 == 1.0.4` → **No update required**
4. App continues normally

### **Scenario 3: Build number changed but version didn't**

1. User has: `1.0.3+13`
2. You release: `1.0.3+14`
3. Firebase Remote Config: `minimum_required_version = 1.0.3`
4. Version check: `1.0.3 == 1.0.3` → **No update required** ❌
5. **Solution**: Increment version to `1.0.4+14`

---

## ⚙️ Configuration

### **Force Update Settings**

**To enable force updates:**
- Set `force_update_enabled` to `true` in Firebase Remote Config
- Users cannot dismiss the dialog
- App is completely blocked until updated

**To allow optional updates:**
- Set `force_update_enabled` to `false`
- Users can dismiss the dialog
- App continues to work
- Dialog shows again on next launch

### **Update Check Frequency**

The app checks for updates:
- ✅ On app launch (splash screen)
- ✅ When app resumes from background
- ✅ When navigating to main screen
- ✅ Every 2 seconds if force update is enabled

---

## 🔍 Troubleshooting

### **Issue: Users not being prompted to update**

**Possible causes:**
1. Version number not incremented (only build number changed)
2. Firebase Remote Config not updated
3. Remote Config changes not published
4. App version matches minimum required version

**Solutions:**
1. Check `pubspec.yaml` - did you increment the version number?
2. Check Firebase Console - is `minimum_required_version` set correctly?
3. Did you click "Publish changes" in Firebase?
4. Wait up to 1 hour for Remote Config to propagate

### **Issue: Update dialog not showing**

**Check:**
1. Is `minimum_required_version` higher than current app version?
2. Is Firebase Remote Config properly initialized?
3. Check console logs for version check errors
4. Try clearing app cache and restarting

### **Issue: Force update not blocking app**

**Check:**
1. Is `force_update_enabled` set to `true` in Firebase?
2. Did you publish the Remote Config changes?
3. Check that `PopScope` is working (iOS 14+)

---

## 📝 Quick Reference

**To trigger update prompt:**
1. Increment version in `pubspec.yaml`: `1.0.3` → `1.0.4`
2. Update Firebase Remote Config: `minimum_required_version = 1.0.4`
3. Publish Remote Config changes
4. Release app to stores

**Current version format:**
```yaml
version: 1.0.3+13
         ^^^^^ ^^
         Version Build Number
```

**Version comparison:**
- `1.0.3 < 1.0.4` ✅ Update required
- `1.0.3 == 1.0.3` ❌ No update
- `1.0.4 > 1.0.3` ❌ No update (user has newer version)

---

## 🎉 Summary

**Key Points:**
- ✅ Increment **version number** (not just build number) to trigger updates
- ✅ Update Firebase Remote Config when releasing
- ✅ Use force update for critical updates
- ✅ Version check happens automatically on app launch

**Remember:** Build numbers (+13, +14) are for tracking builds, but **version numbers (1.0.3, 1.0.4) are what trigger update prompts!**





