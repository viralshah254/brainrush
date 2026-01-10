import 'dart:math';
import '../models/room.dart';

class RoomService {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  final Random _random = Random();
  final Map<String, Room> _rooms = {};

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<Room> createRoom({
    required String hostId,
    required String hostUsername,
    required String topic,
    required int maxPlayers,
    required int totalQuestions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final code = _generateRoomCode();
    final room = Room(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      hostId: hostId,
      topic: topic,
      maxPlayers: maxPlayers,
      totalQuestions: totalQuestions,
      players: [
        RoomPlayer(
          userId: hostId,
          username: hostUsername,
          score: 0,
          isReady: true,
        ),
      ],
      isActive: true,
      createdAt: DateTime.now(),
    );

    _rooms[code] = room;
    return room;
  }

  Future<Room?> joinRoom({
    required String code,
    required String userId,
    required String username,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final room = _rooms[code];
    if (room == null) return null;

    if (room.players.length >= room.maxPlayers) {
      return null; // Room is full
    }

    if (room.players.any((p) => p.userId == userId)) {
      return room; // Already in room
    }

    final newPlayer = RoomPlayer(
      userId: userId,
      username: username,
      score: 0,
      isReady: false,
    );

    final updatedPlayers = [...room.players, newPlayer];
    final updatedRoom = room.copyWith(players: updatedPlayers);
    _rooms[code] = updatedRoom;

    return updatedRoom;
  }

  Future<Room?> getRoom(String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _rooms[code];
  }

  Future<bool> updatePlayerReady(String code, String userId, bool isReady) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final room = _rooms[code];
    if (room == null) return false;

    final updatedPlayers = room.players.map((p) {
      if (p.userId == userId) {
        return p.copyWith(isReady: isReady);
      }
      return p;
    }).toList();

    _rooms[code] = room.copyWith(players: updatedPlayers);
    return true;
  }

  Future<bool> updatePlayerScore(String code, String userId, int score) async {
    final room = _rooms[code];
    if (room == null) return false;

    final updatedPlayers = room.players.map((p) {
      if (p.userId == userId) {
        return p.copyWith(score: p.score + score);
      }
      return p;
    }).toList();

    _rooms[code] = room.copyWith(players: updatedPlayers);
    return true;
  }

  Future<bool> leaveRoom(String code, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final room = _rooms[code];
    if (room == null) return false;

    final updatedPlayers = room.players.where((p) => p.userId != userId).toList();

    if (updatedPlayers.isEmpty) {
      // Delete room if empty
      _rooms.remove(code);
    } else {
      // Update host if current host left
      String newHostId = room.hostId;
      if (room.hostId == userId && updatedPlayers.isNotEmpty) {
        newHostId = updatedPlayers.first.userId;
      }

      _rooms[code] = room.copyWith(
        hostId: newHostId,
        players: updatedPlayers,
      );
    }

    return true;
  }

  Future<bool> closeRoom(String code) async {
    _rooms.remove(code);
    return true;
  }

  bool areAllPlayersReady(Room room) {
    if (room.players.length < 2) return false;
    return room.players.every((p) => p.isReady);
  }
}

