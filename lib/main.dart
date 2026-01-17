import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/game_provider.dart';
import 'providers/mode_provider.dart';
import 'services/premium_service.dart';
import 'services/ad_service.dart';
import 'services/campaign_service.dart';
import 'services/question_service.dart';
import 'services/education_subscription_service.dart';
import 'services/retention_service.dart';
import 'services/fcm_service.dart';
import 'services/local_notification_service.dart';
import 'services/education_question_bank.dart';
import 'services/expanded_question_bank.dart';
import 'services/version_check_service.dart';
import 'services/card_collection_service.dart';
import 'services/friend_service.dart';
import 'services/locale_service.dart';
import 'l10n/app_localizations_delegate.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/update_check_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style to match dark theme immediately
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E27),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase (REQUIRED)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    print('✅ Firebase initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('❌ CRITICAL: Firebase initialization failed: $e');
    // Don't continue if Firebase fails - it's required for auth
    rethrow;
  }

  // Initialize Firebase Cloud Messaging
  try {
    await FCMService().initialize();
    // ignore: avoid_print
    print('✅ FCM initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ FCM not available (iOS Simulator) - $e');
  }

  // Initialize Local Notifications
  try {
    await LocalNotificationService().initialize();
    // ignore: avoid_print
    print('✅ Local notifications initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ Local notifications error: $e');
  }

  // Initialize Mobile Ads (with error handling)
  // Note: Ads won't work on iOS Simulator - use real device for testing
  try {
    await MobileAds.instance.initialize();
    await AdService().initialize();
    // ignore: avoid_print
    print('✅ Ads initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ Ads not available (Simulator or config issue) - App will work without ads');
  }
  
  // Initialize Premium Service
  // Note: In-App Purchase needs real device or TestFlight
  try {
    await PremiumService().initialize();
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ In-App Purchase not available (Simulator) - Premium features disabled');
  }

  // Initialize Education Subscription Service
  try {
    await EducationSubscriptionService().initialize();
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ Education subscriptions not available (Simulator) - Education subscriptions disabled');
  }

  // Start loading questions in background (non-blocking)
  // Questions will load lazily when needed, but we start the process early
  EducationQuestionBank.initialize().catchError((e) {
    // ignore: avoid_print
    print('⚠️ Error loading education questions in background: $e');
  });
  
  // Also pre-initialize ExpandedQuestionBank in background
  ExpandedQuestionBank.initialize().catchError((e) {
    // ignore: avoid_print
    print('⚠️ Error loading questions in background: $e');
  });

  // Initialize Version Check Service
  try {
    // ignore: avoid_print
    print('🔍 Initializing version check service...');
    await VersionCheckService().initialize();
    // ignore: avoid_print
    print('✅ Version check service initialized');
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ Version check service initialization error: $e');
    // Don't block app startup - version check will use defaults
  }

  runApp(const MindRushApp());
}

class MindRushApp extends StatelessWidget {
  const MindRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => GameProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ModeProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PremiumService(),
        ),
        ChangeNotifierProvider(
          create: (_) => EducationSubscriptionService(),
        ),
        Provider(
          create: (_) => AdService(),
        ),
        Provider(
          create: (_) {
            final service = QuestionService();
            // Initialize in background (non-blocking)
            service.initialize().catchError((e) {
              debugPrint('⚠️ Error initializing QuestionService: $e');
            });
            return service;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => CampaignService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => RetentionService(),
        ),
        // Initialize card collection service
        ChangeNotifierProvider(
          create: (_) {
            final service = CardCollectionService();
            service.loadUserCards(); // Load user's cards
            return service;
          },
        ),
        // Initialize friend service
        ChangeNotifierProvider(
          create: (_) {
            final service = FriendService();
            service.initialize(); // Load friends
            return service;
          },
        ),
        // Initialize locale service
        ChangeNotifierProvider(
          create: (_) {
            final service = LocaleService();
            service.initialize(); // Load saved locale
            return service;
          },
        ),
      ],
      child: UpdateCheckWrapper(
        child: Consumer<LocaleService>(
          builder: (context, localeService, _) {
            return MaterialApp(
              title: 'MindRush',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              // Localization
              locale: localeService.currentLocale,
              supportedLocales: LocaleService.supportedLocales,
              localizationsDelegates: [
                const AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // RTL Support
              builder: (context, child) {
                return Directionality(
                  textDirection: localeService.isRTL 
                      ? TextDirection.rtl 
                      : TextDirection.ltr,
                  child: child!,
                );
              },
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
