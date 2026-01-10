import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'ad_service.dart';

class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Product IDs (update these in App Store Connect / Google Play Console)
  static const String monthlySubscriptionId = 'brainz_rush_premium_monthly';
  static const String yearlySubscriptionId = 'brainz_rush_premium_yearly';

  bool _isPremium = false;
  bool _isInitialized = false;
  List<ProductDetails> _products = [];
  
  bool get isPremium => _isPremium;
  bool get isInitialized => _isInitialized;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if In-App Purchase is available
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        // ignore: avoid_print
        print('⚠️ In-App Purchase not available');
        return;
      }

      // Load saved premium status
      await _loadPremiumStatus();

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) {
          // ignore: avoid_print
          print('❌ Purchase stream error: $error');
        },
      );

      // Load products
      await _loadProducts();

      // Restore purchases (important for subscriptions)
      await restorePurchases();

      _isInitialized = true;
      // ignore: avoid_print
      print('✅ PremiumService initialized');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error initializing PremiumService: $e');
    }
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
    
    // Update AdService
    AdService().setPremiumStatus(_isPremium);
    
    notifyListeners();
  }

  Future<void> _savePremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', isPremium);
    
    // Update AdService
    AdService().setPremiumStatus(isPremium);
    
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    try {
      const Set<String> productIds = {
        monthlySubscriptionId,
        yearlySubscriptionId,
      };

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        // ignore: avoid_print
        print('❌ Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      
      // ignore: avoid_print
      print('✅ Loaded ${_products.length} products');
      for (final product in _products) {
        // ignore: avoid_print
        print('  - ${product.title}: ${product.price}');
      }
      
      notifyListeners();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading products: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        // ignore: avoid_print
        print('⏳ Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Grant premium access
        _savePremiumStatus(true);
        // ignore: avoid_print
        print('✅ Premium activated!');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Show error
        // ignore: avoid_print
        print('❌ Purchase error: ${purchaseDetails.error}');
      }

      // Complete purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<bool> purchaseMonthly() async {
    return _purchaseProduct(monthlySubscriptionId);
  }

  Future<bool> purchaseYearly() async {
    return _purchaseProduct(yearlySubscriptionId);
  }

  Future<bool> _purchaseProduct(String productId) async {
    try {
      final ProductDetails? product = _products
          .cast<ProductDetails?>()
          .firstWhere(
            (p) => p?.id == productId,
            orElse: () => null,
          );

      if (product == null) {
        // ignore: avoid_print
        print('❌ Product not found: $productId');
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Purchase error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      // ignore: avoid_print
      print('✅ Purchases restored');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error restoring purchases: $e');
    }
  }

  ProductDetails? getMonthlyProduct() {
    return _products
        .cast<ProductDetails?>()
        .firstWhere(
          (p) => p?.id == monthlySubscriptionId,
          orElse: () => null,
        );
  }

  ProductDetails? getYearlyProduct() {
    return _products
        .cast<ProductDetails?>()
        .firstWhere(
          (p) => p?.id == yearlySubscriptionId,
          orElse: () => null,
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

