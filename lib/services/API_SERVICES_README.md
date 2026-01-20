# API Services Documentation

## Overview

All backend API endpoints are now connected through a clean, centralized API service architecture.

## Architecture

```
lib/services/
├── api_client.dart          # Base HTTP client with smart features
├── api_service.dart         # Main service providing access to all APIs
└── api/
    ├── auth_api_service.dart
    ├── user_api_service.dart
    ├── questions_api_service.dart
    ├── quiz_api_service.dart
    ├── campaign_api_service.dart
    ├── rooms_api_service.dart
    ├── leagues_api_service.dart
    ├── friends_api_service.dart
    ├── quests_api_service.dart
    ├── leaderboards_api_service.dart
    ├── rewards_api_service.dart
    ├── cards_api_service.dart
    ├── achievements_api_service.dart
    ├── education_api_service.dart
    ├── subscriptions_api_service.dart
    ├── notifications_api_service.dart
    ├── analytics_api_service.dart
    ├── system_api_service.dart
    ├── ads_api_service.dart
    └── contacts_api_service.dart
```

## Usage

### Initialize API Service

```dart
import 'package:mindrush/services/api_service.dart';

// Initialize on app startup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final api = ApiService();
  await api.initialize();
  
  runApp(MyApp());
}
```

### Authentication

```dart
final api = ApiService();

// Sign up
try {
  final response = await api.auth.signUp(
    email: 'user@example.com',
    username: 'username',
    password: 'password123',
    provider: 'EMAIL',
    age: 18,
  );
  // Tokens are automatically saved
} catch (e) {
  print('Error: $e');
}

// Login
try {
  final response = await api.auth.login(
    email: 'user@example.com',
    password: 'password123',
  );
} catch (e) {
  print('Error: $e');
}

// OAuth Login
final googleResponse = await api.auth.loginWithGoogle(
  idToken: 'google_id_token',
);

// Guest account
final guestResponse = await api.auth.createGuestAccount();

// Logout
await api.auth.logout();
```

### User Management

```dart
final api = ApiService();

// Get current user
final user = await api.user.getCurrentUser();

// Update username
await api.user.updateUsername('new_username');

// Get user stats
final stats = await api.user.getUserStats();

// Get wallet
final wallet = await api.user.getWallet();

// Get user achievements
final achievements = await api.user.getUserAchievements();

// Get education profile
final education = await api.user.getEducationProfile();

// Get match history
final matches = await api.user.getMatchHistory(limit: 20, offset: 0);

// Get transaction history
final transactions = await api.user.getTransactionHistory(limit: 50, offset: 0);

// Save answered questions
await api.user.saveAnsweredQuestions(questionIds: ['id1', 'id2', 'id3']);

// Link social account
await api.user.linkSocialAccount(
  provider: 'GOOGLE',
  providerId: 'google_user_id',
  email: 'user@example.com',
);

// Unlink social account
await api.user.unlinkSocialAccount('GOOGLE');

// Update app mode
await api.user.updateAppMode('EDUCATION');

// Claim login reward
final reward = await api.user.claimLoginReward();

// Get free coins
final coins = await api.user.getFreeCoins(
  amount: 100,
  source: 'AD',
);

// Spin lucky wheel
final spin = await api.user.spinLuckyWheel(spinCost: 100);
```

### Questions & Quiz

