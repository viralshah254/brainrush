# 🔧 Fix Xcode Build Error - CocoaPods Issues

## ❌ Error
```
Unable to load contents of file list: '/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-input-files.xcfilelist'
```

This error occurs when CocoaPods files are missing or corrupted.

## ✅ Solution

### **Step 1: Clean Everything**

In your terminal, run:

```bash
cd /Users/v/Desktop/Apps/mind_rush/mind_rush

# Clean Flutter
flutter clean

# Remove iOS build artifacts
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### **Step 2: Reinstall CocoaPods**

```bash
# Make sure you're in the ios directory
cd /Users/v/Desktop/Apps/mind_rush/mind_rush/ios

# Install pods
pod deintegrate
pod install --repo-update
```

### **Step 3: Get Flutter Dependencies**

```bash
# Go back to project root
cd ..

# Get Flutter packages
flutter pub get
```

### **Step 4: Clean Xcode**

1. **Close Xcode completely** (Cmd + Q)
2. **Open Xcode**
3. **Product → Clean Build Folder** (Shift + Cmd + K)
4. **Close Xcode again**
5. **Reopen Xcode**

### **Step 5: Rebuild**

1. In Xcode, select **Product → Build** (Cmd + B)
2. If errors persist, try building from terminal:
   ```bash
   flutter build ios --no-codesign
   ```

## 🔍 Alternative: If Pod Install Fails

If `pod install` fails, try:

```bash
cd ios
pod cache clean --all
pod deintegrate
pod install
```

## 📝 Note

The errors you're seeing are because the CocoaPods-generated files are missing. The `pod install` command will regenerate all the necessary `Pods-Runner-*.xcfilelist` files.

---

**After running these steps, your Xcode build should work!**



