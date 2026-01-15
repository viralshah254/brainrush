import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/room_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/out_of_coins_dialog.dart';
import '../multiplayer/multiplayer_lobby_screen.dart';

class PlayWithFriendsScreen extends StatefulWidget {
  const PlayWithFriendsScreen({super.key});

  @override
  State<PlayWithFriendsScreen> createState() => _PlayWithFriendsScreenState();
}

class _PlayWithFriendsScreenState extends State<PlayWithFriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  final _roomService = RoomService();
  
  String _selectedTopic = 'Math';
  int _maxPlayers = 3;
  int _totalQuestions = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Play With Friends'),
        backgroundColor: AppTheme.darkBg,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryNeon,
          tabs: const [
            Tab(text: 'Create Room'),
            Tab(text: 'Join Room'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(),
          _buildJoinTab(),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    final topics = ['Math', 'Science', 'History', 'Geography', 'Literature'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create a Room',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your game and share the code with friends',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 32),

          // Topic Selection
          const Text(
            'Topic',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topics.map((topic) {
              final isSelected = _selectedTopic == topic;
              return ChoiceChip(
                label: Text(topic),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedTopic = topic),
                backgroundColor: AppTheme.darkCard,
                selectedColor: AppTheme.primaryNeon,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.darkBg : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Max Players
          const Text(
            'Max Players',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              final players = index + 2;
              final isSelected = _maxPlayers == players;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  child: ChoiceChip(
                    label: Center(child: Text('$players')),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _maxPlayers = players),
                    backgroundColor: AppTheme.darkCard,
                    selectedColor: AppTheme.primaryNeon,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.darkBg : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Questions Count
          const Text(
            'Number of Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [5, 10, 15, 20].map((count) {
              final isSelected = _totalQuestions == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Center(child: Text('$count')),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _totalQuestions = count),
                    backgroundColor: AppTheme.darkCard,
                    selectedColor: AppTheme.primaryNeon,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.darkBg : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          // Create Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: AppTheme.darkBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Room',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Join a Room',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the 6-digit code shared by your friend',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 8,
            ),
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: AppTheme.darkCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryNeon),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryNeon, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Join Room',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    if (user == null) return;

    // Check if user has enough coins (50 coins entry fee)
    const entryCost = 50;
    if (!userProvider.hasEnoughCoins(entryCost)) {
      _showInsufficientCoinsDialog(entryCost);
      return;
    }

    // Deduct entry fee
    userProvider.spendCoins(entryCost);

    try {
      final room = await _roomService.createRoom(
        hostId: user.id,
        hostUsername: user.username,
        topic: _selectedTopic,
        maxPlayers: _maxPlayers,
        totalQuestions: _totalQuestions,
      );

      if (!mounted) return;

      // Navigate to lobby
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiplayerLobbyScreen(room: room),
        ),
      );
    } catch (e) {
      // Refund coins if room creation failed
      userProvider.addCoins(entryCost);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating room: $e')),
      );
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    if (user == null) return;

    // Check if user has enough coins (50 coins entry fee)
    const entryCost = 50;
    if (!userProvider.hasEnoughCoins(entryCost)) {
      _showInsufficientCoinsDialog(entryCost);
      return;
    }

    // Deduct entry fee
    userProvider.spendCoins(entryCost);

    try {
      final room = await _roomService.joinRoom(
        code: code,
        userId: user.id,
        username: user.username,
      );

      if (room == null) {
        // Refund coins if room not found
        userProvider.addCoins(entryCost);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room not found or is full')),
        );
        return;
      }

      if (!mounted) return;

      // Navigate to lobby
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiplayerLobbyScreen(room: room),
        ),
      );
    } catch (e) {
      // Refund coins on error
      userProvider.addCoins(entryCost);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining room: $e')),
      );
    }
  }

  void _showInsufficientCoinsDialog(int required) {
    // Show the unified out of coins dialog
    showOutOfCoinsDialog(context);
  }
}

