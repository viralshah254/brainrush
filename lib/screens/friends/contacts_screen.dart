import 'package:flutter/material.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/contacts_service.dart';
import 'play_with_friends_screen.dart';

// These imports require: flutter pub get
// Once packages are installed, uncomment these lines:
// import 'package:share_plus/share_plus.dart';
// import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _contactsService = ContactsService();
  List<ContactWithAppStatus> _contacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    // Check permission
    final hasPermission = await _contactsService.hasPermission();
    if (!hasPermission) {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _hasPermission = true;
    });

    // Simulate finding contacts with app (for demo)
    // In production, this would be a backend API call
    await _contactsService.simulateFindContactsWithApp();
    final updatedContacts = await _contactsService.getContactsWithAppStatus();

    if (mounted) {
      setState(() {
        _contacts = updatedContacts;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await _contactsService.requestPermission();
    if (granted) {
      await _loadContacts();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts permission is required to find friends'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _inviteContact(dynamic contact) {
    final appStoreUrl = Platform.isIOS
        ? 'https://apps.apple.com/app/idYOUR_APP_ID' // Replace with actual App Store ID
        : 'https://play.google.com/store/apps/details?id=com.dvtechventures.mindrush';
    
    final contactName = contact.displayName ?? 'Friend';
    final message = 'Hey $contactName! Join me on MindRush - the ultimate quiz game! Download here: $appStoreUrl';
    
    // TODO: Uncomment once share_plus is installed (run: flutter pub get)
    // Share.share(message, subject: 'Join me on MindRush!');
    
    // Temporary fallback: Show dialog with message to copy
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: const Text(
            'Invite Friend',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy this message to invite your friend:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SelectableText(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppTheme.primaryNeon),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _playWithContact(ContactWithAppStatus contactWithStatus) {
    // Navigate to play with friends screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PlayWithFriendsScreen(),
      ),
    );
  }

  List<ContactWithAppStatus> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      final name = contact.contact.displayName.toLowerCase();
      final phone = contact.phoneNumber?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Find Friends'),
        backgroundColor: AppTheme.darkBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
            tooltip: 'Refresh contacts',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60),
                  filled: true,
                  fillColor: AppTheme.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasPermission
                      ? _buildPermissionRequest()
                      : _buildContactsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contacts_outlined,
              size: 80,
              color: Colors.white60,
            ),
            const SizedBox(height: 24),
            const Text(
              'Access Contacts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We need access to your contacts to find friends who also play MindRush!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.contacts),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: AppTheme.darkBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    final filtered = _filteredContacts;
    final contactsWithApp = filtered.where((c) => c.hasApp).toList();
    final contactsWithoutApp = filtered.where((c) => !c.hasApp).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contacts_outlined,
              size: 80,
              color: Colors.white60,
            ),
            const SizedBox(height: 16),
            const Text(
              'No contacts found',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Contacts with app section
        if (contactsWithApp.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Playing MindRush',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${contactsWithApp.length}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...contactsWithApp.map((contactWithStatus) =>
              _buildContactCard(contactWithStatus, hasApp: true)),
          const SizedBox(height: 24),
        ],

        // Contacts without app section
        if (contactsWithoutApp.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, color: Colors.orange, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Invite to Play',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${contactsWithoutApp.length}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...contactsWithoutApp.map((contactWithStatus) =>
              _buildContactCard(contactWithStatus, hasApp: false)),
        ],
      ],
    );
  }

  Widget _buildContactCard(ContactWithAppStatus contactWithStatus, {required bool hasApp}) {
    final contact = contactWithStatus.contact;
    final phoneNumber = contactWithStatus.phoneNumber;
    final initials = _getInitials(contact.displayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasApp ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          width: hasApp ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: hasApp ? Colors.green.withOpacity(0.2) : AppTheme.primaryNeon.withOpacity(0.2),
          child: contact.photo != null && contact.photo!.isNotEmpty
              ? ClipOval(
                  child: Image.memory(
                    contact.photo!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
              : Text(
                  initials,
                  style: TextStyle(
                    color: hasApp ? Colors.green : AppTheme.primaryNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          contact.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: phoneNumber != null
            ? Text(
                _formatPhoneNumber(phoneNumber),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              )
            : null,
        trailing: hasApp
            ? ElevatedButton.icon(
                onPressed: () => _playWithContact(contactWithStatus),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Play'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () => _inviteContact(contact),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Invite'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1)).toUpperCase();
  }

  String _formatPhoneNumber(String phone) {
    // Simple formatting - just show last 4 digits for privacy
    if (phone.length >= 4) {
      return '***-***-${phone.substring(phone.length - 4)}';
    }
    return phone;
  }
}

