# 📱 App Store Declarations Guide for MindRush

This document outlines all required declarations for **Google Play Console** and **App Store Connect** to ensure your app is approved.

---

## 🔴 CRITICAL: Privacy Policy URL

**Both stores require a publicly accessible Privacy Policy URL.**

Your privacy policy URL: `https://www.dvtechventures.com/TandCs`

**⚠️ Make sure this URL:**
- Is publicly accessible (no login required)
- Clearly explains what data you collect
- Explains how data is used
- Explains third-party services (Firebase, Google, Facebook, Apple)
- Explains data retention and deletion policies
- Includes contact information for privacy inquiries

---

## 📱 GOOGLE PLAY CONSOLE DECLARATIONS

### 1. **Data Safety Section** (REQUIRED)

Navigate to: **Play Console → Your App → Policy → App content → Data safety**

#### **Data Collection & Sharing:**

**✅ YES - You collect the following data:**

1. **Personal Info**
   - ✅ Email address (for authentication)
   - ✅ Name/Username (user profile)
   - ✅ Age (for COPPA compliance and education mode)

2. **App Activity**
   - ✅ App interactions (game plays, scores, progress)
   - ✅ In-app search history (if any)
   - ✅ Other user-generated content (game stats, streaks)

3. **Device or Other IDs**
   - ✅ Device ID (Firebase Analytics)
   - ✅ Advertising ID (Google Mobile Ads)

4. **Location** (if applicable)
   - ❌ No location data collected

5. **Financial Info**
   - ✅ Purchase history (in-app purchases)

6. **Photos and Videos**
   - ❌ No photos/videos collected

7. **Audio Files**
   - ❌ No audio files collected

8. **Files and Docs**
   - ❌ No files/docs collected

9. **Contacts**
   - ✅ **YES - Contacts list** (for finding friends feature)
   - Purpose: Find friends who also use the app
   - Data type: Contact names and phone numbers (hashed)
   - Shared with third parties: No

#### **Data Usage:**

- **App functionality** (authentication, game progress, finding friends)
- **Analytics** (Firebase Analytics)
- **Advertising** (Google Mobile Ads)
- **Personalization** (education mode settings)

#### **Data Sharing:**

- ✅ **YES** - Data is shared with third parties:
  - **Google** (Firebase, Google Sign-In, Google Mobile Ads)
  - **Facebook** (Facebook Login)
  - **Apple** (Apple Sign-In - iOS only)

#### **Data Security:**

- ✅ Data is encrypted in transit
- ✅ Users can request data deletion
- ✅ Users can request data export

#### **Data Deletion:**

- ✅ Users can request account deletion
- ✅ Provide instructions in your privacy policy

---

### 2. **Target Audience & Content Rating**

Navigate to: **Play Console → Your App → Policy → App content → Target audience and content**

#### **Target Audience:**
- ✅ **Everyone** (or specify age range, e.g., 10+)
- ⚠️ **If collecting age data for users under 13, you MUST comply with COPPA**

#### **Content Rating:**
- Select appropriate rating (likely **Everyone** or **Everyone 10+**)
- Complete the content rating questionnaire

---

### 3. **Permissions Declaration**

Navigate to: **Play Console → Your App → Policy → App content → Sensitive permissions and APIs**

#### **Declare the following permissions:**

1. **READ_CONTACTS** / **WRITE_CONTACTS**
   - Purpose: Find friends who also use the app
   - Justification: Core feature for social gameplay
   - ⚠️ **REQUIRES PERMISSION DECLARATION FORM**

2. **POST_NOTIFICATIONS**
   - Purpose: Send push notifications for daily challenges and reminders
   - Justification: User engagement and retention

3. **INTERNET** / **ACCESS_NETWORK_STATE**
   - Purpose: App functionality, authentication, ads
   - Justification: Core app functionality

4. **WAKE_LOCK**
   - Purpose: Keep screen on during gameplay
   - Justification: Prevent screen timeout during quizzes

5. **RECEIVE_BOOT_COMPLETED**
   - Purpose: Schedule notifications after device restart
   - Justification: Notification scheduling

6. **VIBRATE**
   - Purpose: Haptic feedback during gameplay
   - Justification: User experience enhancement

---

### 4. **Monetization Declaration**

Navigate to: **Play Console → Your App → Monetize → Monetization setup**

