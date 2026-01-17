import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/friend.dart';

/// Friend Service - Manages friends list, friend requests, and friend operations
/// Uses local storage (can be extended to backend later)
class FriendService extends ChangeNotifier {
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  List<Friend> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  bool _isInitialized = false;

  List<Friend> get friends => List.unmodifiable(_friends);
  List<FriendRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  int get friendsCount => _friends.length;
  int get pendingRequestsCount => _pendingRequests.length;

  /// Initialize and load friends from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadFriendsFromStorage();
      await _loadFriendRequestsFromStorage();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing FriendService: $e');
    }
  }

  /// Load friends from SharedPreferences
  Future<void> _loadFriendsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = prefs.getString('friends_list');
      
      if (friendsJson != null && friendsJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(friendsJson);
        _friends = decoded
            .map((json) => Friend.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Generate demo friends for testing
        _friends = _generateDemoFriends();
        await _saveFriendsToStorage();
      }
    } catch (e) {
      debugPrint('❌ Error loading friends: $e');
      _friends = [];
    }
  }

  /// Load friend requests from SharedPreferences
  Future<void> _loadFriendRequestsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getString('friend_requests');
      
      if (requestsJson != null && requestsJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(requestsJson);
        _pendingRequests = decoded
            .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error loading friend requests: $e');
      _pendingRequests = [];
    }
  }

  /// Save friends to SharedPreferences
  Future<void> _saveFriendsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = json.encode(
        _friends.map((f) => f.toJson()).toList(),
      );
      await prefs.setString('friends_list', friendsJson);
    } catch (e) {
      debugPrint('❌ Error saving friends: $e');
    }
  }

  /// Save friend requests to SharedPreferences
  Future<void> _saveFriendRequestsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = json.encode(
        _pendingRequests.map((r) => r.toJson()).toList(),
      );
      await prefs.setString('friend_requests', requestsJson);
    } catch (e) {
      debugPrint('❌ Error saving friend requests: $e');
    }
  }

  /// Get all friends
  Future<List<Friend>> getFriends() async {
    await initialize();
    return List.unmodifiable(_friends);
  }

  /// Get pending friend requests (incoming)
  Future<List<FriendRequest>> getPendingRequests() async {
    await initialize();
    return _pendingRequests
        .where((r) => r.status == FriendRequestStatus.pending)
        .toList();
  }

  /// Send friend request
  Future<bool> sendFriendRequest({
    required String toUserId,
    required String toUsername,
    String? toAvatarUrl,
  }) async {
    await initialize();
    
    // Check if already friends
    if (_friends.any((f) => f.userId == toUserId)) {
      return false;
    }
    
    // Check if request already exists
    if (_pendingRequests.any((r) => 
        r.toUserId == toUserId && r.status == FriendRequestStatus.pending)) {
      return false;
    }
    
    final request = FriendRequest(
      id: 'request_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: 'current_user', // Will be replaced with actual user ID
      fromUsername: toUsername,
      toUserId: toUserId,
      fromAvatarUrl: toAvatarUrl,
      createdAt: DateTime.now(),
    );
    
    _pendingRequests.add(request);
    await _saveFriendRequestsToStorage();
    notifyListeners();
    
    return true;
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    await initialize();
    
    final requestIndex = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return false;
    
    final request = _pendingRequests[requestIndex];
    
    // Create friendship
    final friend = Friend(
      id: 'friendship_${DateTime.now().millisecondsSinceEpoch}',
      userId: request.fromUserId,
      username: request.fromUsername,
      avatarUrl: request.fromAvatarUrl,
      createdAt: DateTime.now(),
      status: FriendStatus.accepted,
    );
    
    _friends.add(friend);
    
    // Remove request
    _pendingRequests.removeAt(requestIndex);
    
    await _saveFriendsToStorage();
    await _saveFriendRequestsToStorage();
    notifyListeners();
    
    return true;
  }

  /// Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    await initialize();
    
    final requestIndex = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return false;
    
    _pendingRequests.removeAt(requestIndex);
    await _saveFriendRequestsToStorage();
    notifyListeners();
    
    return true;
  }

  /// Remove friend
  Future<bool> removeFriend(String friendId) async {
    await initialize();
    
    final friendIndex = _friends.indexWhere((f) => f.id == friendId);
    if (friendIndex == -1) return false;
    
    _friends.removeAt(friendIndex);
    await _saveFriendsToStorage();
    notifyListeners();
    
    return true;
  }

  /// Generate demo friends for testing
  List<Friend> _generateDemoFriends() {
    final demoUsernames = [
      'Alex',
      'Sam',
      'Jordan',
      'Casey',
      'Riley',
      'Taylor',
      'Morgan',
      'Avery',
    ];
    
    return List.generate(5, (index) {
      return Friend(
        id: 'friend_$index',
        userId: 'user_$index',
        username: demoUsernames[index % demoUsernames.length],
        createdAt: DateTime.now().subtract(Duration(days: index)),
        lastActive: DateTime.now().subtract(Duration(minutes: index * 10)),
        totalScore: 10000 - (index * 500),
        gamesPlayed: 100 - (index * 5),
        level: 5 + index,
        accuracy: 0.75 + (index * 0.05),
        currentStreak: 3 + index,
        status: FriendStatus.accepted,
      );
    });
  }

  /// Refresh friends list (for backend integration)
  Future<void> refreshFriends() async {
    // TODO: Call backend API to refresh friends
    notifyListeners();
  }
}

