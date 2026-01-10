import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';

class ModeProvider extends ChangeNotifier {
  AppMode _currentMode = AppMode.general;
  QuestionMode _currentQuestionMode = QuestionMode.general;
  bool _isInitialized = false;

  AppMode get currentMode => _currentMode;
  QuestionMode get currentQuestionMode => _currentQuestionMode;
  bool get isInitialized => _isInitialized;
  bool get isEducationMode => _currentMode == AppMode.education;
  bool get isGeneralMode => _currentMode == AppMode.general;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('app_mode');
      
      if (savedMode == 'education') {
        _currentMode = AppMode.education;
        // Default to school for education mode
        _currentQuestionMode = QuestionMode.educationSchool;
      } else {
        _currentMode = AppMode.general;
        _currentQuestionMode = QuestionMode.general;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      // ignore: avoid_print
      print('✅ ModeProvider initialized: ${_currentMode.name}');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error initializing ModeProvider: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> switchMode(AppMode mode) async {
    if (_currentMode == mode) return;
    
    _currentMode = mode;
    
    // Update question mode based on app mode
    if (mode == AppMode.education) {
      _currentQuestionMode = QuestionMode.educationSchool;
    } else {
      _currentQuestionMode = QuestionMode.general;
    }
    
    // Persist
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_mode', mode.name);
      
      // ignore: avoid_print
      print('✅ Switched to ${mode.name} mode');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error saving mode: $e');
    }
    
    notifyListeners();
    
    // Analytics
    _trackModeSwitch(mode);
  }

  Future<void> setQuestionMode(QuestionMode mode) async {
    if (_currentQuestionMode == mode) return;
    
    _currentQuestionMode = mode;
    
    // If switching to SAT/GMAT, ensure we're in education mode
    if (mode == QuestionMode.educationSat || mode == QuestionMode.educationGmat) {
      _currentMode = AppMode.education;
    }
    
    notifyListeners();
    
    // ignore: avoid_print
    print('✅ Question mode set to: ${mode.code}');
  }

  void _trackModeSwitch(AppMode mode) {
    // TODO: Integrate with analytics service
    // Analytics.logEvent('mode_switch', {
    //   'mode': mode.name,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
    
    // ignore: avoid_print
    print('📊 Analytics: mode_switch to ${mode.name}');
  }
}

