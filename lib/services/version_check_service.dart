import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class VersionCheckService {
  static final VersionCheckService _instance = VersionCheckService._internal();
  factory VersionCheckService() => _instance;
  VersionCheckService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  PackageInfo? _packageInfo;

  /// Initialize the version check service
  Future<void> initialize() async {
    try {
      // Get current app version
      _packageInfo = await PackageInfo.fromPlatform();
      debugPrint('📱 Current app version: ${_packageInfo?.version} (${_packageInfo?.buildNumber})');

      // Initialize Firebase Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set default values (fallback if remote config fails)
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set defaults
      await _remoteConfig!.setDefaults({
        'minimum_required_version': _packageInfo?.version ?? '1.0.0',
        'force_update_enabled': false,
        'update_message': 'A new version of MindRush is available. Please update to continue.',
        'update_title': 'Update Required',
      });

      // Fetch remote config
      try {
        await _remoteConfig!.fetchAndActivate();
        debugPrint('✅ Remote config fetched successfully');
      } catch (e) {
        debugPrint('⚠️ Remote config fetch failed (using defaults): $e');
      }
    } catch (e) {
      debugPrint('⚠️ Version check service initialization error: $e');
    }
  }

  /// Get current app version
  String get currentVersion => _packageInfo?.version ?? '1.0.0';
  String get buildNumber => _packageInfo?.buildNumber ?? '0';

  /// Get minimum required version from remote config
  String get minimumRequiredVersion {
    try {
      return _remoteConfig?.getString('minimum_required_version') ?? currentVersion;
    } catch (e) {
      debugPrint('⚠️ Error getting minimum version: $e');
      return currentVersion;
    }
  }

  /// Check if update is required
  bool isUpdateRequired() {
    try {
      final current = _parseVersion(currentVersion);
      final required = _parseVersion(minimumRequiredVersion);
      
      debugPrint('🔍 Version check: Current=$current, Required=$required');
      
      return _compareVersions(current, required) < 0;
    } catch (e) {
      debugPrint('⚠️ Error checking version: $e');
      return false; // Don't block app if version check fails
    }
  }

  /// Check if force update is enabled
  bool isForceUpdateEnabled() {
    try {
      return _remoteConfig?.getBool('force_update_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get update message
  String getUpdateMessage() {
    try {
      return _remoteConfig?.getString('update_message') ?? 
             'A new version of MindRush is available. Please update to continue.';
    } catch (e) {
      return 'A new version of MindRush is available. Please update to continue.';
    }
  }

  /// Get update title
  String getUpdateTitle() {
    try {
      return _remoteConfig?.getString('update_title') ?? 'Update Required';
    } catch (e) {
      return 'Update Required';
    }
  }

  /// Get store URL based on platform
  String getStoreUrl() {
    if (Platform.isIOS) {
      // Replace with your actual App Store ID
      return 'https://apps.apple.com/app/idYOUR_APP_ID';
    } else if (Platform.isAndroid) {
      // Replace with your actual package name
      return 'https://play.google.com/store/apps/details?id=com.dvtechventures.mindrush';
    }
    return '';
  }

  /// Parse version string to comparable format
  List<int> _parseVersion(String version) {
    return version.split('.').map((v) => int.tryParse(v) ?? 0).toList();
  }

  /// Compare two version lists
  /// Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
  int _compareVersions(List<int> v1, List<int> v2) {
    final maxLength = v1.length > v2.length ? v1.length : v2.length;
    
    for (int i = 0; i < maxLength; i++) {
      final part1 = i < v1.length ? v1[i] : 0;
      final part2 = i < v2.length ? v2[i] : 0;
      
      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }
    
    return 0;
  }
}

