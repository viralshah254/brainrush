# 🔄 Rebuild Required for Assets

## Issue
Flutter cannot find `assets/questions/education_questions.json` even though it exists.

## Solution
Flutter requires a **full rebuild** to recognize new or modified assets. Hot reload/hot restart does NOT include asset changes.

## Steps to Fix

1. **Stop the app** (if running)

2. **Clean the build:**
   ```bash
   flutter clean
   ```

3. **Get dependencies:**
   ```bash
   flutter pub get
   ```

4. **Rebuild and run:**
   ```bash
   flutter run
   ```

   Or if using an IDE:
   - **VS Code**: Stop the app, then press `F5` or click "Run"
   - **Android Studio**: Stop the app, then click the green "Run" button

## Why This Happens
- Assets are bundled at **build time**, not runtime
- Hot reload only updates Dart code, not assets
- The 29MB JSON file needs to be included in the app bundle during build

## Verification
After rebuilding, you should see in the console:
```
📚 Pre-loading education questions...
📚 Loading education questions from assets/questions/education_questions.json...
📚 JSON string loaded (X characters) in Xms
✅ Loaded X education questions from JSON
```

If you still see "Unable to load asset", check:
1. File exists: `ls -lh assets/questions/education_questions.json`
2. Path in `pubspec.yaml` matches exactly: `assets/questions/education_questions.json`
3. No typos in the path
4. File is not corrupted (should start with `[` and end with `]`)










