# 🎓 Education Mode - School Systems & Grade Levels

## ✅ **What Changed**

### **School Systems (Simplified)**

**Before** (5 systems):
- Kenya (CBC)
- Kenya (8-4-4)
- US (Grades)
- UK (Year)
- India (Standard)
- Other

**After** (3 systems):
- 🇺🇸 **US (Grades)** - Grade 5, Grade 6, Grade 7, ..., Grade 12
- 🇬🇧 **UK (Year)** - Year 5, Year 6, Year 7, ..., Year 12
- 🌍 **General** - Grade 5, Grade 6, Grade 7, ..., Grade 12

---

## 🔄 **Dynamic Grade Level Updates**

### **How It Works:**

1. **Select School System** → Grade options automatically update
2. **Select Age** → Suggests appropriate grade for that system
3. **Switch Systems** → Grades reset to match new system

### **Example Flow:**

```
1. User selects "US (Grades)"
   → Dropdown shows: Grade 5, Grade 6, ..., Grade 12

2. User selects Age: 15
   → Auto-suggests: Grade 10

3. User switches to "UK (Year)"
   → Dropdown updates: Year 5, Year 6, ..., Year 12
   → Auto-updates to: Year 10 (equivalent)
```

---

## 📊 **Grade Level Mappings**

### **US System:**
| Code | Display | Age |
|------|---------|-----|
| US_GRADE_5 | Grade 5 | 10 |
| US_GRADE_6 | Grade 6 | 11 |
| US_GRADE_7 | Grade 7 | 12 |
| US_GRADE_8 | Grade 8 | 13 |
| US_GRADE_9 | Grade 9 | 14 |
| US_GRADE_10 | Grade 10 | 15 |
| US_GRADE_11 | Grade 11 | 16 |
| US_GRADE_12 | Grade 12 | 17 |

### **UK System:**
| Code | Display | Age |
|------|---------|-----|
| UK_YEAR_5 | Year 5 | 10 |
| UK_YEAR_6 | Year 6 | 11 |
| UK_YEAR_7 | Year 7 | 12 |
| UK_YEAR_8 | Year 8 | 13 |
| UK_YEAR_9 | Year 9 | 14 |
| UK_YEAR_10 | Year 10 | 15 |
| UK_YEAR_11 | Year 11 | 16 |
| UK_YEAR_12 | Year 12 | 17 |

### **General System:**
| Code | Display | Age |
|------|---------|-----|
| GRADE_5 | Grade 5 | 10 |
| GRADE_6 | Grade 6 | 11 |
| GRADE_7 | Grade 7 | 12 |
| GRADE_8 | Grade 8 | 13 |
| GRADE_9 | Grade 9 | 14 |
| GRADE_10 | Grade 10 | 15 |
| GRADE_11 | Grade 11 | 16 |
| GRADE_12 | Grade 12 | 17 |

---

## 🎯 **Implementation Details**

### **1. GradeLevel Class Updates:**

```dart
class GradeLevel {
  final String systemCode; // 'US', 'UK', or 'GENERAL'
  
  static List<GradeLevel> getGradesForSystem(String systemCode) {
    switch (systemCode) {
      case 'US':
        return usGrades; // Grade 5, Grade 6, etc.
      case 'UK':
        return ukYears;  // Year 5, Year 6, etc.
      default:
        return generalGrades; // Grade 5, Grade 6, etc.
    }
  }
}
```

### **2. Dynamic Dropdown:**

```dart
List<GradeLevel> get _availableGrades {
  if (_selectedSchoolSystem == null) {
    return GradeLevel.generalGrades;
  }
  return GradeLevel.getGradesForSystem(_selectedSchoolSystem!);
}
```

### **3. Auto-Update on System Change:**

```dart
onChanged: (value) {
  setState(() {
    _selectedSchoolSystem = value;
    
    // Reset grades and auto-suggest based on age
    if (value != null && _selectedAge != null) {
      final suggestedGrade = GradeLevel.fromAge(_selectedAge!, value);
      if (suggestedGrade != null) {
        _selectedGradeLevel = suggestedGrade.code;
        _selectedChallengeGradeLevel = suggestedGrade.code;
      }
    }
  });
}
```

---

## 🌍 **When to Use Each System**

### **US (Grades):**
- Users in United States
- American curriculum
- SAT preparation
- Grades 5-12

### **UK (Year):**
- Users in United Kingdom
- British curriculum
- GCSE/A-Level preparation
- Years 5-12

### **General:**
- All other countries
- International curriculum
- Mixed systems
- Default option
- Grades 5-12

---

## ✅ **User Experience**

### **Before:**
- 5 confusing school systems
- Static grade options
- No automatic updates
- Manual switching required

### **After:**
- 3 clear systems
- Dynamic grade options
- Automatic updates when switching
- Age-based suggestions
- System-appropriate terminology

---

## 📱 **UI Flow**

```
Education Settings Screen
  ↓
1. Select School System
   [US (Grades)] [UK (Year)] [General]
  ↓
2. Select Age (10-22)
   → Auto-suggests grade/year for that age
  ↓
3. Current Grade/Year
   → Shows appropriate options:
      US: Grade 5-12
      UK: Year 5-12
      General: Grade 5-12
  ↓
4. Challenge Level
   → Same options as Current Grade
  ↓
5. Exam Focus
   [None] [SAT $6/mo] [GMAT $6/mo]
```

---

## 🎓 **Question Filtering**

Questions will be tagged with:
- `mode`: EDUCATION_SCHOOL / EDUCATION_SAT / EDUCATION_GMAT
- `gradeLevel`: US_GRADE_10, UK_YEAR_10, GRADE_10, etc.
- `systemCode`: US, UK, GENERAL

**Filtering logic:**
```dart
// Get questions for user
if (user.schoolSystem == 'US') {
  // Filter by US_GRADE_X
} else if (user.schoolSystem == 'UK') {
  // Filter by UK_YEAR_X
} else {
  // Filter by GRADE_X (general)
}
```

---

## 🚀 **Benefits**

1. **Clearer Options**: Only 3 systems instead of 5
2. **Better UX**: Automatic updates when switching
3. **Appropriate Terminology**: "Grade" for US/General, "Year" for UK
4. **Age-Based Suggestions**: Smart defaults
5. **Scalable**: Easy to add more systems later
6. **Consistent**: Same numeric values across systems

---

## 📝 **Future Enhancements**

### **Could Add:**
- Australia (Years)
- Canada (Grades)
- India (Standard)
- Custom age ranges per country
- More granular age-to-grade mappings

### **Current Scope:**
- 🇺🇸 US (Grades)
- 🇬🇧 UK (Year)
- 🌍 General (Grades)

---

**Last Updated**: January 11, 2026  
**Status**: ✅ **IMPLEMENTED**  
**Files Modified**:
- `lib/models/app_mode.dart`
- `lib/screens/education/education_settings_screen.dart`

