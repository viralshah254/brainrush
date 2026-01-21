import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

/// Service to track friend invites and manage rewards
class InviteService {
  static final InviteService _instance = InviteService._internal();
  factory InviteService() => _instance;
  InviteService._internal();

  static const String _inviteCountKey = 'friend_invites_sent';
  static const String _inviteRewardClaimedKey = 'friend_invites_reward_claimed';
  static const String _inviteLink = 'https://www.dvtechventures.com/download';
  static const int _requiredInvites = 5;
  static const int _rewardCoins = 500;

  /// Get number of invites sent
  Future<int> getInvitesSent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_inviteCountKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting invite count: $e');
      return 0;
    }
  }

  /// Check if reward has been claimed
  Future<bool> isRewardClaimed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_inviteRewardClaimedKey) ?? false;
    } catch (e) {
      debugPrint('❌ Error checking reward status: $e');
      return false;
    }
  }

  /// Check if user has reached the required invites
  Future<bool> hasReachedRequiredInvites() async {
    final invitesSent = await getInvitesSent();
    return invitesSent >= _requiredInvites;
  }

  /// Check if user can claim reward (has 5+ invites and hasn't claimed yet)
  Future<bool> canClaimReward() async {
    final hasReached = await hasReachedRequiredInvites();
    final hasClaimed = await isRewardClaimed();
    return hasReached && !hasClaimed;
  }

  /// Get remaining invites needed
  Future<int> getRemainingInvites() async {
    final invitesSent = await getInvitesSent();
    final remaining = _requiredInvites - invitesSent;
    return remaining > 0 ? remaining : 0;
  }

  /// Share invite link and track the invite
  Future<bool> shareInvite() async {
    try {
      final message = '''🎮 Join me on MindRush - The Thinking Game!

Test your knowledge across Math, Science, History, Geography, and more!

Download now: $_inviteLink

Let's compete and see who's smarter! 🧠✨''';

      final result = await Share.share(
        message,
        subject: 'Join me on MindRush!',
      );

      // Track the invite if sharing was successful
      // Note: Share.share doesn't guarantee the user actually shared,
      // but we'll track it when the share dialog is opened
      if (result.status == ShareResultStatus.success || 
          result.status == ShareResultStatus.dismissed) {
        // User opened the share dialog - count it as an invite sent
        await _incrementInviteCount();
        debugPrint('✅ Invite shared and tracked');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error sharing invite: $e');
      return false;
    }
  }

  /// Increment invite count
  Future<void> _incrementInviteCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_inviteCountKey) ?? 0;
      await prefs.setInt(_inviteCountKey, currentCount + 1);
      debugPrint('📊 Invite count: ${currentCount + 1}/$_requiredInvites');
    } catch (e) {
      debugPrint('❌ Error incrementing invite count: $e');
    }
  }

  /// Manually increment invite count (for testing or alternative tracking)
  Future<void> incrementInviteCount() async {
    await _incrementInviteCount();
  }

  /// Claim the reward (500 coins)
  Future<bool> claimReward() async {
    try {
      final canClaim = await canClaimReward();
      if (!canClaim) {
        debugPrint('❌ Cannot claim reward - requirements not met');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_inviteRewardClaimedKey, true);
      debugPrint('✅ Reward claimed: $_rewardCoins coins');
      return true;
    } catch (e) {
      debugPrint('❌ Error claiming reward: $e');
      return false;
    }
  }

  /// Get invite link
  String get inviteLink => _inviteLink;

  /// Get required invites
  int get requiredInvites => _requiredInvites;

  /// Get reward coins
  int get rewardCoins => _rewardCoins;

  /// Reset invite tracking (for testing)
  Future<void> resetInvites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_inviteCountKey);
      await prefs.remove(_inviteRewardClaimedKey);
      debugPrint('🔄 Invite tracking reset');
    } catch (e) {
      debugPrint('❌ Error resetting invites: $e');
    }
  }
}





