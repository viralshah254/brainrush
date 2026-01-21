import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service to manage app locale and language selection
class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  static const String _localeKey = 'app_locale';
  Locale _currentLocale = const Locale('en'); // Default to English

  Locale get currentLocale => _currentLocale;

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('hi'), // Hindi
    Locale('zh'), // Chinese (Simplified)
    Locale('ar'), // Arabic
  ];

  /// Language names in their native scripts
  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Español',
    'hi': 'हिन्दी',
    'zh': '中文',
    'ar': 'العربية',
  };

  /// Initialize locale from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        _currentLocale = Locale(localeCode);
        notifyListeners();
        debugPrint('✅ Locale initialized: $localeCode');
      }
    } catch (e) {
      debugPrint('❌ Error initializing locale: $e');
    }
  }

  /// Change app locale
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      _currentLocale = locale;
      notifyListeners();
      debugPrint('✅ Locale changed to: ${locale.languageCode}');
    } catch (e) {
      debugPrint('❌ Error changing locale: $e');
    }
  }

  /// Get language name for a locale
  String getLanguageName(String localeCode) {
    return languageNames[localeCode] ?? localeCode.toUpperCase();
  }

  /// Check if current locale is RTL
  bool get isRTL {
    return _currentLocale.languageCode == 'ar';
  }
}




