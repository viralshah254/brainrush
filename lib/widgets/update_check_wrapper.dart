import 'package:flutter/material.dart';
import '../services/version_check_service.dart';
import '../widgets/update_dialog.dart';

/// Wrapper widget that checks for updates and blocks navigation if force update is required
class UpdateCheckWrapper extends StatefulWidget {
  final Widget child;

  const UpdateCheckWrapper({
    super.key,
    required this.child,
  });

  @override
  State<UpdateCheckWrapper> createState() => _UpdateCheckWrapperState();
}

class _UpdateCheckWrapperState extends State<UpdateCheckWrapper>
    with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check for updates when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);

    try {
      final versionService = VersionCheckService();
      
      // Re-fetch remote config to get latest version requirements
      try {
        await versionService.initialize();
      } catch (e) {
        // If initialization fails, don't block app
        setState(() => _isChecking = false);
        return;
      }

      final isUpdateRequired = await versionService.isUpdateRequired();
      final isForceUpdate = await versionService.isForceUpdateEnabled();

      if (isUpdateRequired && mounted) {
        // Show update dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            title: versionService.getUpdateTitle(),
            message: versionService.getUpdateMessage(),
            storeUrl: versionService.getStoreUrl(),
            isForceUpdate: isForceUpdate,
          ),
        );

        // If force update, keep checking
        if (isForceUpdate && mounted) {
          // Re-check after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _checkForUpdates();
            }
          });
          return;
        }
      }
    } catch (e) {
      // Don't block app if check fails
      debugPrint('⚠️ Update check error: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

