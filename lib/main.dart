import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'providers/user_provider.dart';
import 'providers/game_provider.dart';
import 'providers/mode_provider.dart';
import 'services/premium_service.dart';
import 'services/ad_service.dart';
import 'services/campaign_service.dart';
import 'services/question_service.dart';
import 'services/education_subscription_service.dart';
import 'services/retention_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
          create: (_) => QuestionService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => CampaignService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => RetentionService(),
        ),
      ],
      child: MaterialApp(
        title: 'MindRush',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
