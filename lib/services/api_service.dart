/// Main API Service - Centralized access to all API services
/// 
/// Usage:
/// ```dart
/// final api = ApiService();
/// final user = await api.user.getCurrentUser();
/// final questions = await api.questions.getPracticeQuestions();
/// ```

import 'api_client.dart';
import 'websocket_client.dart';
import 'api/auth_api_service.dart';
import 'api/user_api_service.dart';
import 'api/questions_api_service.dart';
import 'api/quiz_api_service.dart';
import 'api/campaign_api_service.dart';
import 'api/rooms_api_service.dart';
import 'api/leagues_api_service.dart';
import 'api/friends_api_service.dart';
import 'api/quests_api_service.dart';
import 'api/leaderboards_api_service.dart';
import 'api/rewards_api_service.dart';
import 'api/cards_api_service.dart';
import 'api/achievements_api_service.dart';
import 'api/education_api_service.dart';
import 'api/subscriptions_api_service.dart';
import 'api/notifications_api_service.dart';
import 'api/analytics_api_service.dart';
import 'api/system_api_service.dart';
import 'api/ads_api_service.dart';
import 'api/contacts_api_service.dart';

/// Main API Service class providing access to all API services
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // API Client
  final ApiClient client = ApiClient();
  
  // WebSocket Client
  final WebSocketClient ws = WebSocketClient();

  // API Services
  final AuthApiService auth = AuthApiService();
  final UserApiService user = UserApiService();
  final QuestionsApiService questions = QuestionsApiService();
  final QuizApiService quiz = QuizApiService();
  final CampaignApiService campaign = CampaignApiService();
  final RoomsApiService rooms = RoomsApiService();
  final LeaguesApiService leagues = LeaguesApiService();
  final FriendsApiService friends = FriendsApiService();
  final QuestsApiService quests = QuestsApiService();
  final LeaderboardsApiService leaderboards = LeaderboardsApiService();
  final RewardsApiService rewards = RewardsApiService();
  final CardsApiService cards = CardsApiService();
  final AchievementsApiService achievements = AchievementsApiService();
  final EducationApiService education = EducationApiService();
  final SubscriptionsApiService subscriptions = SubscriptionsApiService();
  final NotificationsApiService notifications = NotificationsApiService();
  final AnalyticsApiService analytics = AnalyticsApiService();
  final SystemApiService system = SystemApiService();
  final AdsApiService ads = AdsApiService();
  final ContactsApiService contacts = ContactsApiService();

  /// Initialize API client
  Future<void> initialize() async {
    await client.initialize();
  }

  /// Connect WebSocket
  Future<void> connectWebSocket() async {
    await ws.connect();
  }

  /// Disconnect WebSocket
  void disconnectWebSocket() {
    ws.disconnect();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => client.accessToken != null;

  /// Clear all authentication tokens
  Future<void> logout() async {
    await client.clearTokens();
  }
}