#### **In-App Products:**
- ✅ **YES** - App contains in-app purchases
- Declare all product types:
  - Consumable (coins)
  - Non-consumable subscriptions (SAT Prep, GMAT Prep, All Access)

#### **Ads:**
- ✅ **YES** - App contains ads
- Ad network: **Google Mobile Ads**
- Ad types: Rewarded Interstitial Ads

---

### 5. **COPPA Compliance** (If targeting users under 13)

Navigate to: **Play Console → Your App → Policy → App content → Families**

#### **If your app is designed for families:**
- ✅ **YES** - App collects age data
- ✅ **YES** - App may be used by children under 13
- ⚠️ You MUST:
  - Implement parental consent mechanism
  - Limit data collection for children
  - Comply with COPPA requirements
  - Complete the "Designed for Families" questionnaire

---

### 6. **Third-Party Services Declaration**

#### **Firebase Services:**
- Firebase Authentication
- Firebase Cloud Messaging (Push Notifications)
- Firebase Remote Config
- Firebase Analytics

#### **Social Login Providers:**
- Google Sign-In
- Facebook Login
- Apple Sign-In (iOS only)

#### **Ad Networks:**
- Google Mobile Ads (AdMob)

**⚠️ Declare all third-party SDKs in the Data Safety section**

---

## 🍎 APP STORE CONNECT DECLARATIONS

### 1. **App Privacy** (REQUIRED)

Navigate to: **App Store Connect → Your App → App Privacy**

#### **Data Collection:**

**✅ YES - You collect the following data types:**

1. **Contact Info**
   - ✅ Email Address
   - ✅ Name
   - ✅ Age
   - Purpose: Account creation, authentication, age verification
   - Linked to User: Yes
   - Used for Tracking: No
   - Used for Third-Party Advertising: No

2. **User Content**
   - ✅ Game Progress (scores, streaks, coins)
   - ✅ Education Settings (grade level, exam focus)
   - Purpose: App functionality, personalization
   - Linked to User: Yes
   - Used for Tracking: No
   - Used for Third-Party Advertising: No

3. **Identifiers**
   - ✅ Device ID
   - ✅ Advertising ID
   - Purpose: Analytics, advertising
   - Linked to User: Yes
   - Used for Tracking: Yes (for ads)
   - Used for Third-Party Advertising: Yes

4. **Usage Data**
   - ✅ Product Interaction (game plays, feature usage)
   - Purpose: Analytics, app improvement
   - Linked to User: Yes
   - Used for Tracking: No
   - Used for Third-Party Advertising: No

5. **Diagnostics**
   - ✅ Crash Data (if using Firebase Crashlytics)
   - ✅ Performance Data
   - Purpose: App stability and performance
   - Linked to User: No (anonymous)
   - Used for Tracking: No
   - Used for Third-Party Advertising: No

6. **Contacts**
   - ✅ **YES - Contacts** (for finding friends)
   - Purpose: Find friends who also use the app
   - Linked to User: Yes
   - Used for Tracking: No
   - Used for Third-Party Advertising: No

#### **Data Linked to User:**
- ✅ Most data is linked to user identity
- ✅ Some analytics data may be anonymized

#### **Data Used to Track You:**
- ✅ **YES** - Advertising ID is used for tracking
- Purpose: Personalized advertising
- Third-party advertising: Yes (Google Mobile Ads)

#### **Data Linked to User:**
- ✅ Email, Name, Age, Game Progress, Education Settings

#### **Data Not Linked to User:**
- ✅ Crash logs (if anonymized)
- ✅ Aggregated analytics

---

### 2. **App Information**

Navigate to: **App Store Connect → Your App → App Information**

#### **Age Rating:**
- Complete the age rating questionnaire
- Likely rating: **4+** or **9+** (depending on content)
- ⚠️ If collecting age data, ensure COPPA compliance

#### **Category:**
- Primary: **Education** or **Games**
- Secondary: **Education** or **Entertainment**

---

### 3. **App Privacy Details** (Privacy Nutrition Label)

Navigate to: **App Store Connect → Your App → App Privacy**

#### **Required Disclosures:**

1. **Data Collection:**
   - ✅ Contact Info (Email, Name, Age)
   - ✅ Contacts
   - ✅ User Content (Game Progress)
   - ✅ Identifiers (Device ID, Advertising ID)
   - ✅ Usage Data
   - ✅ Diagnostics

