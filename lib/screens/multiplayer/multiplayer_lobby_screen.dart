import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import '../game_screen.dart';
import '../../providers/game_provider.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  final Room room;

  const MultiplayerLobbyScreen({
    super.key,
    required this.room,
  });

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen>
    with TickerProviderStateMixin {
  final _roomService = RoomService();
  late AnimationController _pulseController;
  Room? _currentRoom;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Poll for room updates every 2 seconds
    _pollRoomUpdates();
  }

  void _pollRoomUpdates() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      
      final room = await _roomService.getRoom(widget.room.code);
      if (room != null && mounted) {
        setState(() {
          _currentRoom = room;
        });
        _pollRoomUpdates();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoom == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isHost = _currentRoom!.hostId == _currentRoom!.players.first.userId;
    final allReady = _roomService.areAllPlayersReady(_currentRoom!);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Game Lobby'),
        backgroundColor: AppTheme.darkBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _leaveRoom(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Room code card
              _buildRoomCodeCard(),
              const SizedBox(height: 24),

              // Game settings
              _buildSettingsCard(),
              const SizedBox(height: 24),

              // Players list
              Expanded(
                child: _buildPlayersList(),
              ),
              const SizedBox(height: 24),

              // Start button (host only)
              if (isHost)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: allReady ? 1.0 + (_pulseController.value * 0.05) : 1.0,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: allReady && !_isStarting
                              ? _startGame
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allReady
                                ? AppTheme.primaryNeon
                                : Colors.grey,
                            foregroundColor: AppTheme.darkBg,
                            disabledBackgroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isStarting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.darkBg,
                                    ),
                                  ),
                                )
                              : Text(
                                  allReady
                                      ? 'Start Game 🚀'
                                      : 'Waiting for players...',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      'Waiting for host to start...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Room Code',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.darkBg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentRoom!.code,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBg,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.copy, color: AppTheme.darkBg),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _currentRoom!.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSettingItem('📚', 'Topic', _currentRoom!.topic),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildSettingItem(
            '👥',
            'Players',
            '${_currentRoom!.players.length}/${_currentRoom!.maxPlayers}',
          ),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildSettingItem('❓', 'Questions', '${_currentRoom!.totalQuestions}'),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNeon,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Players',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentRoom!.players.length}/${_currentRoom!.maxPlayers}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _currentRoom!.players.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final player = _currentRoom!.players[index];
                final isHost = index == 0;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: player.isReady
                        ? Colors.green.withOpacity(0.1)
                        : AppTheme.darkBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: player.isReady
                          ? Colors.green
                          : Colors.white10,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            player.username[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  player.username,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (isHost) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryNeon.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'HOST',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.primaryNeon,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              player.isReady ? 'Ready!' : 'Not ready',
                              style: TextStyle(
                                fontSize: 12,
                                color: player.isReady
                                    ? Colors.green
                                    : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Status icon
                      Icon(
                        player.isReady
                            ? Icons.check_circle
                            : Icons.schedule,
                        color: player.isReady
                            ? Colors.green
                            : Colors.white30,
                        size: 32,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startGame() async {
    setState(() => _isStarting = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          category: _currentRoom!.topic,
          questionCount: _currentRoom!.totalQuestions,
          mode: GameMode.multiplayer,
          roomCode: _currentRoom!.code,
        ),
      ),
    );
  }

  Future<void> _leaveRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text(
          'Leave Room?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to leave this room?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }
}