```dart
final api = ApiService();

// Get practice questions
final questions = await api.questions.getPracticeQuestions(
  category: 'Math',
  questionCount: 10,
  gradeLevel: '10',
  excludeAnswered: true,
);

// Get education questions
final eduQuestions = await api.questions.getEducationQuestions(
  category: 'Math',
  questionCount: 10,
  gradeLevel: '10',
  examFocus: 'SAT',
);

// Get question bank
final bank = await api.questions.getQuestionBank(
  category: 'Math',
  limit: 50,
  offset: 0,
);

// Report question
await api.questions.reportQuestion(
  questionId: 'question_id',
  reason: 'Incorrect answer',
);

// Get session statistics
final stats = await api.questions.getSessionStatistics('session_id');

// Create new session
final session = await api.questions.createNewSession();

// Save answered questions
await api.questions.saveAnsweredQuestions(questionIds: ['id1', 'id2']);

// Get session history
final history = await api.questions.getSessionHistory(limit: 20, offset: 0);

// Get categories
final categories = await api.questions.getCategories();

// Quiz-specific endpoints (use quiz service)
final result = await api.quiz.submitAnswer(
  sessionId: 'session_id',
  questionId: 'question_id',
  selectedIndex: 2,
  timeRemaining: 5,
);

// Request extra time
final extraTime = await api.quiz.requestExtraTime(
  sessionId: 'session_id',
  adWatched: true,
);

// Try again
await api.quiz.tryAgain(
  sessionId: 'session_id',
  adWatched: true,
);

// Question timeout
final timeout = await api.quiz.questionTimeout(
  sessionId: 'session_id',
  questionId: 'question_id',
);

// Complete session
final completion = await api.quiz.completeSession(
  sessionId: 'session_id',
  score: 850,
  correctAnswers: 8,
  totalQuestions: 10,
  timeSpent: 120,
);
```

### Campaign Mode

```dart
final api = ApiService();

// Get all campaigns
final campaigns = await api.campaign.getAllCampaigns();

// Get campaign progress
final progress = await api.campaign.getCampaignProgress();

// Get campaign rounds
final rounds = await api.campaign.getCampaignRounds();

// Check round unlock status
final unlock = await api.campaign.checkRoundUnlockStatus('round_id');

// Get round results
final results = await api.campaign.getRoundResults('round_id');

// Get next round
final nextRound = await api.campaign.getNextRound('round_id');

// Replay round
final replay = await api.campaign.replayRound('round_id');

// Start round
final session = await api.campaign.startCampaignRound('round_id');

// Submit answer (alternative path)
final answer = await api.campaign.submitAnswer(
  roundId: 'round_id',
  questionId: 'question_id',
  selectedIndex: 2,
  timeRemaining: 5,
);

// Complete round (alternative path)
final result = await api.campaign.completeRound(
  roundId: 'round_id',
  score: 850,
  correctAnswers: 8,
  totalQuestions: 10,
  timeSpent: 120,
);
```

### Multiplayer Rooms

```dart
final api = ApiService();

// Create room
final room = await api.rooms.createRoom(
  category: 'Math',
  questionCount: 10,
  maxPlayers: 5,
  isPrivate: true,
  mode: 'GENERAL',
);

// Join room
final joinResult = await api.rooms.joinRoom('ABC123');

// Join room via invite token
final inviteJoin = await api.rooms.joinRoomViaInvite('invite_token');

// Join room lobby
final lobby = await api.rooms.joinRoomLobby('ABC123');

// Toggle ready
await api.rooms.toggleReady(
  roomCode: 'ABC123',
  ready: true,
);

// Start game (host only)
final match = await api.rooms.startGame('ABC123');
```

### Friends

```dart
final api = ApiService();

// Get friends
final friends = await api.friends.getFriends();

// Search users
final users = await api.friends.searchUsers(query: 'username');

// Send friend request
await api.friends.sendFriendRequest('user_id');

// Accept request
await api.friends.acceptFriendRequest('request_id');

// Get friends presence
final presence = await api.friends.getFriendsPresence();

// Update presence
await api.friends.updatePresence(
  status: 'PLAYING',
  activity: 'In a match',
);
```

### Leagues

