import '../api_client.dart';

/// Education API Service
class EducationApiService {
  final ApiClient _api = ApiClient();

  /// Get education profile
  Future<Map<String, dynamic>> getEducationProfile() async {
    return await _api.get<Map<String, dynamic>>('/education/profile');
  }

  /// Update education profile
  Future<Map<String, dynamic>> updateEducationProfile({
    String? gradeLevel,
    String? examFocus,
    String? schoolSystem,
  }) async {
    final body = <String, dynamic>{};
    if (gradeLevel != null) body['gradeLevel'] = gradeLevel;
    if (examFocus != null) body['examFocus'] = examFocus;
    if (schoolSystem != null) body['schoolSystem'] = schoolSystem;

    return await _api.put<Map<String, dynamic>>(
      '/education/profile',
      body: body,
    );
  }

  /// Update age
  Future<void> updateAge(int age) async {
    await _api.put('/education/age', body: {'age': age});
  }

  /// Update school system
  Future<void> updateSchoolSystem(String schoolSystem) async {
    await _api.put(
      '/education/school-system',
      body: {'schoolSystem': schoolSystem},
    );
  }

  /// Update grade level
  Future<void> updateGradeLevel(String gradeLevel) async {
    await _api.put('/education/grade', body: {'gradeLevel': gradeLevel});
  }

  /// Update exam focus
  Future<void> updateExamFocus(String examFocus) async {
    await _api.put('/education/exam', body: {'examFocus': examFocus});
  }

  /// Update education age
  Future<Map<String, dynamic>> updateEducationAge(int age) async {
    return await _api.put<Map<String, dynamic>>(
      '/education/profile/age',
      body: {'age': age},
    );
  }

  /// Update challenge grade
  Future<Map<String, dynamic>> updateChallengeGrade(String challengeGrade) async {
    return await _api.put<Map<String, dynamic>>(
      '/education/profile/challenge-grade',
      body: {'challengeGrade': challengeGrade},
    );
  }

  /// Update education grade
  Future<Map<String, dynamic>> updateEducationGrade(String grade) async {
    return await _api.put<Map<String, dynamic>>(
      '/education/profile/grade',
      body: {'grade': grade},
    );
  }

  /// Update education school system
  Future<Map<String, dynamic>> updateEducationSchoolSystem(
    String schoolSystem,
  ) async {
    return await _api.put<Map<String, dynamic>>(
      '/education/profile/school-system',
      body: {'schoolSystem': schoolSystem},
    );
  }

  /// Update education exam
  Future<Map<String, dynamic>> updateEducationExam(String exam) async {
    return await _api.put<Map<String, dynamic>>(
      '/education/profile/exam',
      body: {'exam': exam},
    );
  }
}

