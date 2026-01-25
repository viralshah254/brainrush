import '../api_client.dart';

/// Cards Collection API Service
class CardsApiService {
  final ApiClient _api = ApiClient();

  /// Get card collection
  Future<Map<String, dynamic>> getCardCollection() async {
    return await _api.get<Map<String, dynamic>>('/cards/collection');
  }

  /// Get available cards
  Future<List<dynamic>> getAvailableCards() async {
    return await _api.get<List<dynamic>>('/cards/available');
  }

  /// Unlock card
  Future<void> unlockCard(String cardId) async {
    await _api.post('/cards/$cardId/unlock');
  }

  /// Open card pack
  Future<Map<String, dynamic>> openCardPack() async {
    return await _api.post<Map<String, dynamic>>('/cards/pack/open');
  }

  /// Toggle card favorite
  Future<void> toggleCardFavorite(String cardId) async {
    await _api.put('/cards/$cardId/favorite');
  }

  /// Get collection stats
  Future<Map<String, dynamic>> getCollectionStats() async {
    return await _api.get<Map<String, dynamic>>('/cards/stats');
  }
}