```dart
final api = ApiService();

// Get all leagues
final leagues = await api.leagues.getAllLeagues();

// Get active leagues
final active = await api.leagues.getActiveLeagues();

// Join league
await api.leagues.joinLeague('league_id');

// Leave league
await api.leagues.leaveLeague('league_id');

// Get my rank
final rank = await api.leagues.getMyRank('league_id');

// Get education league by grade
final eduLeague = await api.leagues.getEducationLeagueByGrade('10');

// Start league match
final match = await api.leagues.startLeagueMatch('league_id');

// Get leaderboard
final leaderboard = await api.leagues.getLeagueLeaderboard(
  leagueId: 'league_id',
  limit: 100,
);

// Submit score
final result = await api.leagues.submitLeagueScore(
  leagueId: 'league_id',
  score: 850,
  correctAnswers: 8,
  totalQuestions: 10,
);
```

### Quests & Challenges

```dart
final api = ApiService();

// Get daily quests
final quests = await api.quests.getDailyQuests();

// Update quest progress
final progress = await api.quests.updateQuestProgress(
  questId: 'quest_id',
  questType: 'PLAY_GAMES',
  increment: 1,
);

// Claim quest reward
final reward = await api.quests.claimQuestReward('quest_id');

// Claim all quests bonus
final bonus = await api.quests.claimAllQuestsBonus();

// Get daily challenge status
final status = await api.quests.getDailyChallengeStatus();

// Get daily challenge questions
final challengeQuestions = await api.quests.getDailyChallengeQuestions();

// Get daily challenge reward
final challengeReward = await api.quests.getDailyChallengeReward();

// Get weekly challenges
final challenges = await api.quests.getWeeklyChallenges();

// Update weekly challenge progress
final weeklyProgress = await api.quests.updateWeeklyChallengeProgress(
  challengeId: 'challenge_id',
  challengeType: 'PLAY_GAMES',
  increment: 1,
);

// Claim weekly challenge reward
final weeklyReward = await api.quests.claimWeeklyChallengeReward('challenge_id');
```

### Leaderboards

```dart
final api = ApiService();

// Get global leaderboard
final global = await api.leaderboards.getGlobalLeaderboard(
  period: 'all',
  limit: 100,
);

// Get weekly leaderboard
final weekly = await api.leaderboards.getWeeklyLeaderboard();

// Get friends leaderboard
final friends = await api.leaderboards.getFriendsLeaderboard();
```

### Error Handling

All API methods throw `ApiException` on error:

```dart
try {
  final user = await api.user.getCurrentUser();
} on ApiException catch (e) {
  print('API Error: ${e.error.message}');
  print('Error Code: ${e.error.code}');
  print('Status Code: ${e.statusCode}');
} catch (e) {
  print('Unexpected error: $e');
}
```

### Response Format

All API responses follow the backend format:
```json
{
  "success": true,
  "data": { ... }
}
```

The API client automatically extracts the `data` field, so you receive the actual data directly.

### Token Management

Tokens are automatically managed:
- Saved on login/signup
- Added to all authenticated requests
- Refreshed automatically on 401 errors
- Cleared on logout

### Base URL Configuration

**Current Configuration:**
- API Base URL: `http://localhost:3000/api/v1`
- WebSocket URL: `ws://localhost:3000`

**To change to production:**
```dart
// In api_client.dart, change:
static const String baseUrl = 'https://api.mindrush.com/api/v1';
static const String wsUrl = 'wss://api.mindrush.com';
```

### WebSocket Usage

```dart
final api = ApiService();

// Connect WebSocket
await api.connectWebSocket();

// Join a room
api.ws.joinRoom('ABC123');

// Listen to events
api.ws.onMatchStarted((data) {
  print('Match started: $data');
});

api.ws.onScoreUpdate((data) {
  print('Score update: $data');
});

// Update presence
api.ws.updatePresence(
  status: 'PLAYING',
  activity: 'In a match',
);

// Disconnect when done
api.disconnectWebSocket();
```

## Available Services

