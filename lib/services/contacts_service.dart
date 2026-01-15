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
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Check if contacts permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
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

