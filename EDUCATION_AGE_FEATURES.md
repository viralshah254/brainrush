# 🎓 Education Mode - Age-Appropriate Features

## ✅ **Age-Based UI Adaptations**

### **High School Age (10-18 years)**
Shows ALL features:
- ✅ School System selector
- ✅ Grade Level (Grade 5-12 / Year 5-12)
- ✅ Challenge Level
- ✅ Subject Practice (Math, Science, English, etc.)
- ✅ SAT Prep (if 15+)
- ✅ GMAT Prep (if 18+)
- ✅ Grade League
- ✅ Study With Friends

### **Post-High School Age (19-30 years)**
**Simplified UI - Focus on College/MBA prep:**
- ❌ School System **hidden**
- ❌ Grade Level **hidden**
- ❌ Challenge Level **hidden**
- ❌ Subject Practice **hidden**
- ✅ SAT Prep (age requirement met)
- ✅ GMAT Prep (age requirement met)
- ❌ Grade League **hidden**
- ✅ Study With Friends **shown**
- ℹ️ Info message: *"Focus on SAT/GMAT prep for college/MBA admission"*

---

## 👥 **Study With Friends - Education Edition**

### **What It Does:**
A fun, intuitive way for friends to test each other on educational subjects they're studying together!

### **User Flow:**

```
1. User taps "Study With Friends" card
   ↓
2. Dialog appears: "Choose what to practice together"
   ↓
3. Options shown based on user's profile:
   
   HIGH SCHOOL AGE (10-18):
   - 📚 School Subjects (Math, Science, English, etc.)
   - 🎓 SAT Practice (if unlocked)
   - 💼 GMAT Practice (if unlocked)
   
   COLLEGE AGE (19+):
   - 🎓 SAT Practice (if unlocked)
   - 💼 GMAT Practice (if unlocked)
   ↓
4. User selects study mode
   ↓
5. Choose specific subject:
   - All Subjects (random mix)
   - Math
   - Science (school only)
   - English (school only)
   - Reading & Writing (SAT)
   - Quantitative (GMAT)
   - Verbal (GMAT)
   - etc.
   ↓
6. Navigate to Play With Friends screen
   ↓
7. Create/Join room with subject pre-selected
   ↓
8. Friends join and test each other!
```

---

## 📊 **Age-Based Feature Matrix**

| Feature | Age 10-14 | Age 15-18 | Age 19-30 |
|---------|-----------|-----------|-----------|
| **School System** | ✅ Show | ✅ Show | ❌ Hide |
| **Grade Level** | ✅ Show | ✅ Show | ❌ Hide |
| **Subject Practice** | ✅ Show | ✅ Show | ❌ Hide |
| **SAT Prep** | ❌ Age restricted | ✅ Available | ✅ Available |
| **GMAT Prep** | ❌ Age restricted | ❌ Age restricted (until 18) | ✅ Available |
| **Grade League** | ✅ Show | ✅ Show | ❌ Hide |
| **Study With Friends** | ✅ Show | ✅ Show | ✅ Show |
| **Daily Class Challenge** | ✅ Show | ✅ Show | ✅ Show (College level) |

---

## 🎨 **UI Changes by Age**

### **Example: 17-year-old (High School Senior)**

**Education Settings:**
```
Age: 17 years old
School System: US (Grades)
Current Grade Level: Grade 12
Challenge Level: Grade 12
Exam Focus: 
  ○ None
  ● SAT Prep ($6/mo) ✓ Available
  ○ GMAT Prep (18+ only) 🔒 Locked
```

**Home Screen:**
```
📚 Daily Class Challenge (Grade 12)
📝 Subject Practice
🎓 SAT Prep
👥 Study With Friends
🏆 Grade League
```

---

### **Example: 19-year-old (College Freshman)**

**Education Settings:**
```
Age: 19 years old

ℹ️ Focus on SAT/GMAT prep for college/MBA admission

Exam Focus:
  ○ None
  ● SAT Prep ($6/mo) ✓ Available
  ○ GMAT Prep ($6/mo) ✓ Available
```

**Home Screen:**
```
📚 Daily Class Challenge (College Level)
🎓 SAT Prep
💼 GMAT Prep
👥 Study With Friends
```

---

## 💡 **Study With Friends Options**