- **AuthApiService** - Authentication & OAuth
- **UserApiService** - User profile, stats, wallet, rewards
- **QuestionsApiService** - Questions, quiz sessions
- **CampaignApiService** - Campaign mode
- **RoomsApiService** - Multiplayer rooms
- **LeaguesApiService** - Leagues & tournaments
- **FriendsApiService** - Friends & social features
- **QuestsApiService** - Daily quests & weekly challenges
- **LeaderboardsApiService** - All leaderboards
- **RewardsApiService** - Rewards system
- **CardsApiService** - Card collection
- **AchievementsApiService** - Achievements
- **EducationApiService** - Education mode
- **SubscriptionsApiService** - Premium subscriptions
- **NotificationsApiService** - Push notifications
- **AnalyticsApiService** - Analytics tracking
- **SystemApiService** - App info, version check, store

### Rewards

```dart
final api = ApiService();

// Get today's daily reward
final todayReward = await api.rewards.getTodaysDailyReward();

// Claim daily reward
final claimed = await api.rewards.claimDailyReward();

// Get daily reward calendar
final calendar = await api.rewards.getDailyRewardCalendar();

// Get available rewards
final available = await api.rewards.getAvailableRewards();

// Claim reward
await api.rewards.claimReward('reward_id');

// Get reward history
final history = await api.rewards.getRewardHistory(limit: 20, offset: 0);
```

### Ads & Monetization

```dart
final api = ApiService();

// Check ad eligibility
final eligible = await api.ads.checkAdEligibility();

// Record ad view
final adView = await api.ads.recordAdView(
  adUnitId: 'ca-app-pub-xxx/interstitial',
  adType: 'REWARDED',
  context: 'EXTRA_TIME',
  completed: true,
);

// Grant ad reward
final reward = await api.ads.grantAdReward(
  adViewId: 'ad_view_id',
  type: 'COINS',
  amount: 50,
);

// Watch try again ad
final tryAgain = await api.ads.watchTryAgainAd(
  adUnitId: 'ca-app-pub-xxx/rewarded',
  adWatched: true,
);

// Watch double points ad
final doublePoints = await api.ads.watchDoublePointsAd(
  adUnitId: 'ca-app-pub-xxx/rewarded',
  adWatched: true,
);
```

### Contacts & Invites

```dart
final api = ApiService();

// Upload contacts
final uploaded = await api.contacts.uploadContacts(
  phoneNumbers: ['+1234567890', '+0987654321'],
);

// Find friends from contacts
final matches = await api.contacts.findFriendsFromContacts(
  phoneNumbers: ['+1234567890'],
);

// Get contact matches
final contactMatches = await api.contacts.getContactMatches();

// Get invite status
final inviteStatus = await api.contacts.getInviteStatus();

// Get invite link
final inviteLink = await api.contacts.getInviteLink();

// Track invite
final tracked = await api.contacts.trackInvite();

// Claim invite reward
final inviteReward = await api.contacts.claimInviteReward();
```

### Education

```dart
final api = ApiService();

// Get education profile
final profile = await api.education.getEducationProfile();

// Update education profile
await api.education.updateEducationProfile(
  gradeLevel: '11',
  examFocus: 'GMAT',
  schoolSystem: 'US',
);

// Update education age
await api.education.updateEducationAge(16);

// Update challenge grade
await api.education.updateChallengeGrade('10');

// Update education grade
await api.education.updateEducationGrade('11');

// Update education school system
await api.education.updateEducationSchoolSystem('US');

// Update education exam
await api.education.updateEducationExam('SAT');
```

### Subscriptions

