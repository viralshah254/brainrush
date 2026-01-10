enum AppMode {
  general,
  education,
}

enum SchoolSystem {
  us('US (Grades)', 'US'),
  uk('UK (Year)', 'UK'),
  general('General', 'GENERAL');

  final String displayName;
  final String code;
  
  const SchoolSystem(this.displayName, this.code);
}

enum ExamFocus {
  none('None', 'NONE', false),
  sat('SAT Prep', 'SAT', true),
  gmat('GMAT Prep', 'GMAT', true);

  final String displayName;
  final String code;
  final bool requiresSubscription;
  
  const ExamFocus(this.displayName, this.code, this.requiresSubscription);
}

enum QuestionMode {
  general('GENERAL'),
  educationSchool('EDUCATION_SCHOOL'),
  educationSat('EDUCATION_SAT'),
  educationGmat('EDUCATION_GMAT');

  final String code;
  
  const QuestionMode(this.code);
}

class GradeLevel {
  final String code;
  final String displayName;
  final int numericValue;
  final int suggestedAge;
  final String systemCode; // 'US', 'UK', or 'GENERAL'

  const GradeLevel({
    required this.code,
    required this.displayName,
    required this.numericValue,
    required this.suggestedAge,
    required this.systemCode,
  });

  // US System (Grades)
  static const List<GradeLevel> usGrades = [
    GradeLevel(code: 'US_GRADE_5', displayName: 'Grade 5', numericValue: 5, suggestedAge: 10, systemCode: 'US'),
    GradeLevel(code: 'US_GRADE_6', displayName: 'Grade 6', numericValue: 6, suggestedAge: 11, systemCode: 'US'),
    GradeLevel(code: 'US_GRADE_7', displayName: 'Grade 7', numericValue: 7, suggestedAge: 12, systemCode: 'US'),
    GradeLevel(code: 'US_GRADE_8', displayName: 'Grade 8', numericValue: 8, suggestedAge: 13, systemCode: 'US'),
    GradeLevel(code: 'US_GRADE_9', displayName: 'Grade 9', numericValue: 9, suggestedAge: 14, systemCode: 'US'),
    GradeLevel(code: 'US_GRADE_10', displayName: 'Grade 10', numericValue: 10, suggestedAge: 15, systemCode: 'US'),
    GradeLevel(code: 'US_GRADE_11', displayName: 'Grade 11', numericValue: 11, suggestedAge: 16, systemCode: 'US'),
    GradeLevel(code: 'US_GRADE_12', displayName: 'Grade 12', numericValue: 12, suggestedAge: 17, systemCode: 'US'),
  ];

  // UK System (Years)
  static const List<GradeLevel> ukYears = [
    GradeLevel(code: 'UK_YEAR_5', displayName: 'Year 5', numericValue: 5, suggestedAge: 10, systemCode: 'UK'),
    GradeLevel(code: 'UK_YEAR_6', displayName: 'Year 6', numericValue: 6, suggestedAge: 11, systemCode: 'UK'),
    GradeLevel(code: 'UK_YEAR_7', displayName: 'Year 7', numericValue: 7, suggestedAge: 12, systemCode: 'UK'),
    GradeLevel(code: 'UK_YEAR_8', displayName: 'Year 8', numericValue: 8, suggestedAge: 13, systemCode: 'UK'),
    GradeLevel(code: 'UK_YEAR_9', displayName: 'Year 9', numericValue: 9, suggestedAge: 14, systemCode: 'UK'),
    GradeLevel(code: 'UK_YEAR_10', displayName: 'Year 10', numericValue: 10, suggestedAge: 15, systemCode: 'UK'),
    GradeLevel(code: 'UK_YEAR_11', displayName: 'Year 11', numericValue: 11, suggestedAge: 16, systemCode: 'UK'),
    GradeLevel(code: 'UK_YEAR_12', displayName: 'Year 12', numericValue: 12, suggestedAge: 17, systemCode: 'UK'),
  ];

  // General System (Grades - default)
  static const List<GradeLevel> generalGrades = [
    GradeLevel(code: 'GRADE_5', displayName: 'Grade 5', numericValue: 5, suggestedAge: 10, systemCode: 'GENERAL'),
    GradeLevel(code: 'GRADE_6', displayName: 'Grade 6', numericValue: 6, suggestedAge: 11, systemCode: 'GENERAL'),
    GradeLevel(code: 'GRADE_7', displayName: 'Grade 7', numericValue: 7, suggestedAge: 12, systemCode: 'GENERAL'),
    GradeLevel(code: 'GRADE_8', displayName: 'Grade 8', numericValue: 8, suggestedAge: 13, systemCode: 'GENERAL'),
    GradeLevel(code: 'GRADE_9', displayName: 'Grade 9', numericValue: 9, suggestedAge: 14, systemCode: 'GENERAL'),
    GradeLevel(code: 'GRADE_10', displayName: 'Grade 10', numericValue: 10, suggestedAge: 15, systemCode: 'GENERAL'),
    GradeLevel(code: 'GRADE_11', displayName: 'Grade 11', numericValue: 11, suggestedAge: 16, systemCode: 'GENERAL'),
    GradeLevel(code: 'GRADE_12', displayName: 'Grade 12', numericValue: 12, suggestedAge: 17, systemCode: 'GENERAL'),
  ];

  // Get grades for a specific system
  static List<GradeLevel> getGradesForSystem(String systemCode) {
    switch (systemCode) {
      case 'US':
        return usGrades;
      case 'UK':
        return ukYears;
      case 'GENERAL':
      default:
        return generalGrades;
    }
  }

  // Get all grades (default to general)
  static List<GradeLevel> get allGrades => generalGrades;

  static GradeLevel? fromAge(int age, String systemCode) {
    final grades = getGradesForSystem(systemCode);
    try {
      return grades.firstWhere((grade) => grade.suggestedAge == age);
    } catch (e) {
      // Default to closest grade
      if (age < 10) return grades.first;
      if (age > 17) return grades.last;
      return null;
    }
  }

  static GradeLevel? fromCode(String code) {
    // Try all systems
    for (final grades in [usGrades, ukYears, generalGrades]) {
      try {
        return grades.firstWhere((grade) => grade.code == code);
      } catch (e) {
        continue;
      }
    }
    return null;
  }
}

