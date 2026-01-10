enum AppMode {
  general,
  education,
}

enum SchoolSystem {
  kenya_cbc('Kenya (CBC)', 'KE_CBC'),
  kenya_844('Kenya (8-4-4)', 'KE_844'),
  us_grades('US (Grades)', 'US'),
  uk_year('UK (Year)', 'UK'),
  india_standard('India (Standard)', 'IN'),
  other('Other', 'OTHER');

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

  const GradeLevel({
    required this.code,
    required this.displayName,
    required this.numericValue,
    required this.suggestedAge,
  });

  static const List<GradeLevel> allGrades = [
    GradeLevel(code: 'GRADE_5', displayName: 'Grade 5', numericValue: 5, suggestedAge: 10),
    GradeLevel(code: 'GRADE_6', displayName: 'Grade 6', numericValue: 6, suggestedAge: 11),
    GradeLevel(code: 'GRADE_7', displayName: 'Grade 7', numericValue: 7, suggestedAge: 12),
    GradeLevel(code: 'GRADE_8', displayName: 'Grade 8', numericValue: 8, suggestedAge: 13),
    GradeLevel(code: 'GRADE_9', displayName: 'Grade 9', numericValue: 9, suggestedAge: 14),
    GradeLevel(code: 'GRADE_10', displayName: 'Grade 10', numericValue: 10, suggestedAge: 15),
    GradeLevel(code: 'GRADE_11', displayName: 'Grade 11', numericValue: 11, suggestedAge: 16),
    GradeLevel(code: 'GRADE_12', displayName: 'Grade 12', numericValue: 12, suggestedAge: 17),
  ];

  static GradeLevel? fromAge(int age) {
    try {
      return allGrades.firstWhere((grade) => grade.suggestedAge == age);
    } catch (e) {
      // Default to closest grade
      if (age < 10) return allGrades.first;
      if (age > 17) return allGrades.last;
      return null;
    }
  }

  static GradeLevel? fromCode(String code) {
    try {
      return allGrades.firstWhere((grade) => grade.code == code);
    } catch (e) {
      return null;
    }
  }
}

