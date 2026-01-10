import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';

/// Subscription service for SAT/GMAT education packages
/// Prices: SAT $6/mo, GMAT $6/mo
class EducationSubscriptionService extends ChangeNotifier {
  static final EducationSubscriptionService _instance = EducationSubscriptionService._internal();
  factory EducationSubscriptionService() => _instance;
  EducationSubscriptionService._internal();

  // Subscription status
  bool _hasSatSubscription = false;
  bool _hasGmatSubscription = false;
  bool _hasAllAccessSubscription = false;

  bool get hasSatSubscription => _hasSatSubscription || _hasAllAccessSubscription;
  bool get hasGmatSubscription => _hasGmatSubscription || _hasAllAccessSubscription;
  bool get hasAllAccessSubscription => _hasAllAccessSubscription;
  bool get hasAnyEducationSubscription => hasSatSubscription || hasGmatSubscription;

  // Product IDs for in_app_purchase
  static const String satMonthlyProductId = 'edu_sat_monthly';
  static const String gmatMonthlyProductId = 'edu_gmat_monthly';
  static const String allAccessMonthlyProductId = 'edu_all_access_monthly';

  // Pricing (for display)
  static const String satPrice = '\$6.00/month';
  static const String gmatPrice = '\$6.00/month';
  static const String allAccessPrice = '\$9.99/month';

  Future<void> initialize() async {
    await _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSatSubscription = prefs.getBool('has_sat_subscription') ?? false;
      _hasGmatSubscription = prefs.getBool('has_gmat_subscription') ?? false;
      _hasAllAccessSubscription = prefs.getBool('has_all_access_subscription') ?? false;
      
      // ignore: avoid_print
      print('✅ Subscription status loaded');
      // ignore: avoid_print
      print('   SAT: $_hasSatSubscription');
      // ignore: avoid_print
      print('   GMAT: $_hasGmatSubscription');
      // ignore: avoid_print
      print('   All Access: $_hasAllAccessSubscription');
      
      notifyListeners();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading subscription status: $e');
    }
  }

  /// Check if user can access a specific exam mode
  bool canAccessExamMode(ExamFocus examFocus) {
    switch (examFocus) {
      case ExamFocus.sat:
        return hasSatSubscription;
      case ExamFocus.gmat:
        return hasGmatSubscription;
      case ExamFocus.none:
        return true; // School mode is always accessible
    }
  }

  /// Purchase SAT subscription
  Future<bool> purchaseSatSubscription() async {
    // ignore: avoid_print
    print('🛒 Purchasing SAT subscription...');
    
    // TODO: Implement actual in_app_purchase flow
    // For now, simulate purchase
    _hasSatSubscription = true;
    await _saveSubscriptionStatus();
    notifyListeners();
    
    // Track analytics
    _trackSubscriptionEvent('subscribe_success', 'SAT');
    
    // ignore: avoid_print
    print('✅ SAT subscription activated');
    return true;
  }

  /// Purchase GMAT subscription
  Future<bool> purchaseGmatSubscription() async {
    // ignore: avoid_print
    print('🛒 Purchasing GMAT subscription...');
    
    // TODO: Implement actual in_app_purchase flow
    // For now, simulate purchase
    _hasGmatSubscription = true;
    await _saveSubscriptionStatus();
    notifyListeners();
    
    // Track analytics
    _trackSubscriptionEvent('subscribe_success', 'GMAT');
    
    // ignore: avoid_print
    print('✅ GMAT subscription activated');
    return true;
  }

  /// Purchase All Access subscription
  Future<bool> purchaseAllAccessSubscription() async {
    // ignore: avoid_print
    print('🛒 Purchasing All Access subscription...');
    
    // TODO: Implement actual in_app_purchase flow
    // For now, simulate purchase
    _hasAllAccessSubscription = true;
    await _saveSubscriptionStatus();
    notifyListeners();
    
    // Track analytics
    _trackSubscriptionEvent('subscribe_success', 'All Access');
    
    // ignore: avoid_print
    print('✅ All Access subscription activated');
    return true;
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    // ignore: avoid_print
    print('🔄 Restoring purchases...');
    
    // TODO: Implement actual in_app_purchase restore
    // For now, load from local storage
    await _loadSubscriptionStatus();
    
    // ignore: avoid_print
    print('✅ Purchases restored');
  }

  Future<void> _saveSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_sat_subscription', _hasSatSubscription);
      await prefs.setBool('has_gmat_subscription', _hasGmatSubscription);
      await prefs.setBool('has_all_access_subscription', _hasAllAccessSubscription);
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error saving subscription status: $e');
    }
  }

  void _trackSubscriptionEvent(String event, String product) {
    // TODO: Integrate with analytics service
    // Analytics.logEvent(event, {
    //   'product': product,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
    
    // ignore: avoid_print
    print('📊 Analytics: $event - $product');
  }

  /// For testing: Grant/revoke subscriptions manually
  Future<void> setSubscription(String type, bool value) async {
    switch (type.toLowerCase()) {
      case 'sat':
        _hasSatSubscription = value;
        break;
      case 'gmat':
        _hasGmatSubscription = value;
        break;
      case 'all':
        _hasAllAccessSubscription = value;
        break;
    }
    await _saveSubscriptionStatus();
    notifyListeners();
  }
}

