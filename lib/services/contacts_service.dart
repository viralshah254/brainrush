import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactWithAppStatus {
  final Contact contact;
  final bool hasApp;
  final String? phoneNumber;

  ContactWithAppStatus({
    required this.contact,
    required this.hasApp,
    this.phoneNumber,
  });
}

class ContactsService {
  static final ContactsService _instance = ContactsService._internal();
  factory ContactsService() => _instance;
  ContactsService._internal();

  List<Contact>? _contacts;
  List<String> _contactsWithApp = [];

  /// Request contacts permission
  /// Returns: true if granted, false if denied
  Future<bool> requestPermission() async {
    try {
      // Use FlutterContacts.requestPermission() which is the recommended way
      // This properly handles iOS and Android permission requests
      final granted = await FlutterContacts.requestPermission();
      
      // ignore: avoid_print
      print('📱 FlutterContacts.requestPermission() result: $granted');
      
      // Trust FlutterContacts result - it's what we use to actually load contacts
      if (granted) {
        // ignore: avoid_print
        print('✅ Contacts permission GRANTED (FlutterContacts)');
        
        // Check permission_handler status for reference (may differ)
        final status = await Permission.contacts.status;
        // ignore: avoid_print
        print('📱 Permission handler status: $status');
        
        // Return true if FlutterContacts says granted (primary source)
        return true;
      }
      
      // If FlutterContacts says not granted, check if permanently denied
      final status = await Permission.contacts.status;
      // ignore: avoid_print
      print('📱 Permission status after denial: $status');
      // ignore: avoid_print
      print('❌ Contacts permission NOT granted');
      
      return false;
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('❌ Error requesting contacts permission: $e');
      // ignore: avoid_print
      print('❌ Stack trace: $stackTrace');
      
      // Fallback: Try using permission_handler directly
      try {
        // ignore: avoid_print
        print('🔄 Trying fallback permission request...');
        final status = await Permission.contacts.request();
        // ignore: avoid_print
        print('🔄 Fallback permission status: $status');
        return status.isGranted;
      } catch (fallbackError) {
        // ignore: avoid_print
        print('❌ Fallback permission request also failed: $fallbackError');
        return false;
      }
    }
  }

  /// Check if contacts permission is granted
  Future<bool> hasPermission() async {
    try {
      // Try a lightweight check with FlutterContacts (most reliable)
      // Request permission - if already granted, it returns true immediately
      final granted = await FlutterContacts.requestPermission();
      
      if (granted) {
        // ignore: avoid_print
        print('✅ Contacts permission GRANTED (FlutterContacts)');
        return true;
      }
      
      // Also check permission_handler for reference
      final status = await Permission.contacts.status;
      // ignore: avoid_print
      print('📱 Permission.contacts.status: $status');
      
      // If permission_handler says granted, trust it
      if (status.isGranted) {
        // ignore: avoid_print
        print('✅ Contacts permission GRANTED (permission_handler)');
        return true;
      }
      
      // ignore: avoid_print
      print('❌ Contacts permission NOT granted');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error checking contacts permission: $e');
      // Fallback to permission_handler
      try {
        final status = await Permission.contacts.status;
        return status.isGranted;
      } catch (_) {
        return false;
      }
    }
  }

  /// Check if permission is permanently denied (requires opening settings)
  Future<bool> isPermanentlyDenied() async {
    try {
      final status = await Permission.contacts.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error checking if permission is permanently denied: $e');
      return false;
    }
  }

  /// Get current permission status
  Future<PermissionStatus> getPermissionStatus() async {
    try {
      return await Permission.contacts.status;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error getting permission status: $e');
      return PermissionStatus.denied;
    }
  }

  /// Open app settings so user can grant permission manually
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error opening app settings: $e');
      return false;
    }
  }

  /// Load contacts from device
  Future<List<Contact>> loadContacts() async {
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        return [];
      }
    }

    try {
      _contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );
      
      // Sort by name
      _contacts!.sort((a, b) {
        final nameA = a.displayName.toLowerCase();
        final nameB = b.displayName.toLowerCase();
        return nameA.compareTo(nameB);
      });

      // Load saved "has app" contacts
      await _loadContactsWithApp();

      return _contacts ?? [];
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading contacts: $e');
      return [];
    }
  }

  /// Get contacts with app status
  Future<List<ContactWithAppStatus>> getContactsWithAppStatus() async {
    if (_contacts == null || _contacts!.isEmpty) {
      await loadContacts();
    }

    if (_contacts == null || _contacts!.isEmpty) {
      return [];
    }

    final contactsWithStatus = <ContactWithAppStatus>[];

    for (final contact in _contacts!) {
      // Get primary phone number
      final phoneNumber = contact.phones.isNotEmpty
          ? _normalizePhoneNumber(contact.phones.first.number)
          : null;

      // Check if this contact has the app (from saved list)
      final hasApp = phoneNumber != null && _contactsWithApp.contains(phoneNumber);

      contactsWithStatus.add(
        ContactWithAppStatus(
          contact: contact,
          hasApp: hasApp,
          phoneNumber: phoneNumber,
        ),
      );
    }

    // Sort: contacts with app first, then alphabetically
    contactsWithStatus.sort((a, b) {
      if (a.hasApp && !b.hasApp) return -1;
      if (!a.hasApp && b.hasApp) return 1;
      return a.contact.displayName.toLowerCase()
          .compareTo(b.contact.displayName.toLowerCase());
    });

    return contactsWithStatus;
  }

  /// Mark a contact as having the app (for frontend simulation)
  /// In a real app, this would be determined by backend matching phone numbers
  Future<void> markContactAsHasApp(String phoneNumber) async {
    final normalized = _normalizePhoneNumber(phoneNumber);
    if (!_contactsWithApp.contains(normalized)) {
      _contactsWithApp.add(normalized);
      await _saveContactsWithApp();
    }
  }

  /// Check if a phone number has the app
  bool contactHasApp(String phoneNumber) {
    final normalized = _normalizePhoneNumber(phoneNumber);
    return _contactsWithApp.contains(normalized);
  }

  /// Normalize phone number (remove spaces, dashes, etc.)
  String _normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Load saved contacts with app from SharedPreferences
  Future<void> _loadContactsWithApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('contacts_with_app') ?? [];
      _contactsWithApp = saved;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading contacts with app: $e');
      _contactsWithApp = [];
    }
  }

  /// Save contacts with app to SharedPreferences
  Future<void> _saveContactsWithApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('contacts_with_app', _contactsWithApp);
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error saving contacts with app: $e');
    }
  }

  /// Simulate finding contacts with app (frontend-only)
  /// In production, this would query a backend API
  Future<void> simulateFindContactsWithApp() async {
    // For demo purposes, randomly mark some contacts as having the app
    // In production, this would be done via backend API matching phone numbers
    if (_contacts == null || _contacts!.isEmpty) {
      await loadContacts();
    }

    if (_contacts == null || _contacts!.isEmpty) return;

    // Mark first 3 contacts with phone numbers as having the app (for demo)
    int marked = 0;
    for (final contact in _contacts!) {
      if (contact.phones.isNotEmpty && marked < 3) {
        final phone = _normalizePhoneNumber(contact.phones.first.number);
        if (!_contactsWithApp.contains(phone)) {
          _contactsWithApp.add(phone);
          marked++;
        }
      }
    }

    await _saveContactsWithApp();
  }
}

