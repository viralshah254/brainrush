# 🔧 Plugin Error Fix Guide

## ❌ **Error: MissingPluginException**

```
MissingPluginException(No implementation found for method _init 
on channel plugins.flutter.io/google_mobile_ads)
```

This error occurs when adding new native plugins (like Google Mobile Ads) because the native code hasn't been linked yet.

---

## ✅ **Solution**

### **Quick Fix**
1. Stop the running app
2. Run:
```bash
flutter clean
flutter pub get
flutter run
```

The app will rebuild with native plugins properly linked.

---

### **If Still Not Working (iOS)**

1. **Set UTF-8 encoding** (add to `~/.zshrc` or `~/.bash_profile`):
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

2. **Reload terminal**:
```bash
source ~/.zshrc
```

3. **Install pods**:
```bash
cd ios
pod install
cd ..
flutter run
```

---

### **If Still Not Working (Android)**

1. **Invalidate caches** in Android Studio:
   - File → Invalidate Caches → Invalidate and Restart

2. **Clean Gradle**:
```bash
cd android
./gradlew clean
cd ..
flutter run
```

---

## 🎯 **Why This Happens**

When you add a new plugin with native code (Java/Kotlin for Android, Swift/Objective-C for iOS), Flutter needs to:

1. Download the plugin
2. Link it to the native project
3. Compile the native code
4. Register the plugin channels

**Hot restart doesn't do this** - you need a **full rebuild**.

---

## 📱 **Testing Ads**

### **Use Test Ad IDs First**

Before using your real ad IDs, test with these:

**Android Test IDs:**
```dart
// Rewarded Ad
'ca-app-pub-3940256099942544/5224354917'

// Rewarded Interstitial Ad  
'ca-app-pub-3940256099942544/5354046379'
```

**iOS Test IDs:**
```dart
// Rewarded Ad
'ca-app-pub-3940256099942544/1712485313'

// Rewarded Interstitial Ad
'ca-app-pub-3940256099942544/6978759866'
```

### **Update AdService to use Test IDs**

```dart
// lib/services/ad_service.dart
static const String _rewardedAdUnitId = kDebugMode
    ? Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917' // Test
        : 'ca-app-pub-3940256099942544/1712485313' // Test
    : 'ca-app-pub-4248679794653671/5995363366'; // Real
```

---

## ✅ **Verification Steps**

After rebuilding, verify:

1. ✅ App launches without errors
2. ✅ AdService initializes (check console logs)
3. ✅ Ads load (use test IDs)
4. ✅ Ad shows when triggered
5. ✅ Premium status works

---

## 🚀 **Quick Commands**

```bash
# Stop app, clean, and rebuild
flutter clean && flutter pub get && flutter run

# Or with specific device
flutter clean && flutter pub get && flutter run -d YOUR_DEVICE_ID
```

---

## 💡 **Pro Tips**

1. **Always do full rebuild** after adding native plugins
2. **Use test ad IDs** during development
3. **Check console logs** for initialization messages
4. **Test on real devices** before launch
5. **Verify ads work** before submitting to stores

---

## 📞 **Still Having Issues?**

Check:
- [ ] Internet connection (ads need network)
- [ ] Device has Google Play Services (Android)
- [ ] Ad IDs are correct
- [ ] App ID in AndroidManifest.xml is correct
- [ ] Permissions are in manifest (INTERNET)
- [ ] No firewall/VPN blocking ads

---

**Status:** This is a common, expected error when adding plugins.  
**Fix:** Simple rebuild solves it 99% of the time! ✅

---

Last Updated: Jan 10, 2026

