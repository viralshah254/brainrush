import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// WebSocket Client for real-time features
class WebSocketClient {
  static final WebSocketClient _instance = WebSocketClient._internal();
  factory WebSocketClient() => _instance;
  WebSocketClient._internal();

  IO.Socket? _socket;
  final ApiClient _apiClient = ApiClient();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_socket != null && _isConnected) {
      debugPrint('WebSocket already connected');
      return;
    }

    try {
      final token = _apiClient.accessToken;
      if (token == null) {
        throw Exception('No access token available');
      }

      _socket = IO.io(
        ApiClient.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      debugPrint('❌ Error connecting to WebSocket: $e');
      rethrow;
    }
  }

  /// Setup event listeners
  void _setupEventListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('✅ WebSocket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('❌ WebSocket disconnected');
    });

    _socket!.onError((error) {
      debugPrint('❌ WebSocket error: $error');
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ WebSocket connection error: $error');
      _isConnected = false;
    });
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      debugPrint('WebSocket disconnected');
    }
  }

  /// Join a room
  void joinRoom(String roomCode) {
    _socket?.emit('room:join', {'roomCode': roomCode});
  }

  /// Leave a room
  void leaveRoom(String roomCode) {
    _socket?.emit('room:leave', {'roomCode': roomCode});
  }

  /// Toggle ready status
  void toggleReady({required String roomCode, required bool ready}) {
    _socket?.emit('room:ready', {
      'roomCode': roomCode,
      'ready': ready,
    });
  }

  /// Start match (host only)
  void startMatch({required String roomCode, required String matchId}) {
    _socket?.emit('room:start_match', {
      'roomCode': roomCode,
      'matchId': matchId,
    });
  }

  /// Get time remaining
  void getTimeRemaining(String matchId) {
    _socket?.emit('room:get_time_remaining', {'matchId': matchId});
  }

  /// Get results
  void getResults({required String roomCode, required String matchId}) {
    _socket?.emit('room:get_results', {
      'roomCode': roomCode,
      'matchId': matchId,
    });
  }

  /// Update presence
  void updatePresence({required String status, String? activity}) {
    _socket?.emit('update_presence', {
      'status': status,
      if (activity != null) 'activity': activity,
    });
  }

  /// Ping server
  void ping() {
    _socket?.emit('ping');
  }

  // Event Listeners

  /// Listen to room joined event
  void onRoomJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:joined', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to participant joined event
  void onParticipantJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:participant_joined', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to participant left event
  void onParticipantLeft(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:participant_left', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to participant ready event
  void onParticipantReady(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:participant_ready', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to match started event
  void onMatchStarted(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:match_started', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to score update event
  void onScoreUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:score_update', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to match completed event
  void onMatchCompleted(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:match_completed', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to match expiring soon event
  void onMatchExpiringSoon(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:match_expiring_soon', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to time remaining event
  void onTimeRemaining(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:time_remaining', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to results event
  void onResults(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:results', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to friend online event
  void onFriendOnline(Function(Map<String, dynamic>) callback) {
    _socket?.on('friend_online', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to friend offline event
  void onFriendOffline(Function(Map<String, dynamic>) callback) {
    _socket?.on('friend_offline', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to friend presence update event
  void onFriendPresenceUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('friend_presence_update', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to pong event
  void onPong(Function(Map<String, dynamic>) callback) {
    _socket?.on('pong', (data) => callback(data as Map<String, dynamic>));
  }

  /// Listen to room error event
  void onRoomError(Function(Map<String, dynamic>) callback) {
    _socket?.on('room:error', (data) => callback(data as Map<String, dynamic>));
  }

  /// Remove all listeners for an event
  void off(String event) {
    _socket?.off(event);
  }

  /// Remove all listeners
  void clearListeners() {
    _socket?.clearListeners();
  }
}




