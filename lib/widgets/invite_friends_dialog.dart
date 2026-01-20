import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/invite_service.dart';
import '../providers/user_provider.dart';

/// Dialog shown after daily challenge completion to invite friends
class InviteFriendsDialog extends StatefulWidget {
  const InviteFriendsDialog({super.key});

  @override
  State<InviteFriendsDialog> createState() => _InviteFriendsDialogState();
}

class _InviteFriendsDialogState extends State<InviteFriendsDialog> {
  final InviteService _inviteService = InviteService();
  bool _isLoading = false;
  int _invitesSent = 0;
  int _remainingInvites = 5;
  bool _canClaimReward = false;
  bool _hasClaimedReward = false;

  @override
  void initState() {
    super.initState();
    _loadInviteStatus();
  }

  Future<void> _loadInviteStatus() async {
    final invitesSent = await _inviteService.getInvitesSent();
    final remaining = await _inviteService.getRemainingInvites();
    final canClaim = await _inviteService.canClaimReward();
    final hasClaimed = await _inviteService.isRewardClaimed();

    if (mounted) {
      setState(() {
        _invitesSent = invitesSent;
        _remainingInvites = remaining;
        _canClaimReward = canClaim;
        _hasClaimedReward = hasClaimed;
      });
    }
  }

  Future<void> _handleInvite() async {
    setState(() => _isLoading = true);
    
    final success = await _inviteService.shareInvite();
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        // Reload status
        await _loadInviteStatus();
        
        // Check if they can now claim reward
        if (_canClaimReward && !_hasClaimedReward) {
          _showRewardAvailable();
        } else if (_remainingInvites == 0) {
          _showRewardAvailable();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share invite. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _claimReward() async {
    final success = await _inviteService.claimReward();
    
    if (mounted && success) {
      final userProvider = context.read<UserProvider>();
      userProvider.addCoins(_inviteService.rewardCoins);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 +${_inviteService.rewardCoins} coins earned!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        await _loadInviteStatus();
      }
    }
  }

  void _showRewardAvailable() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reward Unlocked!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          'You\'ve invited 5 friends! Claim your ${_inviteService.rewardCoins} coins reward.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _claimReward();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              foregroundColor: AppTheme.darkBg,
            ),
            child: const Text('Claim Reward'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryNeon.withOpacity(0.2),
              AppTheme.successNeon.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryNeon.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people,
                size: 40,
                color: AppTheme.primaryNeon,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Invite Your Friends!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Invite 5 friends and get ${_inviteService.rewardCoins} coins!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            
            // Progress
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invites Sent',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '$_invitesSent / ${_inviteService.requiredInvites}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _invitesSent / _inviteService.requiredInvites,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _canClaimReward ? Colors.green : AppTheme.primaryNeon,
                      ),
                    ),
                  ),
                  if (_remainingInvites > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$_remainingInvites more to unlock reward',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            if (_canClaimReward && !_hasClaimedReward) ...[
              // Claim Reward Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _claimReward,
                  icon: const Icon(Icons.celebration),
                  label: Text(
                    'Claim ${_inviteService.rewardCoins} Coins',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (_hasClaimedReward) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Reward Claimed!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Invite Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleInvite,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.darkBg,
                        ),
                      )
                    : const Icon(Icons.share),
                label: Text(
                  _isLoading ? 'Sharing...' : 'Invite Friends',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNeon,
                  foregroundColor: AppTheme.darkBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Close Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


