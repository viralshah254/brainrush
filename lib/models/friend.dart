/// Friend model representing a user's friend relationship
class Friend {
  final String id; // Friendship ID
  final String userId; // Friend's user ID
  final String username;
  final String? avatarUrl;
  final DateTime createdAt; // When friendship was established
  final DateTime? lastActive; // Last time friend was active
  
  // Friend's stats
  final int totalScore;
  final int gamesPlayed;
  final int level;
  final double accuracy;
  final int currentStreak;
  
  // Status
  final FriendStatus status; // accepted, pending_incoming, pending_outgoing
  
  const Friend({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    this.lastActive,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.level = 1,
    this.accuracy = 0.0,
    this.currentStreak = 0,
    this.status = FriendStatus.accepted,
  });

  Friend copyWith({
    String? id,
    String? userId,
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastActive,
    int? totalScore,
    int? gamesPlayed,
    int? level,
    double? accuracy,
    int? currentStreak,
    FriendStatus? status,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      totalScore: totalScore ?? this.totalScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      level: level ?? this.level,
      accuracy: accuracy ?? this.accuracy,
      currentStreak: currentStreak ?? this.currentStreak,
      status: status ?? this.status,
    );
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
      totalScore: json['totalScore'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      status: json['status'] != null
          ? FriendStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['status'],
              orElse: () => FriendStatus.accepted,
            )
          : FriendStatus.accepted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'totalScore': totalScore,
      'gamesPlayed': gamesPlayed,
      'level': level,
      'accuracy': accuracy,
      'currentStreak': currentStreak,
      'status': status.toString().split('.').last,
    };
  }
  
  /// Check if friend is online (active within last 5 minutes)
  bool get isOnline {
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive!).inMinutes < 5;
  }
  
  /// Get formatted last active time
  String get lastActiveText {
    if (lastActive == null) return 'Never';
    final diff = DateTime.now().difference(lastActive!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

enum FriendStatus {
  accepted, // Friend request accepted, friendship active
  pendingIncoming, // Friend request received, waiting for user to accept
  pendingOutgoing, // Friend request sent, waiting for friend to accept
  blocked, // Friend is blocked
}

/// Friend Request model
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String? fromAvatarUrl;
  final String toUserId;
  final DateTime createdAt;
  final FriendRequestStatus status;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    this.fromAvatarUrl,
    required this.toUserId,
    required this.createdAt,
    this.status = FriendRequestStatus.pending,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUsername: json['fromUsername'] as String,
      fromAvatarUrl: json['fromAvatarUrl'] as String?,
      toUserId: json['toUserId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] != null
          ? FriendRequestStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['status'],
              orElse: () => FriendRequestStatus.pending,
            )
          : FriendRequestStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromAvatarUrl': fromAvatarUrl,
      'toUserId': toUserId,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}




