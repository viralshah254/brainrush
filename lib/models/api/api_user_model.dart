/// API User Response Model
class ApiUserModel {
  final String id;
  final String username;
  final String? email;
  final String? photoUrl;
  final int? age;
  final String? country;
  final Map<String, dynamic>? userStats;
  final Map<String, dynamic>? userWallet;
  final Map<String, dynamic>? userStreak;
  final Map<String, dynamic>? userPreferences;
  final Map<String, dynamic>? educationProfile;

  ApiUserModel({
    required this.id,
    required this.username,
    this.email,
    this.photoUrl,
    this.age,
    this.country,
    this.userStats,
    this.userWallet,
    this.userStreak,
    this.userPreferences,
    this.educationProfile,
  });

  factory ApiUserModel.fromJson(Map<String, dynamic> json) {
    return ApiUserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      age: json['age'] as int?,
      country: json['country'] as String?,
      userStats: json['userStats'] as Map<String, dynamic>?,
      userWallet: json['userWallet'] as Map<String, dynamic>?,
      userStreak: json['userStreak'] as Map<String, dynamic>?,
      userPreferences: json['userPreferences'] as Map<String, dynamic>?,
      educationProfile: json['educationProfile'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'age': age,
      'country': country,
      'userStats': userStats,
      'userWallet': userWallet,
      'userStreak': userStreak,
      'userPreferences': userPreferences,
      'educationProfile': educationProfile,
    };
  }
}