```dart
final api = ApiService();

// Get premium benefits
final benefits = await api.subscriptions.getPremiumBenefits();

// Purchase premium monthly
final monthly = await api.subscriptions.purchasePremiumMonthly(
  platform: 'ios',
  transactionId: 'transaction_123',
  receipt: 'receipt_data',
);

// Purchase premium yearly
final yearly = await api.subscriptions.purchasePremiumYearly(
  platform: 'ios',
  transactionId: 'transaction_123',
  receipt: 'receipt_data',
);

// Get SAT subscription info
final satInfo = await api.subscriptions.getSATSubscriptionInfo();

// Get GMAT subscription info
final gmatInfo = await api.subscriptions.getGMATSubscriptionInfo();

// Get education products
final products = await api.subscriptions.getEducationProducts();

// Purchase SAT subscription
final satPurchase = await api.subscriptions.purchaseSATSubscription(
  platform: 'ios',
  transactionId: 'transaction_123',
  receipt: 'receipt_data',
);

// Purchase GMAT subscription
final gmatPurchase = await api.subscriptions.purchaseGMATSubscription(
  platform: 'ios',
  transactionId: 'transaction_123',
  receipt: 'receipt_data',
);
```

### System & Help

```dart
final api = ApiService();

// Get contact information
final contact = await api.system.getContactInformation();

// Get about information
final about = await api.system.getAboutInformation();

// Get terms of service
final terms = await api.system.getTermsOfService();

// Get privacy policy
final privacy = await api.system.getPrivacyPolicy();

// Get available languages
final languages = await api.system.getAvailableLanguages();

// Get match results
final matchResults = await api.system.getMatchResults('match_id');

// Get match rankings
final rankings = await api.system.getMatchRankings('match_id');

// Share to social media
final share = await api.system.shareToSocialMedia(
  platform: 'FACEBOOK',
  content: 'I just scored 1000 points!',
  url: 'https://mindrush.com/share/abc123',
);

// Submit support ticket
final ticket = await api.system.submitSupportTicketNew(
  subject: 'Issue with login',
  message: 'I cannot log in...',
  category: 'TECHNICAL',
);

// Get purchase history
final purchases = await api.system.getPurchaseHistory();

// Purchase item
final purchase = await api.system.purchaseItem(
  itemId: 'item_id',
  paymentMethod: 'STRIPE',
);
```

## Smart Features

### Response Caching

The API client automatically caches GET requests to reduce redundant API calls:

```dart
final api = ApiService();

// Cached request (default TTL: 5 minutes)
final user = await api.user.getCurrentUser(); // First call - hits API
final user2 = await api.user.getCurrentUser(); // Second call - returns cached

// Custom cache TTL
final questions = await api.questions.getPracticeQuestions(
  category: 'Math',
  questionCount: 10,
); // Uses default 5-minute cache

// Disable caching for specific request
final freshData = await api.user.getCurrentUser(); // useCache: false

// Clear cache manually
api.client.clearCache();
```

**Cache Features:**
- Automatic caching of GET requests
- Configurable TTL per request
- LRU eviction when cache is full (max 100 entries)
- Automatic invalidation on POST/PUT/DELETE to related endpoints
- Memory-based cache (fast access)

### Automatic Retry

Failed requests are automatically retried with exponential backoff:

```dart
// Automatically retries on:
// - Network errors (SocketException, TimeoutException)
// - 5xx server errors
// - Max 3 retries with exponential backoff (1s, 2s, 4s)

final user = await api.user.getCurrentUser();
// If network error occurs, automatically retries up to 3 times
```

**Retry Configuration:**
- Default: 3 retries
- Exponential backoff: 1s → 2s → 4s
- Only retries on network errors and 5xx responses
- Configurable per request

### Request Deduplication

Prevents duplicate concurrent requests:

```dart
// If multiple widgets call the same endpoint simultaneously,
// only one request is made and all callers receive the same result

Future<void> loadUser() async {
  // Multiple calls to same endpoint = single request
  final user1 = api.user.getCurrentUser();
  final user2 = api.user.getCurrentUser();
  final user3 = api.user.getCurrentUser();
  
  // All three futures resolve to the same result
  await Future.wait([user1, user2, user3]);
}
```

### Offline Support & Request Queue