2. **Data Usage:**
   - App Functionality
   - Analytics
   - Advertising
   - Personalization

3. **Data Sharing:**
   - ✅ **YES** - Data is shared with third parties:
     - Google (Firebase, Google Sign-In, Google Mobile Ads)
     - Facebook (Facebook Login)
     - Apple (Apple Sign-In)

---

### 4. **In-App Purchases Declaration**

Navigate to: **App Store Connect → Your App → Features → In-App Purchases**

#### **Declare all IAP products:**
- Consumable products (coins)
- Auto-renewable subscriptions (SAT Prep, GMAT Prep, All Access)

#### **Subscription Groups:**
- Organize subscriptions into groups
- Set up subscription pricing and terms

---

### 5. **Advertising Identifier (IDFA) Usage**

Navigate to: **App Store Connect → Your App → App Privacy → Tracking**

#### **IDFA Usage:**
- ✅ **YES** - App uses IDFA for advertising
- ⚠️ **REQUIRES USER PERMISSION** (iOS 14.5+)
- You must implement the App Tracking Transparency framework
- Show permission dialog before accessing IDFA

**Code to add:**
```dart
// Add to Info.plist:
<key>NSUserTrackingUsageDescription</key>
<string>We use your advertising identifier to show you personalized ads and improve your experience.</string>
```

---

### 6. **Contacts Permission Declaration**

Navigate to: **App Store Connect → Your App → App Privacy**

#### **Contacts Access:**
- ✅ **YES** - App accesses contacts
- Purpose: Find friends who also use the app
- ⚠️ **REQUIRES USAGE DESCRIPTION** (already in Info.plist)
- Must explain why contacts are needed

---

## ⚠️ CRITICAL CHECKLIST BEFORE SUBMISSION

### **Google Play Console:**
- [ ] Privacy Policy URL is accessible and complete
- [ ] Data Safety section is fully completed
- [ ] All permissions are declared with justifications
- [ ] In-app purchases are declared
- [ ] Ads are declared
- [ ] COPPA compliance (if applicable)
- [ ] Target audience is set correctly
- [ ] Content rating is completed

### **App Store Connect:**
- [ ] Privacy Policy URL is accessible and complete
- [ ] App Privacy section is fully completed
- [ ] All data types are declared
- [ ] Tracking disclosure is accurate
- [ ] Contacts permission is explained
- [ ] IDFA usage is declared (if applicable)
- [ ] In-app purchases are set up
- [ ] Age rating is completed
- [ ] App Tracking Transparency is implemented (if using IDFA)

---

## 📋 PRIVACY POLICY REQUIREMENTS

Your privacy policy (`https://www.dvtechventures.com/TandCs`) must include:

1. **What data you collect:**
   - Email, name, age
   - Contacts (for finding friends)
   - Game progress and statistics
   - Device identifiers

2. **How data is used:**
   - Authentication
   - App functionality
   - Analytics
   - Advertising
   - Finding friends

3. **Third-party services:**
   - Google (Firebase, Google Sign-In, Google Mobile Ads)
   - Facebook (Facebook Login)
   - Apple (Apple Sign-In)

4. **Data sharing:**
   - Which data is shared with third parties
   - Purpose of sharing

5. **User rights:**
   - How to access data
   - How to delete data
   - How to opt-out of tracking

6. **COPPA compliance:**
   - If collecting data from children under 13
   - Parental consent process

7. **Contact information:**
   - Email or contact form for privacy inquiries

---

## 🚨 COMMON REJECTION REASONS

1. **Missing Privacy Policy URL** - Most common rejection
2. **Incomplete Data Safety/App Privacy** - Must declare all data collection
3. **Undisclosed permissions** - All permissions must be declared
4. **Missing COPPA compliance** - If targeting children
5. **Incorrect age rating** - Must match app content
6. **Missing tracking disclosure** - Must explain IDFA/Advertising ID usage
7. **Incomplete IAP setup** - All products must be properly configured

---

## 📞 SUPPORT

If you need help with:
- **Google Play Console:** [Google Play Help](https://support.google.com/googleplay/android-developer)
- **App Store Connect:** [Apple Developer Support](https://developer.apple.com/support/)

---

**Last Updated:** January 2026
**App Version:** 1.0.3+5








