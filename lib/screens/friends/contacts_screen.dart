import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
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
    // ignore: avoid_print
    print('📱 Contacts permission status: $hasPermission');
    
    if (!hasPermission) {
      // ignore: avoid_print
      print('❌ Contacts permission NOT granted');
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
      return;
    }

    // ignore: avoid_print
    print('✅ Contacts permission GRANTED');
    
    setState(() {
      _hasPermission = true;
    });

    // Simulate finding contacts with app (for demo)
    // In production, this would be a backend API call
    await _contactsService.simulateFindContactsWithApp();
    final allContacts = await _contactsService.getContactsWithAppStatus();
    
    // Filter to show ONLY contacts who have the game
    final contactsWithGame = allContacts.where((contact) => contact.hasApp).toList();
    
    // ignore: avoid_print
    print('📱 Total contacts: ${allContacts.length}');
    // ignore: avoid_print
    print('📱 Contacts with game: ${contactsWithGame.length}');
    // ignore: avoid_print
    print('📱 Showing only contacts who have the game');

    if (mounted) {
      setState(() {
        _contacts = contactsWithGame; // Only show contacts with app
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    if (!mounted) return;
    
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    // Check current permission status first
    final currentStatus = await _contactsService.getPermissionStatus();
    
    if (currentStatus == PermissionStatus.granted) {
      // Already granted - just load contacts
      await _loadContacts();
      return;
    }
    
    if (currentStatus == PermissionStatus.permanentlyDenied) {
      // Permanently denied - need to open settings
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Permission Required',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contacts permission was denied. To find friends who play MindRush, please enable contacts access in your device settings.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                'Would you like to open settings now?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: AppTheme.darkBg,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        final opened = await _contactsService.openSettings();
        if (opened && mounted) {
          // Wait a bit for user to return from settings, then check permission again
          await Future.delayed(const Duration(seconds: 1));
          await _loadContacts();
        }
      }
      return;
    }

    // Not granted and not permanently denied - request permission
    // This will show the system permission dialog
    final granted = await _contactsService.requestPermission();
    
    if (!mounted) return;
    
    if (granted) {
      // Permission granted - load contacts
      await _loadContacts();
      return;
    }

    // Permission denied (but not permanently) - show dialog to encourage retry
    setState(() {
      _isLoading = false;
      _hasPermission = false;
    });
    
    if (mounted) {
      // Show a more prominent dialog instead of just a snackbar
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Permission Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'To find friends who play MindRush, we need access to your contacts. This allows you to:\n\n'
            '• See which contacts are playing\n'
            '• Challenge friends to games\n'
            '• Compete with your network\n\n'
            'Your contacts are never shared or stored on our servers.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: AppTheme.darkBg,
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
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
    // Only show back button if we can pop (i.e., navigated via push, not from bottom nav)
    final canPop = Navigator.canPop(context);
    
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Find Friends'),
        backgroundColor: AppTheme.darkBg,
        automaticallyImplyLeading: canPop,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryNeon.withOpacity(0.2),
                      AppTheme.primaryNeon.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.contacts,
                  size: 60,
                  color: AppTheme.primaryNeon,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Access Contacts',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryNeon.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    _buildBenefitRow(
                      Icons.people,
                      'Find friends who play MindRush',
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitRow(
                      Icons.play_arrow,
                      'Challenge friends to games',
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitRow(
                      Icons.emoji_events,
                      'Compete and see who\'s the best',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestPermission,
                  icon: const Icon(Icons.contacts, size: 24),
                  label: const Text(
                    'Grant Permission',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your contacts are only used to find friends.\nWe never share your data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryNeon,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsList() {
    // Filter to show ONLY contacts who have the game
    final filtered = _filteredContacts.where((c) => c.hasApp).toList();
    
    // ignore: avoid_print
    print('📱 Displaying ${filtered.length} contacts (all have the game)');

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
        // Header showing only contacts with game
        if (filtered.isNotEmpty) ...[
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
                  '${filtered.length}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...filtered.map((contactWithStatus) =>
              _buildContactCard(contactWithStatus, hasApp: true)),
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

