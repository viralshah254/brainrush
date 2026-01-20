import '../api_client.dart';

/// Subscriptions API Service
class SubscriptionsApiService {
  final ApiClient _api = ApiClient();

  /// Get all subscriptions
  Future<List<dynamic>> getSubscriptions() async {
    return await _api.get<List<dynamic>>('/subscriptions');
  }

  /// Purchase subscription
  Future<Map<String, dynamic>> purchaseSubscription({
    required String planId,
    required String paymentMethod,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/subscriptions/purchase',
      body: {
        'planId': planId,
        'paymentMethod': paymentMethod,
      },
    );
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    await _api.post('/subscriptions/$subscriptionId/cancel');
  }

  /// Get subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    return await _api.get<Map<String, dynamic>>('/subscriptions/status');
  }

  /// Get subscription status (alias)
  Future<List<dynamic>> getMySubscriptions() async {
    return await _api.get<List<dynamic>>('/subscriptions/me');
  }

  /// Restore purchases
  Future<List<dynamic>> restorePurchases() async {
    return await _api.post<List<dynamic>>('/subscriptions/restore');
  }

  /// Cancel my subscription
  Future<void> cancelMySubscription() async {
    await _api.post('/subscriptions/me/cancel');
  }

  /// Get premium benefits
  Future<Map<String, dynamic>> getPremiumBenefits() async {
    return await _api.get<Map<String, dynamic>>(
      '/subscriptions/premium/benefits',
    );
  }

  /// Purchase premium monthly
  Future<Map<String, dynamic>> purchasePremiumMonthly({
    required String platform,
    required String transactionId,
    required String receipt,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/subscriptions/premium/monthly',
      body: {
        'platform': platform,
        'transactionId': transactionId,
        'receipt': receipt,
      },
    );
  }

  /// Purchase premium yearly
  Future<Map<String, dynamic>> purchasePremiumYearly({
    required String platform,
    required String transactionId,
    required String receipt,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/subscriptions/premium/yearly',
      body: {
        'platform': platform,
        'transactionId': transactionId,
        'receipt': receipt,
      },
    );
  }

  /// Get SAT subscription info
  Future<Map<String, dynamic>> getSATSubscriptionInfo() async {
    return await _api.get<Map<String, dynamic>>(
      '/subscriptions/education/sat',
    );
  }

  /// Get GMAT subscription info
  Future<Map<String, dynamic>> getGMATSubscriptionInfo() async {
    return await _api.get<Map<String, dynamic>>(
      '/subscriptions/education/gmat',
    );
  }

  /// Get education products
  Future<List<dynamic>> getEducationProducts() async {
    return await _api.get<List<dynamic>>(
      '/subscriptions/education/products',
    );
  }

  /// Purchase SAT subscription
  Future<Map<String, dynamic>> purchaseSATSubscription({
    required String platform,
    required String transactionId,
    required String receipt,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/subscriptions/education/sat/purchase',
      body: {
        'platform': platform,
        'transactionId': transactionId,
        'receipt': receipt,
      },
    );
  }

  /// Purchase GMAT subscription
  Future<Map<String, dynamic>> purchaseGMATSubscription({
    required String platform,
    required String transactionId,
    required String receipt,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/subscriptions/education/gmat/purchase',
      body: {
        'platform': platform,
        'transactionId': transactionId,
        'receipt': receipt,
      },
    );
  }
}