Requests are automatically queued when offline and processed when connection is restored:

```dart
// When offline:
try {
  await api.user.updateUsername('new_username');
} on ApiException catch (e) {
  if (e.error.code == 'OFFLINE') {
    print('Request queued for later');
  }
}

// When connection is restored, queued requests are automatically processed
// Priority: auth (0) > user actions (1) > analytics (2)
```

**Queue Features:**
- Automatic queueing when offline
- Persistent storage in SharedPreferences
- Priority-based processing (auth first, then user actions, then analytics)
- Automatic retry when connection restored
- Manual queue management available

### Request/Response Interceptors

Add custom logic to requests and responses:

```dart
final api = ApiService();

// Add request interceptor (e.g., for analytics)
api.client.addRequestInterceptor((method, endpoint, body, headers) async {
  // Log request
  debugPrint('📤 $method $endpoint');
  
  // Add custom header
  headers['X-Request-ID'] = 'unique_id';
  
  return headers;
});

// Add response interceptor (e.g., for error tracking)
api.client.addResponseInterceptor((method, endpoint, response) async {
  if (response.statusCode >= 400) {
    // Track error
    await api.analytics.trackError(
      error: 'API Error',
      message: response.body,
      properties: {'endpoint': endpoint},
    );
  }
});
```

### Enhanced Error Handling

Improved error messages and connectivity detection:

```dart
try {
  final user = await api.user.getCurrentUser();
} on ApiException catch (e) {
  // Detailed error information
  print('Error Code: ${e.error.code}');
  print('Error Message: ${e.error.message}');
  print('Field: ${e.error.field}'); // If validation error
  
  // Validation errors array
  if (e.error.validationErrors != null) {
    for (final error in e.error.validationErrors!) {
      print('${error['path']}: ${error['message']}');
    }
  }
  
  // Status code
  print('Status: ${e.statusCode}');
}
```

**Error Features:**
- Network connectivity detection
- Detailed validation error messages
- Field-level error information
- Better error recovery suggestions
- Automatic offline queueing

### Connection Pooling & Optimization

Optimized HTTP client with connection pooling:

```dart
// The API client uses a persistent HTTP client with:
// - Connection pooling (reuses connections)
// - Keep-alive connections
// - Optimized for mobile networks
// - Automatic timeout handling

// No configuration needed - works automatically!
```

## Available Services

- **AuthApiService** - Authentication & OAuth
- **UserApiService** - User profile, stats, wallet, rewards, achievements, history
- **QuestionsApiService** - Questions, quiz sessions, question bank
- **QuizApiService** - Quiz-specific endpoints (submit answer, extra time, try again, timeout, complete)
- **CampaignApiService** - Campaign mode with all round operations
- **RoomsApiService** - Multiplayer rooms with invite support
- **LeaguesApiService** - Leagues & tournaments with education support
- **FriendsApiService** - Friends & social features
- **QuestsApiService** - Daily quests & weekly challenges
- **LeaderboardsApiService** - All leaderboards
- **RewardsApiService** - Rewards system with daily rewards
- **CardsApiService** - Card collection
- **AchievementsApiService** - Achievements
- **EducationApiService** - Education mode with profile management
- **SubscriptionsApiService** - Premium subscriptions (monthly/yearly, SAT/GMAT)
- **NotificationsApiService** - Push notifications
- **AnalyticsApiService** - Analytics tracking
- **SystemApiService** - App info, version check, store, help, legal
- **AdsApiService** - Ad monetization
- **ContactsApiService** - Contacts discovery & invites

## Implementation Status

✅ **All 181 endpoints implemented**
✅ **Response caching with TTL and LRU eviction**
✅ **Automatic retry with exponential backoff**
✅ **Request deduplication**
✅ **Offline support with request queue**
✅ **Enhanced error handling**
✅ **Request/response interceptors**
✅ **Connection pooling & optimization**
✅ **Type-safe response models**

