import '../api_client.dart';

/// Contacts & Invites API Service
class ContactsApiService {
  final ApiClient _api = ApiClient();

  /// Upload contacts
  Future<Map<String, dynamic>> uploadContacts({
    required List<String> phoneNumbers,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/contacts/upload',
      body: {'phoneNumbers': phoneNumbers},
    );
  }

  /// Find friends from contacts
  Future<Map<String, dynamic>> findFriendsFromContacts({
    required List<String> phoneNumbers,
  }) async {
    return await _api.post<Map<String, dynamic>>(
      '/contacts/find-from-contacts',
      body: {'phoneNumbers': phoneNumbers},
    );
  }

  /// Get contact matches
  Future<List<dynamic>> getContactMatches() async {
    return await _api.get<List<dynamic>>('/contacts/matches');
  }

  /// Get invite status
  Future<Map<String, dynamic>> getInviteStatus() async {
    return await _api.get<Map<String, dynamic>>('/invites/status');
  }

  /// Get invite link
  Future<Map<String, dynamic>> getInviteLink() async {
    return await _api.get<Map<String, dynamic>>('/invites/link');
  }

  /// Track invite
  Future<Map<String, dynamic>> trackInvite() async {
    return await _api.post<Map<String, dynamic>>('/invites/track');
  }

  /// Claim invite reward
  Future<Map<String, dynamic>> claimInviteReward() async {
    return await _api.post<Map<String, dynamic>>('/invites/reward/claim');
  }
}




