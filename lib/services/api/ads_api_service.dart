import '../api_client.dart';

/// Ad Monetization API Service
class AdsApiService {
  final ApiClient _api = ApiClient();

  /// Check ad eligibility
  Future<Map<String, dynamic>> checkAdEligibility() async {
    return await _api.get<Map<String, dynamic>>('/ads/eligible');
  }

  /// Record ad view
  Future<Map<String, dynamic>> recordAdView({
    required String adUnitId,
    required String adType,
    required String context,
    required bool completed,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/ads/view',
      body: {
        'adUnitId': adUnitId,
        'adType': adType,
        'context': context,
        'completed': completed,
      },
    );
  }

  /// Grant ad reward
  Future<Map<String, dynamic>> grantAdReward({
    required String adViewId,
    required String type,
    required int amount,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/ads/reward',
      body: {
        'adViewId': adViewId,
        'type': type,
        'amount': amount,
      },
    );
  }

  /// Watch try again ad
  Future<Map<String, dynamic>> watchTryAgainAd({
    required String adUnitId,
    required bool adWatched,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/ads/rewarded/try-again',
      body: {
        'adUnitId': adUnitId,
        'adWatched': adWatched,
      },
    );
  }

  /// Watch double points ad
  Future<Map<String, dynamic>> watchDoublePointsAd({
    required String adUnitId,
    required bool adWatched,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/ads/rewarded/double-points',
      body: {
        'adUnitId': adUnitId,
        'adWatched': adWatched,
      },
    );
  }
}




