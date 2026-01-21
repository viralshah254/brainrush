# 🔧 Ad Unit Format Error Fix Guide

## ❌ The Problem

You're seeing this error:
```
❌ Round Complete ad failed to load: 1 - Ad unit doesn't match format.
```

**Root Cause:** You're using a **Rewarded Ad** unit ID for a **Rewarded Interstitial Ad**.

## 🔍 What's Happening

1. **Ad Pre-loading**: Ads are pre-loaded when the app starts (in `main.dart`), which is **normal and expected**. This happens in the background.

2. **Wrong Ad Unit Type**: For iOS, the code is trying to load a `RewardedInterstitialAd` using a `RewardedAd` unit ID (`9905514752`).

3. **Why It Appears on Home Screen**: The error appears in the console when the app starts because ads are pre-loaded on initialization. The ad isn't actually showing on the home screen - it's just failing to load in the background.

## ✅ The Solution

### **Step 1: Create a Rewarded Interstitial Ad Unit in AdMob**

1. Go to [Google AdMob Console](https://apps.admob.com/)
2. Select your app: **MindRush**
3. Navigate to **Apps** → **Ad units**
4. Click **"Add ad unit"**
5. Select **"Rewarded Interstitial"** (NOT "Rewarded")
6. Name it: "Round Complete - iOS" (or similar)
7. Copy the new ad unit ID (format: `ca-app-pub-XXXXXXXXXX/YYYYYYYYYY`)

### **Step 2: Update the Code**

Edit `lib/services/ad_service.dart` and replace the iOS Rewarded Interstitial ad unit ID:

```dart
static String get _rewardedInterstitialAdUnitId {
  if (_useTestAds) {
    // ... test ads ...
  } else {
    if (Platform.isIOS) {
      return 'ca-app-pub-4248679794653671/YOUR_NEW_IOS_REWARDED_INTERSTITIAL_ID'; // ⬅️ Replace this
    } else {
      return 'ca-app-pub-4248679794653671/8749519214'; // Android (correct)
    }
  }
}
```

### **Step 3: Verify Ad Unit Types**

Make sure you have the correct ad unit types:

| Ad Type | iOS Ad Unit ID | Android Ad Unit ID |
|---------|---------------|-------------------|
| **Rewarded Ad** (Try Again) | `9905514752` ✅ | `5995363366` ✅ |
| **Rewarded Interstitial** (Round Complete) | `NEW_ID_NEEDED` ⚠️ | `8749519214` ✅ |

## 📋 Current Ad Unit IDs

### **iOS:**
- ✅ Rewarded Ad (Try Again): `ca-app-pub-4248679794653671/9905514752`
- ❌ Rewarded Interstitial (Round Complete): `ca-app-pub-4248679794653671/9905514752` ← **WRONG!**

### **Android:**
- ✅ Rewarded Ad (Try Again): `ca-app-pub-4248679794653671/5995363366`
- ✅ Rewarded Interstitial (Round Complete): `ca-app-pub-4248679794653671/8749519214`

## 🎯 Quick Fix (Temporary)

If you don't want to create a new ad unit right now, you can temporarily disable the Round Complete ad for iOS:

```dart
// Load Round Complete Rewarded Interstitial Ad
Future<bool> loadRoundCompleteAd() async {
  if (_isPremium || _isRoundCompleteAdLoading) return false;
  
  // Temporarily disable for iOS until correct ad unit is created
  if (Platform.isIOS) {
    print('⚠️ Round Complete ad disabled for iOS - create Rewarded Interstitial ad unit');
    return false;
  }
  
  // ... rest of the code ...
}
```

## 🔍 Why Ads Load on App Start

**This is intentional and correct behavior:**

1. **Pre-loading**: Ads are loaded in the background when the app starts
2. **Better UX**: When user needs to see an ad, it's already loaded (instant)
3. **No User Impact**: The loading happens silently in the background
4. **Error Handling**: Errors are logged but don't affect app functionality

**The error you see is just a log message** - the app continues to work normally.

## ✅ After Fixing

Once you update the ad unit ID:

1. **Rebuild the app**
2. **Test on a real device** (ads don't work on simulator)
3. **Check console** - error should be gone
4. **Verify ad shows** when completing a round

## 📝 Summary

- ❌ **Problem**: Using Rewarded Ad ID for Rewarded Interstitial Ad
- ✅ **Solution**: Create a Rewarded Interstitial ad unit in AdMob and update the code
- ℹ️ **Note**: Ads pre-loading on startup is normal and expected

---

**Need Help?**
- [AdMob Console](https://apps.admob.com/)
- [Ad Unit Types Guide](https://support.google.com/admob/answer/6329638)




