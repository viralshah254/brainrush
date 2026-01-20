import '../api_client.dart';

/// System & App Info API Service
class SystemApiService {
  final ApiClient _api = ApiClient();

  /// Health check
  Future<Map<String, dynamic>> healthCheck() async {
    return await _api.get<Map<String, dynamic>>(
      '/health',
      requiresAuth: false,
    );
  }

  /// Get app version
  Future<Map<String, dynamic>> getAppVersion() async {
    return await _api.get<Map<String, dynamic>>(
      '/app/version',
      requiresAuth: false,
    );
  }

  /// Version check (alias)
  Future<Map<String, dynamic>> versionCheck({
    required String platform,
    required String currentVersion,
  }) async {
    return await _api.get<Map<String, dynamic>>(
      '/app/version-check',
      queryParams: {
        'platform': platform,
        'currentVersion': currentVersion,
      },
      requiresAuth: false,
    );
  }

  /// Get force update status
  Future<Map<String, dynamic>> getForceUpdateStatus({
    required String platform,
  }) async {
    return await _api.get<Map<String, dynamic>>(
      '/app/force-update',
      queryParams: {'platform': platform},
      requiresAuth: false,
    );
  }

  /// Get FAQ
  Future<List<dynamic>> getFAQ() async {
    return await _api.get<List<dynamic>>(
      '/help/faq',
      requiresAuth: false,
    );
  }

  /// Submit support ticket
  Future<void> submitSupportTicket({
    required String subject,
    required String message,
    required String category,
  }) async {
    await _api.post(
      '/help/support',
      body: {
        'subject': subject,
        'message': message,
        'category': category,
      },
      requiresAuth: false,
    );
  }

  /// Submit support ticket (new endpoint)
  Future<Map<String, dynamic>> submitSupportTicketNew({
    required String subject,
    required String message,
    required String category,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/help/ticket',
      body: {
        'subject': subject,
        'message': message,
        'category': category,
      },
      requiresAuth: false,
    );
  }

  /// Get store items
  Future<List<dynamic>> getStoreItems() async {
    return await _api.get<List<dynamic>>('/store/items');
  }

  /// Get coin packages
  Future<Map<String, dynamic>> getCoinPackages() async {
    return await _api.get<Map<String, dynamic>>('/store/coins/packages');
  }

  /// Get contact information
  Future<Map<String, dynamic>> getContactInformation() async {
    return await _api.get<Map<String, dynamic>>(
      '/help/contact',
      requiresAuth: false,
    );
  }

  /// Get about information
  Future<Map<String, dynamic>> getAboutInformation() async {
    return await _api.get<Map<String, dynamic>>(
      '/about',
      requiresAuth: false,
    );
  }

  /// Get terms of service
  Future<Map<String, dynamic>> getTermsOfService() async {
    return await _api.get<Map<String, dynamic>>(
      '/legal/terms',
      requiresAuth: false,
    );
  }

  /// Get privacy policy
  Future<Map<String, dynamic>> getPrivacyPolicy() async {
    return await _api.get<Map<String, dynamic>>(
      '/legal/privacy',
      requiresAuth: false,
    );
  }

  /// Get available languages
  Future<List<dynamic>> getAvailableLanguages() async {
    return await _api.get<List<dynamic>>(
      '/languages',
      requiresAuth: false,
    );
  }

  /// Get match results
  Future<Map<String, dynamic>> getMatchResults(String matchId) async {
    return await _api.get<Map<String, dynamic>>(
      '/matches/$matchId/results',
    );
  }

  /// Get match rankings
  Future<Map<String, dynamic>> getMatchRankings(String matchId) async {
    return await _api.get<Map<String, dynamic>>(
      '/matches/$matchId/rankings',
    );
  }

  /// Share to social media
  Future<Map<String, dynamic>> shareToSocialMedia({
    required String platform,
    required String content,
    String? url,
  }) async {
    final body = <String, dynamic>{
      'platform': platform,
      'content': content,
    };
    if (url != null) body['url'] = url;

    return await _api.post<Map<String, dynamic>>(
      '/social/share',
      body: body,
    );
  }

  /// Get purchase history
  Future<List<dynamic>> getPurchaseHistory() async {
    return await _api.get<List<dynamic>>('/store/purchases');
  }

  /// Purchase item
  Future<Map<String, dynamic>> purchaseItem({
    required String itemId,
    required String paymentMethod,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/store/purchase',
      body: {
        'itemId': itemId,
        'paymentMethod': paymentMethod,
      },
    );
  }

  /// Purchase coins
  Future<Map<String, dynamic>> purchaseCoins({
    required String packageId,
    required String platform,
    required String transactionId,
    required String receipt,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/store/coins/purchase',
      body: {
        'packageId': packageId,
        'platform': platform,
        'transactionId': transactionId,
        'receipt': receipt,
      },
    );
  }
}

