import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // 🧪 TESTING MODE: Set to true to use Google's test ads (always available)
  // Set to false to use your real ad units
  static const bool _useTestAds = false; // Production ads enabled

  // Platform-specific App IDs
  // Android: ca-app-pub-4248679794653671~3486611912
  // iOS: ca-app-pub-4248679794653671~9985405800
  
  // Ad Unit IDs - Platform specific
  static String get _rewardedAdUnitId {
    if (_useTestAds) {
      // Google's test ad units (always have ads)
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded
      } else {
        return 'ca-app-pub-3940256099942544/5224354917'; // Android Test Rewarded
      }
    } else {
      // Your production ad units
      if (Platform.isIOS) {
        return 'ca-app-pub-4248679794653671/9905514752'; // iOS "Get a life" ad
      } else {
        return 'ca-app-pub-4248679794653671/5995363366'; // Android Try again (watch ad to try again)
      }
    }
  }
  
  static String get _rewardedInterstitialAdUnitId {
    if (_useTestAds) {
      // Google's test ad units
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/6978759866'; // iOS Test Rewarded Interstitial
      } else {
        return 'ca-app-pub-3940256099942544/5354046379'; // Android Test Rewarded Interstitial
      }
    } else {
      // Your production ad units
      if (Platform.isIOS) {
        // TODO: Replace with your actual iOS Rewarded Interstitial Ad Unit ID
        // For now, using a placeholder - you need to create a Rewarded Interstitial ad unit in AdMob
        // The error occurs because 9905514752 is a Rewarded Ad, not Rewarded Interstitial
        // Create a new Rewarded Interstitial ad unit in AdMob Console and replace this ID
        return 'ca-app-pub-4248679794653671/9905514752'; // ⚠️ WRONG TYPE - needs Rewarded Interstitial ID
      } else {
        return 'ca-app-pub-4248679794653671/8749519214'; // Android Double points and all other ads
      }
    }
  }

  RewardedAd? _tryAgainRewardedAd;
  RewardedInterstitialAd? _roundCompleteRewardedInterstitialAd;
  
  bool _isInitialized = false;
  bool _isPremium = false;

  // Loading states
  bool _isTryAgainAdLoading = false;
  bool _isRoundCompleteAdLoading = false;

  bool get isPremium => _isPremium;
  bool get isTryAgainAdReady => _tryAgainRewardedAd != null;
  bool get isRoundCompleteAdReady => _roundCompleteRewardedInterstitialAd != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      
      // ignore: avoid_print
      if (_useTestAds) {
        print('🧪 AdService initialized with TEST ADS (always available)');
        print('🧪 Change _useTestAds to false for production ads');
      } else {
        print('✅ AdService initialized with PRODUCTION ADS');
      }
      
      // Pre-load ads
      loadTryAgainAd();
      loadRoundCompleteAd();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error initializing ads: $e');
    }
  }

  void setPremiumStatus(bool isPremium) {
    _isPremium = isPremium;
    if (isPremium) {
      // Dispose ads if premium
      _tryAgainRewardedAd?.dispose();
      _tryAgainRewardedAd = null;
      _roundCompleteRewardedInterstitialAd?.dispose();
      _roundCompleteRewardedInterstitialAd = null;
    } else {
      // Reload ads if not premium
      loadTryAgainAd();
      loadRoundCompleteAd();
    }
  }

  // Load Try Again Rewarded Ad
  Future<bool> loadTryAgainAd() async {
    if (_isPremium || _isTryAgainAdLoading) return false;

    _isTryAgainAdLoading = true;
    final completer = Completer<bool>();

    // ignore: avoid_print
    print('📺 Loading Try Again ad for ${Platform.isIOS ? "iOS" : "Android"}...');
    // ignore: avoid_print
    print('📺 Ad Unit ID: $_rewardedAdUnitId');

    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _tryAgainRewardedAd = ad;
            _isTryAgainAdLoading = false;
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _tryAgainRewardedAd = null;
                loadTryAgainAd(); // Pre-load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                // ignore: avoid_print
                print('❌ Ad failed to show: ${error.code} - ${error.message}');
                ad.dispose();
                _tryAgainRewardedAd = null;
                loadTryAgainAd();
              },
            );
            
            // ignore: avoid_print
            print('✅ Try Again ad loaded successfully');
            completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            _isTryAgainAdLoading = false;
            _tryAgainRewardedAd = null;
            // ignore: avoid_print
            print('❌ Try Again ad failed to load: ${error.code} - ${error.message}');
            completer.complete(false);
            // Retry after delay
            Future.delayed(const Duration(seconds: 5), () => loadTryAgainAd());
          },
        ),
      );

      return await completer.future;
    } catch (e) {
      _isTryAgainAdLoading = false;
      // ignore: avoid_print
      print('❌ Exception loading Try Again ad: $e');
      completer.complete(false);
      return false;
    }
  }

  // Show Try Again Rewarded Ad with loading state
  Future<bool> showTryAgainAd() async {
    if (_isPremium) {
      // ignore: avoid_print
      print('💎 Premium user - skipping ad');
      return true; // Premium users don't need to watch ads
    }

    // Check if ad is loaded
    if (_tryAgainRewardedAd == null) {
      // ignore: avoid_print
      print('⏳ Ad not loaded yet, loading now and waiting...');
      
      // Try to load ad and wait up to 10 seconds (increased timeout for real devices)
      final loadResult = await Future.any([
        loadTryAgainAd(),
        Future.delayed(const Duration(seconds: 10), () => false),
      ]);

      if (!loadResult || _tryAgainRewardedAd == null) {
        // Ad failed to load
        // ignore: avoid_print
        print('❌ Failed to load ad - no ad available');
        return false; // Return false to indicate failure
      }

      // ignore: avoid_print
      print('✅ Ad loaded successfully, ready to show!');
    }

    // ignore: avoid_print
    print('📺 Showing Try Again ad...');

    bool rewardEarned = false;
    final completer = Completer<bool>();

    try {
      _tryAgainRewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          // ignore: avoid_print
          print('📺 Ad showing full screen');
        },
        onAdDismissedFullScreenContent: (ad) {
          // ignore: avoid_print
          print('📺 Ad dismissed');
          ad.dispose();
          _tryAgainRewardedAd = null;
          loadTryAgainAd(); // Pre-load next ad
          if (!completer.isCompleted) {
            completer.complete(rewardEarned);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          // ignore: avoid_print
          print('❌ Ad failed to show: ${error.code} - ${error.message}');
          ad.dispose();
          _tryAgainRewardedAd = null;
          loadTryAgainAd();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      _tryAgainRewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardEarned = true;
          // ignore: avoid_print
          print('✅ User earned reward: ${reward.amount} ${reward.type}');
        },
      );

      return await completer.future;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Exception showing Try Again ad: $e');
      return false;
    }
  }

  // Load Round Complete Rewarded Interstitial Ad
  Future<bool> loadRoundCompleteAd() async {
    if (_isPremium || _isRoundCompleteAdLoading) return false;

    _isRoundCompleteAdLoading = true;
    final completer = Completer<bool>();

    // ignore: avoid_print
    print('📺 Loading Round Complete ad for ${Platform.isIOS ? "iOS" : "Android"}...');
    // ignore: avoid_print
    print('📺 Ad Unit ID: $_rewardedInterstitialAdUnitId');

    try {
      await RewardedInterstitialAd.load(
        adUnitId: _rewardedInterstitialAdUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _roundCompleteRewardedInterstitialAd = ad;
            _isRoundCompleteAdLoading = false;
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _roundCompleteRewardedInterstitialAd = null;
                loadRoundCompleteAd(); // Pre-load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                // ignore: avoid_print
                print('❌ Round complete ad failed to show: ${error.code} - ${error.message}');
                ad.dispose();
                _roundCompleteRewardedInterstitialAd = null;
                loadRoundCompleteAd();
              },
            );
            
            // ignore: avoid_print
            print('✅ Round Complete ad loaded successfully');
            completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            _isRoundCompleteAdLoading = false;
            _roundCompleteRewardedInterstitialAd = null;
            // ignore: avoid_print
            print('❌ Round Complete ad failed to load: ${error.code} - ${error.message}');
            
            // If error is "Ad unit doesn't match format", it means wrong ad unit type
            if (error.code == 1 && error.message.contains('format')) {
              print('⚠️ ERROR: Ad unit ID is wrong type!');
              print('⚠️ You are using a Rewarded Ad unit ID for Rewarded Interstitial Ad.');
              print('⚠️ Please create a Rewarded Interstitial ad unit in AdMob Console.');
              print('⚠️ Current ID: $_rewardedInterstitialAdUnitId');
              // Don't retry if it's a format error - it will keep failing
              completer.complete(false);
              return;
            }
            
            completer.complete(false);
            // Retry after delay (only if not a format error)
            Future.delayed(const Duration(seconds: 30), () => loadRoundCompleteAd());
          },
        ),
      );

      return await completer.future;
    } catch (e) {
      _isRoundCompleteAdLoading = false;
      // ignore: avoid_print
      print('❌ Exception loading Round Complete ad: $e');
      return false;
    }
  }

  // Show Round Complete Rewarded Interstitial Ad
  Future<bool> showRoundCompleteAd() async {
    if (_isPremium) {
      // ignore: avoid_print
      print('💎 Premium user - skipping round complete ad');
      return true; // Premium users skip ads
    }

    // Check if ad is loaded
    if (_roundCompleteRewardedInterstitialAd == null) {
      // ignore: avoid_print
      print('⏳ Round Complete ad not loaded yet, loading now and waiting...');
      
      // Try to load ad and wait up to 5 seconds
      final loadResult = await Future.any([
        loadRoundCompleteAd(),
        Future.delayed(const Duration(seconds: 5), () => false),
      ]);

      if (!loadResult || _roundCompleteRewardedInterstitialAd == null) {
        // ignore: avoid_print
        print('⚠️ Round Complete ad not available (simulator or no fill)');
        return false;
      }

      // ignore: avoid_print
      print('✅ Round Complete ad loaded, ready to show!');
    }

    bool rewardEarned = false;
    final completer = Completer<bool>();

    try {
      // Set up callbacks before showing
      _roundCompleteRewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          // ignore: avoid_print
          print('📺 Round Complete ad showing full screen');
        },
        onAdDismissedFullScreenContent: (ad) {
          // ignore: avoid_print
          print('📺 Round Complete ad dismissed');
          ad.dispose();
          _roundCompleteRewardedInterstitialAd = null;
          loadRoundCompleteAd(); // Pre-load next ad
          if (!completer.isCompleted) {
            completer.complete(rewardEarned);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          // ignore: avoid_print
          print('❌ Round Complete ad failed to show: ${error.code} - ${error.message}');
          ad.dispose();
          _roundCompleteRewardedInterstitialAd = null;
          loadRoundCompleteAd();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      _roundCompleteRewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardEarned = true;
          // ignore: avoid_print
          print('✅ User earned bonus reward: ${reward.amount} ${reward.type}');
        },
      );

      // Wait for ad to be dismissed (user watches it)
      return await completer.future;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error showing Round Complete ad: $e');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    }
  }

  void dispose() {
    _tryAgainRewardedAd?.dispose();
    _roundCompleteRewardedInterstitialAd?.dispose();
  }
}