### **High School Student (Age 16, SAT unlocked):**
```
👥 Study With Friends

Choose what to practice together:

┌─────────────────────────────────────┐
│ 📚  School Subjects                  │
│     Math, Science, English, etc.    │→
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🎓  SAT Practice                     │
│     Math & Reading/Writing          │→
└─────────────────────────────────────┘
```

### **College Student (Age 20, Both unlocked):**
```
👥 Study With Friends

Choose what to practice together:

┌─────────────────────────────────────┐
│ 🎓  SAT Practice                     │
│     Math & Reading/Writing          │→
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 💼  GMAT Practice                    │
│     Quantitative & Verbal           │→
└─────────────────────────────────────┘
```

---

## 🎯 **Benefits**

### **For High School Students:**
- ✅ Study together for classes
- ✅ Prepare for SAT with friends
- ✅ Compete in grade leagues
- ✅ Fun, collaborative learning

### **For College Students:**
- ✅ Focus on exam prep (SAT/GMAT)
- ✅ Study with peers for admissions
- ✅ No clutter from grade-level options
- ✅ Streamlined, goal-focused UI

---

## 🔐 **Age-Based Validation**

### **Settings Screen:**
```dart
// Check if user is beyond high school age (19+)
bool get _isBeyondHighSchoolAge => _selectedAge! >= 19;

// Hide grade-related fields if true
if (!_isBeyondHighSchoolAge) {
  // Show: School System, Grade Level, Challenge Level
}

// Show info message if post-high-school
if (_isBeyondHighSchoolAge) {
  // Show: "Focus on SAT/GMAT prep" message
}
```

### **Home Screen:**
```dart
// Get user age
final age = user?.age ?? 0;
final isBeyondHighSchool = age >= 19;

// Conditionally show features
if (!isBeyondHighSchool) {
  // Show: Subject Practice, Grade League
}

// Always show: Study With Friends, SAT/GMAT (if unlocked)
```

---

## 📱 **Complete User Journeys**

### **Journey 1: High School Junior (16) preparing for SAT**

```
1. Sign up, select Education Mode
2. Age: 16, System: US, Grade: 11
3. Exam Focus: SAT Prep
4. Subscribe for $6/mo
5. Home shows:
   - Daily Class Challenge (Grade 11)
   - Subject Practice
   - SAT Prep ✓
   - Study With Friends
   - Grade League
6. Tap "Study With Friends"
7. Choose "SAT Practice"
8. Select "Math"
9. Create room, invite friends
10. All practice SAT Math together!
```

---

### **Journey 2: College Student (20) preparing for MBA**

```
1. Sign up, select Education Mode
2. Age: 20
3. No grade selection (hidden)
4. Exam Focus: GMAT Prep
5. Subscribe for $6/mo
6. Home shows:
   - Daily Class Challenge (College Level)
   - GMAT Prep ✓
   - Study With Friends
7. Tap "Study With Friends"
8. Choose "GMAT Practice"
9. Select "Quantitative"
10. Create room, invite study group
11. All practice GMAT Quant together!
```

---

## 🎓 **Smart UI Principles**

### **1. Age-Appropriate Content**
- Hide options that aren't relevant
- Show only what matters for user's stage
- Reduce cognitive load

### **2. Progressive Disclosure**
- Start simple, add complexity as needed
- Don't overwhelm with unnecessary choices
- Clear, focused pathways

### **3. Collaborative Learning**
- Study With Friends in all age groups
- Different subjects for different goals
- Fun, social, educational

### **4. Respectful Gating**
- Age restrictions clearly communicated
- Visual indicators (badges, locks)
- No frustration, just clarity

---

## ✅ **Implementation Checklist**

- [x] Age range extended to 30
- [x] Age-based UI hiding (19+)
- [x] Post-high-school info message
- [x] Grade fields hidden for college age
- [x] Subject Practice hidden for 19+
- [x] Grade League hidden for 19+
- [x] Study With Friends added to Education Mode
- [x] Multi-mode selection (School/SAT/GMAT)
- [x] Subject selection per mode
- [x] Navigation to Play With Friends
- [x] Age validation for exam access

---

**Status**: ✅ **FULLY IMPLEMENTED**  
**Last Updated**: January 11, 2026  
**Ready for**: Testing & User Feedback

