# 🚀 Brainz Rush - Complete Backend API Specification

**Generated:** January 11, 2026  
**Flutter Project:** Brainz Rush Mobile App  
**Purpose:** Comprehensive mapping of every screen, feature, and user action to required backend endpoints

---

## 📋 Table of Contents

1. [Authentication & Onboarding](#1-authentication--onboarding)
2. [Home & Navigation](#2-home--navigation)
3. [Quiz Gameplay](#3-quiz-gameplay)
4. [Campaign Mode](#4-campaign-mode)
5. [Friends & Multiplayer](#5-friends--multiplayer)
6. [Leagues & Leaderboards](#6-leagues--leaderboards)
7. [Profile & User Management](#7-profile--user-management)
8. [Education Mode](#8-education-mode)
9. [Monetization](#9-monetization)
10. [System & Infrastructure](#10-system--infrastructure)
11. [Database Schema](#11-database-schema)

---

## 1. Authentication & Onboarding

### **Screen: `splash_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Check auth status | `/auth/session` | GET | No | REST | `users`, `sessions` |
| Load user profile | `/users/me` | GET | Yes | REST | `users`, `user_stats` |

**Entities:**
- `users` (id, username, email, createdAt, lastLogin)
- `sessions` (id, userId, token, expiresAt)
- `user_stats` (userId, totalGames, wins, coins, streakCount)

---

### **Screen: `onboarding_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Sign up (Email) | `/auth/signup` | POST | No | REST | `users`, `auth_providers` |
| Sign up (Google) | `/auth/google` | POST | No | REST | `users`, `auth_providers`, `oauth_tokens` |
| Sign up (Facebook) | `/auth/facebook` | POST | No | REST | `users`, `auth_providers`, `oauth_tokens` |
| Sign up (Apple) | `/auth/apple` | POST | No | REST | `users`, `auth_providers`, `oauth_tokens` |
| Create guest account | `/auth/guest` | POST | No | REST | `users` |
| Set username | `/users/me/username` | PUT | Yes | REST | `users` |
| Set age | `/users/me/age` | PUT | Yes | REST | `users` |

**Entities:**
- `users` (id, username, email, age, isGuest, createdAt)
- `auth_providers` (userId, provider, providerId, email)
- `oauth_tokens` (userId, provider, accessToken, refreshToken, expiresAt)

---

## 2. Home & Navigation

### **Screen: `main_navigation.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load navigation state | `/users/me/preferences` | GET | Yes | REST | `user_preferences` |
| Update last active tab | `/users/me/preferences` | PUT | Yes | REST | `user_preferences` |

**Entities:**
- `user_preferences` (userId, lastActiveTab, notifications, theme)

---

### **Screen: `home_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load user stats | `/users/me/stats` | GET | Yes | REST | `user_stats` |
| Load daily challenge status | `/challenges/daily/status` | GET | Yes | REST | `daily_challenges`, `user_challenges` |
| Load app mode | `/users/me/preferences` | GET | Yes | REST | `user_preferences` |
| Switch mode (General/Education) | `/users/me/mode` | PUT | Yes | REST | `users`, `user_preferences` |
| Check premium status | `/subscriptions/me` | GET | Yes | REST | `subscriptions` |
| Load education config | `/users/me/education` | GET | Yes | REST | `users`, `education_profiles` |
| Load coins balance | `/users/me/wallet` | GET | Yes | REST | `user_wallets` |
| Load streak count | `/users/me/streak` | GET | Yes | REST | `user_streaks` |

**Entities:**
- `user_stats` (userId, totalGames, wins, losses, totalScore, avgAccuracy)
- `daily_challenges` (id, date, questionIds, difficulty)
- `user_challenges` (userId, challengeId, completed, score, completedAt)
- `user_preferences` (userId, appMode, educationMode, notifications)
- `subscriptions` (userId, productId, status, expiresAt)
- `education_profiles` (userId, age, schoolSystem, gradeLevel, examFocus)
- `user_wallets` (userId, coins, lives, hints, buffs)
- `user_streaks` (userId, currentStreak, longestStreak, lastPlayDate)

---

## 3. Quiz Gameplay

### **Screen: `game_screen.dart`**

#### **Game Initialization**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Fetch questions (Practice) | `/questions/practice` | POST | Yes | REST | `questions`, `user_answered_questions` |
| Fetch questions (Daily) | `/challenges/daily/questions` | GET | Yes | REST | `daily_challenges`, `questions` |
| Fetch questions (Campaign) | `/campaign/rounds/{roundId}/questions` | GET | Yes | REST | `campaign_rounds`, `questions` |
| Fetch questions (Friends) | `/rooms/{roomCode}/questions` | GET | Yes | WebSocket | `rooms`, `questions` |
| Fetch questions (League) | `/leagues/{leagueId}/match/questions` | GET | Yes | WebSocket | `leagues`, `league_matches`, `questions` |
| Fetch questions (Education) | `/questions/education` | POST | Yes | REST | `questions`, `education_profiles` |

**Request Body (Practice/Education):**
```json
{
  "category": "Math",
  "questionCount": 10,
  "mode": "PRACTICE",
  "gradeLevel": "GRADE_11",
  "examFocus": "SAT",
  "excludeAnswered": true
}
```

**Response:**
```json
{
  "sessionId": "uuid",
  "questions": [
    {
      "id": "q123",
      "text": "What is 2+2?",
      "options": ["2", "3", "4", "5"],
      "correctIndex": 2,
      "explanation": "2+2 equals 4",
      "category": "Math",
      "difficulty": "easy",
      "timeLimit": 15
    }
  ],
  "expiresAt": "2026-01-11T13:00:00Z"
}
```

---

#### **During Gameplay**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Submit answer | `/quiz/sessions/{sessionId}/answer` | POST | Yes | REST | `quiz_sessions`, `user_answers` |
| Request extra time | `/quiz/sessions/{sessionId}/extra-time` | POST | Yes | REST | `quiz_sessions`, `ad_views` |
| Watch "Try Again" ad | `/ads/rewarded/try-again` | POST | Yes | REST | `ad_views`, `ad_rewards` |
| Skip question (timeout) | `/quiz/sessions/{sessionId}/timeout` | POST | Yes | REST | `quiz_sessions`, `user_answers` |
| Sync multiplayer state | `ws://api.brainzrush.com/rooms/{roomCode}` | WebSocket | Yes | Real-time | `rooms`, `room_participants`, `match_states` |

**Submit Answer Request:**
```json
{
  "questionId": "q123",
  "selectedIndex": 2,
  "timeRemaining": 8,
  "isRetry": false
}
```

**Submit Answer Response:**
```json
{
  "correct": true,
  "correctIndex": 2,
  "pointsEarned": 120,
  "timeBonus": 40,
  "explanation": "2+2 equals 4",
  "nextQuestion": {
    "id": "q124",
    "text": "What is 3+3?"
  }
}
```

**Extra Time Request:**
```json
{
  "adUnitId": "ca-app-pub-xxx",
  "adWatched": true
}
```

---

#### **Game Completion**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Submit game results | `/quiz/sessions/{sessionId}/complete` | POST | Yes | REST | `quiz_sessions`, `user_stats`, `user_wallets` |
| Get daily reward | `/challenges/daily/reward` | GET | Yes | REST | `daily_rewards`, `user_wallets` |
| Update streak | `/users/me/streak` | PUT | Yes | REST | `user_streaks` |
| Save answered questions | `/users/me/answered-questions` | POST | Yes | REST | `user_answered_questions` |

**Complete Game Request:**
```json
{
  "score": 850,
  "correctAnswers": 8,
  "totalQuestions": 10,
  "timeSpent": 120,
  "answers": [
    {
      "questionId": "q123",
      "selectedIndex": 2,
      "correct": true,
      "timeRemaining": 8
    }
  ]
}
```

**Complete Game Response:**
```json
{
  "finalScore": 850,
  "coinsEarned": 170,
  "dailyReward": {
    "type": "COINS",
    "amount": 50,
    "dayOfWeek": 1,
    "description": "50 Coins"
  },
  "newStreak": 5,
  "accuracy": 80.0,
  "rank": "Excellent"
}
```

**Entities:**
- `questions` (id, text, options, correctIndex, category, difficulty, mode, gradeLevel)
- `quiz_sessions` (id, userId, mode, category, startedAt, completedAt, score)
- `user_answers` (id, sessionId, questionId, selectedIndex, correct, timeRemaining)
- `user_answered_questions` (userId, questionId, answeredAt)
- `ad_views` (userId, adUnitId, type, viewedAt, rewarded)
- `ad_rewards` (userId, type, amount, grantedAt)

---

### **Screen: `results_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load detailed stats | `/quiz/sessions/{sessionId}/stats` | GET | Yes | REST | `quiz_sessions`, `user_answers` |
| Share results | `/social/share` | POST | Yes | REST | `shared_results`, `social_feeds` |
| Play again | `/quiz/sessions/new` | POST | Yes | REST | `quiz_sessions` |

**Entities:**
- `shared_results` (id, userId, sessionId, platform, sharedAt)
- `social_feeds` (id, userId, type, content, createdAt)

---

## 4. Campaign Mode

### **Screen: `campaign_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load campaign progress | `/campaign/progress` | GET | Yes | REST | `campaign_progress`, `campaign_rounds` |
| Load all rounds (500) | `/campaign/rounds` | GET | Yes | REST | `campaign_rounds` |
| Check round unlock status | `/campaign/rounds/{roundId}/unlock` | GET | Yes | REST | `campaign_progress`, `campaign_rounds` |

**Response:**
```json
{
  "currentRound": 15,
  "totalRounds": 500,
  "rounds": [
    {
      "roundNumber": 1,
      "category": "Math",
      "difficulty": "easy",
      "questionCount": 10,
      "isUnlocked": true,
      "stars": 3,
      "highScore": 950
    }
  ]
}
```

---

### **Screen: `campaign_game_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Start round | `/campaign/rounds/{roundId}/start` | POST | Yes | REST | `campaign_progress`, `quiz_sessions` |
| Submit answer (with ads) | `/campaign/rounds/{roundId}/answer` | POST | Yes | REST | `user_answers`, `ad_views` |
| Watch "Double Points" ad | `/ads/rewarded/double-points` | POST | Yes | REST | `ad_views`, `ad_rewards` |
| Complete round | `/campaign/rounds/{roundId}/complete` | POST | Yes | REST | `campaign_progress`, `user_wallets` |

**Complete Round Response:**
```json
{
  "roundNumber": 15,
  "score": 850,
  "stars": 2,
  "coinsEarned": 85,
  "nextRoundUnlocked": true,
  "nextRoundNumber": 16
}
```

---

### **Screen: `campaign_results_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load round results | `/campaign/rounds/{roundId}/results` | GET | Yes | REST | `campaign_progress`, `quiz_sessions` |
| Replay round | `/campaign/rounds/{roundId}/replay` | POST | Yes | REST | `campaign_progress` |
| Continue to next round | `/campaign/rounds/{roundId}/next` | GET | Yes | REST | `campaign_rounds` |

**Entities:**
- `campaign_rounds` (id, roundNumber, category, difficulty, questionCount, minStars)
- `campaign_progress` (userId, roundId, completed, score, stars, highScore)

---

## 5. Friends & Multiplayer

### **Screen: `friends_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load friends list | `/friends/list` | GET | Yes | REST | `friendships`, `users` |
| Search users | `/users/search` | GET | Yes | REST | `users` |
| Send friend request | `/friends/request` | POST | Yes | REST | `friend_requests` |
| Accept friend request | `/friends/request/{requestId}/accept` | PUT | Yes | REST | `friend_requests`, `friendships` |
| Decline friend request | `/friends/request/{requestId}/decline` | PUT | Yes | REST | `friend_requests` |
| Remove friend | `/friends/{userId}/remove` | DELETE | Yes | REST | `friendships` |
| Get online status | `ws://api.brainzrush.com/presence` | WebSocket | Yes | Real-time | `user_presence` |
| Invite friend to play | `/friends/{userId}/invite` | POST | Yes | REST | `game_invites` |

**Entities:**
- `friendships` (id, userId, friendId, createdAt)
- `friend_requests` (id, fromUserId, toUserId, status, createdAt)
- `user_presence` (userId, status, lastSeen, currentActivity)
- `game_invites` (id, fromUserId, toUserId, roomCode, expiresAt)

---

### **Screen: `play_with_friends_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Create room | `/rooms/create` | POST | Yes | REST | `rooms`, `room_participants` |
| Join room (by code) | `/rooms/{roomCode}/join` | POST | Yes | REST | `rooms`, `room_participants` |
| Join room (by invite link) | `/rooms/join/{inviteToken}` | POST | Yes | REST | `rooms`, `room_participants` |
| Leave room | `/rooms/{roomCode}/leave` | POST | Yes | REST | `room_participants` |
| Update room settings | `/rooms/{roomCode}/settings` | PUT | Yes | REST | `rooms` |
| Kick player (host only) | `/rooms/{roomCode}/kick/{userId}` | POST | Yes | REST | `room_participants` |

**Create Room Request:**
```json
{
  "category": "Math",
  "questionCount": 10,
  "maxPlayers": 5,
  "isPrivate": true,
  "mode": "EDUCATION_SAT"
}
```

**Create Room Response:**
```json
{
  "roomCode": "ABC123",
  "inviteLink": "https://brainzrush.com/join/xyz789",
  "hostId": "user123",
  "settings": {
    "category": "Math",
    "questionCount": 10,
    "maxPlayers": 5
  }
}
```

---

### **Screen: `multiplayer_lobby_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Connect to room | `ws://api.brainzrush.com/rooms/{roomCode}` | WebSocket | Yes | Real-time | `rooms`, `room_participants` |
| Send chat message | WebSocket event | - | Yes | Real-time | `room_messages` |
| Ready/Unready | WebSocket event | - | Yes | Real-time | `room_participants` |
| Start game (host) | WebSocket event | - | Yes | Real-time | `rooms`, `match_sessions` |
| Sync player list | WebSocket event | - | Yes | Real-time | `room_participants` |

**WebSocket Events:**
```typescript
// Client → Server
{
  "event": "player_ready",
  "userId": "user123",
  "ready": true
}

// Server → All Clients
{
  "event": "player_state_changed",
  "userId": "user123",
  "ready": true,
  "players": [...]
}

// Host starts game
{
  "event": "game_start",
  "matchId": "match456",
  "questions": [...]
}
```

---

### **Screen: `multiplayer_results_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load match results | `/matches/{matchId}/results` | GET | Yes | REST | `match_sessions`, `match_participants` |
| Load player rankings | `/matches/{matchId}/rankings` | GET | Yes | REST | `match_participants` |
| Rematch | `/rooms/{roomCode}/rematch` | POST | Yes | REST | `rooms`, `match_sessions` |
| Return to lobby | `/rooms/{roomCode}/lobby` | POST | Yes | REST | `rooms` |

**Entities:**
- `rooms` (id, code, hostId, status, category, questionCount, maxPlayers, createdAt)
- `room_participants` (id, roomId, userId, ready, joinedAt)
- `room_messages` (id, roomId, userId, message, sentAt)
- `match_sessions` (id, roomCode, status, startedAt, completedAt)
- `match_participants` (id, matchId, userId, score, rank, answersCorrect)

---

## 6. Leagues & Leaderboards

### **Screen: `leagues_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load active leagues | `/leagues/active` | GET | Yes | REST | `leagues`, `league_participants` |
| Load league tiers | `/leagues/tiers` | GET | Yes | REST | `league_tiers` |
| Join league | `/leagues/{leagueId}/join` | POST | Yes | REST | `league_participants` |
| Leave league | `/leagues/{leagueId}/leave` | POST | Yes | REST | `league_participants` |
| Load leaderboard | `/leagues/{leagueId}/leaderboard` | GET | Yes | REST | `league_participants`, `league_scores` |
| Load user rank | `/leagues/{leagueId}/rank/me` | GET | Yes | REST | `league_participants` |
| Load education grade league | `/leagues/education/grade/{gradeLevel}` | GET | Yes | REST | `leagues`, `league_participants` |

**Response:**
```json
{
  "leagues": [
    {
      "id": "league123",
      "name": "Bronze League",
      "tier": "BRONZE",
      "startDate": "2026-01-06",
      "endDate": "2026-01-12",
      "participants": 1000,
      "prizePool": 5000,
      "status": "ACTIVE"
    }
  ],
  "userLeague": {
    "leagueId": "league123",
    "rank": 45,
    "score": 8500,
    "matchesPlayed": 8
  }
}
```

---

### **League Match Flow**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Start league match | `/leagues/{leagueId}/match/start` | POST | Yes | WebSocket | `league_matches`, `match_sessions` |
| Submit match results | `/leagues/{leagueId}/match/{matchId}/complete` | POST | Yes | REST | `league_matches`, `league_scores` |
| Update leaderboard | Auto-triggered | - | - | Real-time | `league_scores`, `league_participants` |

**Entities:**
- `leagues` (id, name, tier, startDate, endDate, prizePool, status, gradeLevel)
- `league_tiers` (id, name, minRank, maxRank, entryFee, rewards)
- `league_participants` (id, leagueId, userId, rank, score, matchesPlayed, joinedAt)
- `league_matches` (id, leagueId, userId, score, rank, completedAt)
- `league_scores` (userId, leagueId, totalScore, matchesPlayed, highestRank)

---

## 7. Profile & User Management

### **Screen: `profile_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load user profile | `/users/me` | GET | Yes | REST | `users`, `user_stats` |
| Load achievements | `/users/me/achievements` | GET | Yes | REST | `user_achievements`, `achievements` |
| Load match history | `/users/me/matches` | GET | Yes | REST | `match_sessions`, `quiz_sessions` |
| Update profile photo | `/users/me/photo` | PUT | Yes | REST | `users`, `media_uploads` |
| Update username | `/users/me/username` | PUT | Yes | REST | `users` |
| Update preferences | `/users/me/preferences` | PUT | Yes | REST | `user_preferences` |
| Link social account | `/users/me/social/link` | POST | Yes | REST | `auth_providers` |
| Unlink social account | `/users/me/social/{provider}/unlink` | DELETE | Yes | REST | `auth_providers` |
| Upgrade guest to full account | `/auth/guest/upgrade` | POST | Yes | REST | `users`, `auth_providers` |
| Delete account | `/users/me` | DELETE | Yes | REST | `users` (soft delete) |
| Load coins/wallet | `/users/me/wallet` | GET | Yes | REST | `user_wallets` |
| Load transaction history | `/users/me/transactions` | GET | Yes | REST | `wallet_transactions` |

**Entities:**
- `users` (id, username, email, photoUrl, age, country, createdAt, deletedAt)
- `user_achievements` (userId, achievementId, unlockedAt, progress)
- `achievements` (id, name, description, icon, requirement)
- `media_uploads` (id, userId, url, type, uploadedAt)
- `wallet_transactions` (id, userId, type, amount, reason, createdAt)

---

## 8. Education Mode

### **Screen: `education_settings_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load education profile | `/education/profile` | GET | Yes | REST | `education_profiles` |
| Update age | `/education/profile/age` | PUT | Yes | REST | `education_profiles` |
| Update school system | `/education/profile/school-system` | PUT | Yes | REST | `education_profiles` |
| Update grade level | `/education/profile/grade` | PUT | Yes | REST | `education_profiles` |
| Update challenge grade | `/education/profile/challenge-grade` | PUT | Yes | REST | `education_profiles` |
| Select exam focus | `/education/profile/exam` | PUT | Yes | REST | `education_profiles` |
| Check SAT subscription | `/subscriptions/education/sat` | GET | Yes | REST | `subscriptions` |
| Check GMAT subscription | `/subscriptions/education/gmat` | GET | Yes | REST | `subscriptions` |

**Update Profile Request:**
```json
{
  "age": 17,
  "schoolSystem": "US",
  "gradeLevel": "GRADE_11",
  "challengeGradeLevel": "GRADE_12",
  "examFocus": "SAT"
}
```

---

### **Screen: `education_paywall_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load subscription products | `/subscriptions/education/products` | GET | Yes | REST | `subscription_products` |
| Purchase SAT subscription | `/subscriptions/education/sat/purchase` | POST | Yes | REST | `subscriptions`, `payments` |
| Purchase GMAT subscription | `/subscriptions/education/gmat/purchase` | POST | Yes | REST | `subscriptions`, `payments` |
| Restore purchases | `/subscriptions/restore` | POST | Yes | REST | `subscriptions` |

**Entities:**
- `education_profiles` (userId, age, country, schoolSystem, gradeLevel, challengeGradeLevel, examFocus)
- `subscription_products` (id, productId, name, price, duration, features)
- `payments` (id, userId, productId, amount, status, transactionId, createdAt)

---

## 9. Monetization

### **Screen: `premium_screen.dart`**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load premium benefits | `/subscriptions/premium/benefits` | GET | No | REST | `subscription_products` |
| Purchase monthly | `/subscriptions/premium/monthly` | POST | Yes | REST | `subscriptions`, `payments` |
| Purchase yearly | `/subscriptions/premium/yearly` | POST | Yes | REST | `subscriptions`, `payments` |
| Check subscription status | `/subscriptions/me` | GET | Yes | REST | `subscriptions` |
| Cancel subscription | `/subscriptions/me/cancel` | POST | Yes | REST | `subscriptions` |
| Restore purchases | `/subscriptions/restore` | POST | Yes | REST | `subscriptions` |

**Purchase Request:**
```json
{
  "productId": "premium_monthly",
  "platform": "ios",
  "receipt": "base64_receipt_data",
  "transactionId": "apple_transaction_id"
}
```

**Purchase Response:**
```json
{
  "subscriptionId": "sub123",
  "status": "ACTIVE",
  "expiresAt": "2026-02-11T00:00:00Z",
  "features": ["AD_FREE", "UNLIMITED_HINTS", "DOUBLE_XP", "EXCLUSIVE_CONTENT"]
}
```

---

### **Ad Monetization**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Record ad view | `/ads/view` | POST | Yes | REST | `ad_views` |
| Grant ad reward | `/ads/reward` | POST | Yes | REST | `ad_rewards`, `user_wallets` |
| Check ad eligibility | `/ads/eligible` | GET | Yes | REST | `ad_views`, `subscriptions` |

**Record Ad View Request:**
```json
{
  "adUnitId": "ca-app-pub-xxx",
  "adType": "REWARDED",
  "context": "TRY_AGAIN",
  "completed": true
}
```

**Grant Reward Response:**
```json
{
  "rewardType": "EXTRA_TIME",
  "amount": 10,
  "granted": true
}
```

**Entities:**
- `subscriptions` (id, userId, productId, status, startDate, expiresAt, autoRenew)
- `ad_views` (id, userId, adUnitId, type, context, completed, viewedAt)
- `ad_rewards` (id, userId, type, amount, source, grantedAt)

---

## 10. System & Infrastructure

### **Daily Rewards System**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get today's reward | `/rewards/daily/today` | GET | Yes | REST | `daily_rewards` |
| Claim daily reward | `/rewards/daily/claim` | POST | Yes | REST | `user_rewards`, `user_wallets` |
| Load reward calendar | `/rewards/daily/calendar` | GET | Yes | REST | `daily_rewards`, `user_rewards` |
| Claim daily login reward | `/users/me/login-reward` | POST | Yes | REST | `user_rewards`, `user_wallets` |
| Claim free coins (4-hour cooldown) | `/users/me/free-coins` | POST | Yes | REST | `user_wallets`, `wallet_transactions` |
| Spin lucky wheel (once per day) | `/users/me/lucky-spin` | POST | Yes | REST | `user_wallets`, `wallet_transactions` |

**Entities:**
- `daily_rewards` (id, dayOfWeek, type, amount, description)
- `user_rewards` (userId, rewardId, claimed, claimedAt)
- `wallet_transactions` (id, userId, type, amount, reason, createdAt)

---

### **Question Management**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Load question bank | `/questions/bank` | GET | Yes | REST | `questions` |
| Generate AI questions | `/questions/generate` | POST | Admin | REST | `questions`, `ai_generations` |
| Validate question | `/questions/{questionId}/validate` | POST | Admin | REST | `questions`, `question_validations` |
| Report question | `/questions/{questionId}/report` | POST | Yes | REST | `question_reports` |
| Load daily pool | `/questions/daily-pool` | GET | Yes | REST | `daily_question_pools`, `questions` |

**Generate AI Questions Request:**
```json
{
  "category": "Math",
  "difficulty": "medium",
  "gradeLevel": "GRADE_11",
  "count": 100,
  "mode": "EDUCATION_SAT"
}
```

**Entities:**
- `questions` (id, text, options, correctIndex, category, difficulty, mode, gradeLevel, source, validated)
- `ai_generations` (id, category, difficulty, count, status, generatedAt)
- `question_validations` (id, questionId, status, validatorId, validatedAt)
- `question_reports` (id, questionId, userId, reason, reportedAt)
- `daily_question_pools` (id, date, mode, gradeLevel, questionIds)

---

### **Notifications**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Register device | `/notifications/device` | POST | Yes | REST | `push_devices` |
| Update preferences | `/notifications/preferences` | PUT | Yes | REST | `notification_preferences` |
| Send push notification | `/notifications/send` | POST | Admin | REST | `notifications`, `notification_deliveries` |
| Load notification history | `/notifications/history` | GET | Yes | REST | `notifications` |
| Mark as read | `/notifications/{notificationId}/read` | PUT | Yes | REST | `notifications` |

**Entities:**
- `push_devices` (id, userId, deviceToken, platform, active, registeredAt)
- `notification_preferences` (userId, dailyReminder, friendRequests, leagueUpdates, quietHours)
- `notifications` (id, userId, type, title, body, read, sentAt)
- `notification_deliveries` (id, notificationId, deviceId, status, deliveredAt)

---

### **Daily Quests System**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get daily quests | `/quests/daily` | GET | Yes | REST | `daily_quests`, `user_quest_progress` |
| Update quest progress | `/quests/daily/{questId}/progress` | POST | Yes | REST | `user_quest_progress` |
| Claim quest reward | `/quests/daily/{questId}/claim` | POST | Yes | REST | `user_quest_progress`, `user_wallets` |
| Claim all quests bonus | `/quests/daily/bonus/claim` | POST | Yes | REST | `user_wallets`, `wallet_transactions` |

**Request Body (Update Progress):**
```json
{
  "questType": "PLAY_GAMES" | "ANSWER_CORRECTLY" | "COMPLETE_DAILY_CHALLENGE" | "PLAY_WITH_FRIENDS",
  "increment": 1
}
```

**Response (Get Daily Quests):**
```json
{
  "quests": [
    {
      "id": "quest_123",
      "type": "PLAY_GAMES",
      "title": "Play 3 Games",
      "description": "Complete 3 games in any mode",
      "currentValue": 2,
      "targetValue": 3,
      "coinReward": 100,
      "isCompleted": false,
      "isClaimed": false
    }
  ],
  "allQuestsBonus": {
    "available": true,
    "amount": 200,
    "claimed": false
  }
}
```

**Entities:**
- `daily_quests` (id, type, title, description, targetValue, coinReward, dayOfWeek)
- `user_quest_progress` (userId, questId, currentValue, isCompleted, isClaimed, updatedAt)

---

### **Weekly Challenges System**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get weekly challenges | `/challenges/weekly` | GET | Yes | REST | `weekly_challenges`, `user_weekly_progress` |
| Update challenge progress | `/challenges/weekly/{challengeId}/progress` | POST | Yes | REST | `user_weekly_progress` |
| Claim challenge reward | `/challenges/weekly/{challengeId}/claim` | POST | Yes | REST | `user_weekly_progress`, `user_wallets` |

**Response:**
```json
{
  "weekStartDate": "2026-01-13T00:00:00Z",
  "weekEndDate": "2026-01-19T23:59:59Z",
  "challenges": [
    {
      "id": "challenge_123",
      "title": "Game Marathon",
      "description": "Play 20 games this week",
      "emoji": "🎮",
      "targetValue": 20,
      "currentProgress": 12,
      "coinReward": 300,
      "xpReward": 100,
      "isCompleted": false
    }
  ]
}
```

**Entities:**
- `weekly_challenges` (id, title, description, targetValue, coinReward, xpReward, weekStartDate)
- `user_weekly_progress` (userId, challengeId, currentProgress, isCompleted, isClaimed, weekStartDate)

---

### **Card Collection System**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get user's card collection | `/cards/collection` | GET | Yes | REST | `user_cards`, `collectible_cards` |
| Get available cards | `/cards/available` | GET | Yes | REST | `collectible_cards` |
| Unlock card | `/cards/{cardId}/unlock` | POST | Yes | REST | `user_cards`, `collectible_cards` |
| Open card pack | `/cards/pack/open` | POST | Yes | REST | `user_cards`, `wallet_transactions` |
| Toggle card favorite | `/cards/{cardId}/favorite` | PUT | Yes | REST | `user_cards` |
| Get collection stats | `/cards/stats` | GET | Yes | REST | `user_cards`, `collectible_cards` |

**Response (Get Collection):**
```json
{
  "collected": [
    {
      "id": "math_basics",
      "name": "Math Basics",
      "emoji": "🔢",
      "category": "MATH",
      "rarity": "COMMON",
      "quantity": 1,
      "obtainedAt": "2026-01-11T10:00:00Z",
      "isFavorite": false
    }
  ],
  "missing": [...],
  "stats": {
    "total": 20,
    "collected": 8,
    "completion": 40.0,
    "byRarity": {
      "COMMON": 5,
      "RARE": 2,
      "EPIC": 1,
      "LEGENDARY": 0
    }
  }
}
```

**Entities:**
- `collectible_cards` (id, name, description, emoji, category, rarity, unlockCondition, unlockValue, isEducationMode)
- `user_cards` (userId, cardId, quantity, obtainedAt, isFavorite)

---

### **Achievements System**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get user achievements | `/achievements` | GET | Yes | REST | `user_achievements`, `achievements` |
| Get achievement details | `/achievements/{achievementId}` | GET | Yes | REST | `achievements`, `user_achievements` |
| Check achievement progress | `/achievements/{achievementId}/progress` | GET | Yes | REST | `user_achievements` |

**Response:**
```json
{
  "achievements": [
    {
      "id": "ach_123",
      "name": "First Steps",
      "description": "Complete your first game",
      "icon": "👣",
      "category": "GAMEPLAY",
      "progress": 1,
      "requirement": 1,
      "unlocked": true,
      "unlockedAt": "2026-01-10T12:00:00Z",
      "points": 10
    }
  ],
  "totalPoints": 150,
  "unlockedCount": 5,
  "totalCount": 25
}
```

**Entities:**
- `achievements` (id, name, description, icon, category, requirement, points)
- `user_achievements` (userId, achievementId, progress, unlocked, unlockedAt)

---

### **Friend Invites & Referrals**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get invite status | `/invites/status` | GET | Yes | REST | `user_invites` |
| Track invite sent | `/invites/track` | POST | Yes | REST | `user_invites` |
| Claim invite reward | `/invites/reward/claim` | POST | Yes | REST | `user_invites`, `user_wallets` |
| Get referral link | `/invites/link` | GET | Yes | REST | `user_invites` |

**Response (Get Status):**
```json
{
  "invitesSent": 3,
  "requiredInvites": 5,
  "remainingInvites": 2,
  "rewardAvailable": false,
  "rewardClaimed": false,
  "rewardAmount": 500,
  "inviteLink": "https://mindrush.com/invite/ABC123"
}
```

**Entities:**
- `user_invites` (userId, invitesSent, rewardClaimed, rewardClaimedAt, inviteCode)

---

### **Contacts & Friend Discovery**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Find friends from contacts | `/friends/find-from-contacts` | POST | Yes | REST | `user_contacts`, `users` |
| Upload contacts (hashed) | `/contacts/upload` | POST | Yes | REST | `user_contacts` |
| Get contact matches | `/contacts/matches` | GET | Yes | REST | `user_contacts`, `users` |

**Request Body (Find from Contacts):**
```json
{
  "phoneNumbers": [
    "+1234567890",
    "+0987654321"
  ]
}
```

**Response:**
```json
{
  "matches": [
    {
      "phoneNumber": "+1234567890",
      "userId": "user_uuid",
      "username": "Alex",
      "avatarUrl": "https://...",
      "isFriend": false,
      "hasPendingRequest": false
    }
  ],
  "totalMatches": 1
}
```

**Privacy Notes:**
- Phone numbers must be hashed before storage/comparison
- Only return users who opted into contact discovery
- Rate limit: 100 phone numbers per request

**Entities:**
- `user_contacts` (userId, hashedPhoneNumber, matchedUserId, discoveredAt)

---

### **Version Check & App Updates**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Check app version | `/app/version-check` | GET | No | REST | `app_versions` |
| Get force update status | `/app/force-update` | GET | No | REST | `app_versions` |

**Response:**
```json
{
  "currentVersion": "1.0.3",
  "latestVersion": "1.0.4",
  "forceUpdate": false,
  "updateUrl": {
    "ios": "https://apps.apple.com/app/id...",
    "android": "https://play.google.com/store/apps/details?id=..."
  },
  "releaseNotes": "Bug fixes and performance improvements"
}
```

**Entities:**
- `app_versions` (version, platform, forceUpdate, releaseNotes, releaseDate)

---

### **Language & Localization**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get available languages | `/languages` | GET | No | REST | `supported_languages` |
| Update user language | `/users/me/language` | PUT | Yes | REST | `user_preferences` |

**Response:**
```json
{
  "languages": [
    {
      "code": "en",
      "name": "English",
      "nativeName": "English"
    },
    {
      "code": "es",
      "name": "Spanish",
      "nativeName": "Español"
    }
  ],
  "defaultLanguage": "en"
}
```

**Entities:**
- `supported_languages` (code, name, nativeName, enabled)
- `user_preferences` (userId, language, ...)

---

### **Help & Support**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get FAQ | `/help/faq` | GET | No | REST | `faq_items` |
| Submit support ticket | `/help/ticket` | POST | Yes | REST | `support_tickets` |
| Get support email | `/help/contact` | GET | No | REST | - |

**Request Body (Submit Ticket):**
```json
{
  "subject": "Question about coins",
  "message": "How do I earn more coins?",
  "category": "GENERAL" | "TECHNICAL" | "BILLING" | "FEATURE_REQUEST"
}
```

**Entities:**
- `faq_items` (id, question, answer, category, order)
- `support_tickets` (id, userId, subject, message, category, status, createdAt)

---

### **About & Legal**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get app info | `/about` | GET | No | REST | - |
| Get terms & privacy | `/legal/terms` | GET | No | REST | - |
| Get privacy policy | `/legal/privacy` | GET | No | REST | - |

**Response:**
```json
{
  "appName": "MindRush",
  "version": "1.0.3",
  "developer": "DV Tech Ventures",
  "copyright": "© 2026 DV Tech Ventures",
  "termsUrl": "https://www.dvtechventures.com/TandCs",
  "privacyUrl": "https://www.dvtechventures.com/Privacy"
}
```

---

### **Coin Store**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Get coin packages | `/store/coins/packages` | GET | Yes | REST | `coin_packages` |
| Purchase coins | `/store/coins/purchase` | POST | Yes | REST | `coin_packages`, `payments`, `user_wallets` |
| Get purchase history | `/store/purchases` | GET | Yes | REST | `payments` |

**Response (Get Packages):**
```json
{
  "packages": [
    {
      "id": "coins_100",
      "name": "100 Coins",
      "coins": 100,
      "price": 0.99,
      "currency": "USD",
      "bonus": 0,
      "popular": false
    },
    {
      "id": "coins_500",
      "name": "500 Coins",
      "coins": 500,
      "price": 4.99,
      "currency": "USD",
      "bonus": 50,
      "popular": true
    }
  ]
}
```

**Entities:**
- `coin_packages` (id, name, coins, price, currency, bonus, popular, active)

---

### **Analytics & Telemetry**

| Action | Endpoint | Method | Auth | Real-time | Database Entities |
|--------|----------|--------|------|-----------|-------------------|
| Track event | `/analytics/event` | POST | Yes | REST | `analytics_events` |
| Track screen view | `/analytics/screen` | POST | Yes | REST | `analytics_screens` |
| Track performance | `/analytics/performance` | POST | Yes | REST | `analytics_performance` |
| Track error | `/analytics/error` | POST | Yes | REST | `error_logs` |

**Track Event Request:**
```json
{
  "event": "question_answered",
  "properties": {
    "questionId": "q123",
    "correct": true,
    "timeRemaining": 8,
    "mode": "DAILY",
    "category": "Math"
  },
  "timestamp": "2026-01-11T12:34:56Z"
}
```

**Entities:**
- `analytics_events` (id, userId, event, properties, timestamp)
- `analytics_screens` (id, userId, screen, duration, timestamp)
- `analytics_performance` (id, userId, metric, value, timestamp)
- `error_logs` (id, userId, error, stackTrace, context, timestamp)

---

## 11. Database Schema

### **Core User Tables**

```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255),
  photo_url TEXT,
  age INTEGER,
  country VARCHAR(2),
  is_guest BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP,
  deleted_at TIMESTAMP
);

-- Auth Providers
CREATE TABLE auth_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  provider VARCHAR(20) NOT NULL, -- 'EMAIL', 'GOOGLE', 'FACEBOOK', 'APPLE'
  provider_id VARCHAR(255),
  email VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(provider, provider_id)
);

-- Sessions
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  token VARCHAR(255) UNIQUE NOT NULL,
  device_info JSONB,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User Stats
CREATE TABLE user_stats (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  total_games INTEGER DEFAULT 0,
  wins INTEGER DEFAULT 0,
  losses INTEGER DEFAULT 0,
  total_score BIGINT DEFAULT 0,
  avg_accuracy DECIMAL(5,2) DEFAULT 0,
  total_time_played INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User Wallets
CREATE TABLE user_wallets (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  coins INTEGER DEFAULT 100,
  lives INTEGER DEFAULT 0,
  hints INTEGER DEFAULT 0,
  buffs JSONB DEFAULT '{}',
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User Streaks
CREATE TABLE user_streaks (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_play_date DATE,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User Preferences
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  app_mode VARCHAR(20) DEFAULT 'GENERAL', -- 'GENERAL', 'EDUCATION'
  theme VARCHAR(20) DEFAULT 'DARK',
  notifications JSONB DEFAULT '{"enabled": true}',
  last_active_tab VARCHAR(20),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

### **Question Tables**

```sql
-- Questions
CREATE TABLE questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  text TEXT NOT NULL,
  options JSONB NOT NULL, -- ["Option 1", "Option 2", "Option 3", "Option 4"]
  correct_index INTEGER NOT NULL,
  explanation TEXT,
  category VARCHAR(50) NOT NULL,
  difficulty VARCHAR(20) NOT NULL, -- 'easy', 'medium', 'hard', 'super_hard'
  topic VARCHAR(50),
  mode VARCHAR(50) DEFAULT 'GENERAL', -- 'GENERAL', 'EDUCATION_SCHOOL', 'EDUCATION_SAT', 'EDUCATION_GMAT'
  grade_level VARCHAR(20),
  source VARCHAR(20) DEFAULT 'AI', -- 'AI', 'CURATED'
  validated BOOLEAN DEFAULT false,
  language VARCHAR(5) DEFAULT 'EN',
  country_tag VARCHAR(10),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_questions_category ON questions(category);
CREATE INDEX idx_questions_mode_grade ON questions(mode, grade_level);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);

-- User Answered Questions
CREATE TABLE user_answered_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  question_id UUID REFERENCES questions(id),
  answered_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, question_id)
);

CREATE INDEX idx_user_answered ON user_answered_questions(user_id, answered_at);

-- Daily Question Pools
CREATE TABLE daily_question_pools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  mode VARCHAR(50) NOT NULL,
  grade_level VARCHAR(20),
  question_ids UUID[] NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(date, mode, grade_level)
);
```

---

### **Game Session Tables**

```sql
-- Quiz Sessions
CREATE TABLE quiz_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  mode VARCHAR(20) NOT NULL, -- 'PRACTICE', 'DAILY', 'CAMPAIGN', 'FRIENDS', 'LEAGUE'
  category VARCHAR(50),
  question_count INTEGER NOT NULL,
  score INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  started_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  time_spent INTEGER
);

CREATE INDEX idx_quiz_sessions_user ON quiz_sessions(user_id, completed_at);

-- User Answers
CREATE TABLE user_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES quiz_sessions(id),
  question_id UUID REFERENCES questions(id),
  selected_index INTEGER,
  correct BOOLEAN NOT NULL,
  time_remaining INTEGER,
  is_retry BOOLEAN DEFAULT false,
  answered_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_answers_session ON user_answers(session_id);
```

---

### **Campaign Tables**

```sql
-- Campaign Rounds
CREATE TABLE campaign_rounds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  round_number INTEGER UNIQUE NOT NULL,
  category VARCHAR(50) NOT NULL,
  difficulty VARCHAR(20) NOT NULL,
  question_count INTEGER NOT NULL,
  min_score_for_stars JSONB DEFAULT '{"1": 300, "2": 600, "3": 900}',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Campaign Progress
CREATE TABLE campaign_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  round_id UUID REFERENCES campaign_rounds(id),
  completed BOOLEAN DEFAULT false,
  score INTEGER DEFAULT 0,
  stars INTEGER DEFAULT 0,
  high_score INTEGER DEFAULT 0,
  completed_at TIMESTAMP,
  UNIQUE(user_id, round_id)
);

CREATE INDEX idx_campaign_progress_user ON campaign_progress(user_id, round_id);
```

---

### **Multiplayer Tables**

```sql
-- Rooms
CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(10) UNIQUE NOT NULL,
  host_id UUID REFERENCES users(id),
  status VARCHAR(20) DEFAULT 'WAITING', -- 'WAITING', 'PLAYING', 'FINISHED'
  category VARCHAR(50),
  question_count INTEGER NOT NULL,
  max_players INTEGER DEFAULT 5,
  is_private BOOLEAN DEFAULT true,
  mode VARCHAR(50) DEFAULT 'GENERAL',
  created_at TIMESTAMP DEFAULT NOW(),
  started_at TIMESTAMP,
  expires_at TIMESTAMP
);

-- Room Participants
CREATE TABLE room_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES rooms(id),
  user_id UUID REFERENCES users(id),
  ready BOOLEAN DEFAULT false,
  joined_at TIMESTAMP DEFAULT NOW(),
  left_at TIMESTAMP,
  UNIQUE(room_id, user_id)
);

-- Match Sessions
CREATE TABLE match_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code VARCHAR(10) REFERENCES rooms(code),
  status VARCHAR(20) DEFAULT 'ACTIVE',
  question_ids UUID[] NOT NULL,
  started_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP
);

-- Match Participants
CREATE TABLE match_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID REFERENCES match_sessions(id),
  user_id UUID REFERENCES users(id),
  score INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  rank INTEGER,
  completed_at TIMESTAMP,
  UNIQUE(match_id, user_id)
);
```

---

### **Friends Tables**

```sql
-- Friendships
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  friend_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, friend_id),
  CHECK (user_id != friend_id)
);

CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);

-- Friend Requests
CREATE TABLE friend_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID REFERENCES users(id),
  to_user_id UUID REFERENCES users(id),
  status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'ACCEPTED', 'DECLINED'
  created_at TIMESTAMP DEFAULT NOW(),
  responded_at TIMESTAMP,
  UNIQUE(from_user_id, to_user_id)
);

-- User Presence
CREATE TABLE user_presence (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  status VARCHAR(20) DEFAULT 'OFFLINE', -- 'ONLINE', 'OFFLINE', 'PLAYING'
  current_activity VARCHAR(50),
  last_seen TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

### **League Tables**

```sql
-- Leagues
CREATE TABLE leagues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  tier VARCHAR(20) NOT NULL, -- 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'DIAMOND'
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  prize_pool INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'UPCOMING', -- 'UPCOMING', 'ACTIVE', 'FINISHED'
  grade_level VARCHAR(20), -- For education mode
  created_at TIMESTAMP DEFAULT NOW()
);

-- League Participants
CREATE TABLE league_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  league_id UUID REFERENCES leagues(id),
  user_id UUID REFERENCES users(id),
  rank INTEGER,
  score INTEGER DEFAULT 0,
  matches_played INTEGER DEFAULT 0,
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(league_id, user_id)
);

CREATE INDEX idx_league_participants_rank ON league_participants(league_id, rank);

-- League Matches
CREATE TABLE league_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  league_id UUID REFERENCES leagues(id),
  user_id UUID REFERENCES users(id),
  score INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  rank_before INTEGER,
  rank_after INTEGER,
  completed_at TIMESTAMP DEFAULT NOW()
);

-- League Scores (Aggregated)
CREATE TABLE league_scores (
  user_id UUID REFERENCES users(id),
  league_id UUID REFERENCES leagues(id),
  total_score INTEGER DEFAULT 0,
  matches_played INTEGER DEFAULT 0,
  highest_rank INTEGER,
  updated_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY(user_id, league_id)
);
```

---

### **Education Tables**

```sql
-- Education Profiles
CREATE TABLE education_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  age INTEGER,
  country VARCHAR(2) DEFAULT 'US',
  school_system VARCHAR(20), -- 'US', 'UK', 'GENERAL'
  grade_level VARCHAR(20), -- 'GRADE_11', 'YEAR_10', etc.
  challenge_grade_level VARCHAR(20),
  exam_focus VARCHAR(20) DEFAULT 'NONE', -- 'NONE', 'SAT', 'GMAT'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

### **Monetization Tables**

```sql
-- Subscription Products
CREATE TABLE subscription_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  duration_days INTEGER NOT NULL,
  features JSONB DEFAULT '[]',
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  product_id VARCHAR(100) REFERENCES subscription_products(product_id),
  status VARCHAR(20) NOT NULL, -- 'ACTIVE', 'CANCELLED', 'EXPIRED'
  platform VARCHAR(20), -- 'ios', 'android', 'web'
  transaction_id VARCHAR(255),
  receipt_data TEXT,
  start_date TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  auto_renew BOOLEAN DEFAULT true,
  cancelled_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id, status);

-- Payments
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  product_id VARCHAR(100),
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  status VARCHAR(20) NOT NULL, -- 'PENDING', 'COMPLETED', 'FAILED', 'REFUNDED'
  platform VARCHAR(20),
  transaction_id VARCHAR(255) UNIQUE,
  receipt_data TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP
);

-- Wallet Transactions
CREATE TABLE wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  type VARCHAR(20) NOT NULL, -- 'EARN', 'SPEND', 'REWARD', 'PURCHASE'
  item VARCHAR(20) NOT NULL, -- 'COINS', 'LIVES', 'HINTS'
  amount INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  reason VARCHAR(100),
  reference_id UUID, -- Session ID, purchase ID, etc.
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_wallet_transactions_user ON wallet_transactions(user_id, created_at);

-- Ad Views
CREATE TABLE ad_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  ad_unit_id VARCHAR(100) NOT NULL,
  ad_type VARCHAR(20) NOT NULL, -- 'REWARDED', 'INTERSTITIAL', 'BANNER'
  context VARCHAR(50), -- 'TRY_AGAIN', 'EXTRA_TIME', 'DOUBLE_POINTS'
  completed BOOLEAN DEFAULT false,
  viewed_at TIMESTAMP DEFAULT NOW()
);

-- Ad Rewards
CREATE TABLE ad_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  ad_view_id UUID REFERENCES ad_views(id),
  type VARCHAR(20) NOT NULL, -- 'EXTRA_TIME', 'TRY_AGAIN', 'DOUBLE_POINTS', 'COINS'
  amount INTEGER NOT NULL,
  granted_at TIMESTAMP DEFAULT NOW()
);
```

---

### **Rewards & Achievements Tables**

```sql
-- Daily Rewards
CREATE TABLE daily_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_of_week INTEGER NOT NULL, -- 1-7 (Monday-Sunday)
  type VARCHAR(20) NOT NULL, -- 'COINS', 'LIVES', 'HINTS', 'DOUBLE_XP', 'AD_FREE'
  amount INTEGER NOT NULL,
  description VARCHAR(100),
  emoji VARCHAR(10),
  UNIQUE(day_of_week)
);

-- User Rewards
CREATE TABLE user_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  reward_id UUID REFERENCES daily_rewards(id),
  claimed BOOLEAN DEFAULT false,
  claimed_at TIMESTAMP,
  UNIQUE(user_id, reward_id, claimed_at::date)
);

-- Achievements
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  category VARCHAR(50),
  requirement JSONB NOT NULL, -- {"type": "wins", "count": 100}
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User Achievements
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  achievement_id UUID REFERENCES achievements(id),
  progress INTEGER DEFAULT 0,
  unlocked BOOLEAN DEFAULT false,
  unlocked_at TIMESTAMP,
  UNIQUE(user_id, achievement_id)
);
```

---

### **System Tables**

```sql
-- Push Devices
CREATE TABLE push_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  device_token VARCHAR(255) UNIQUE NOT NULL,
  platform VARCHAR(20) NOT NULL, -- 'ios', 'android'
  app_version VARCHAR(20),
  os_version VARCHAR(20),
  active BOOLEAN DEFAULT true,
  registered_at TIMESTAMP DEFAULT NOW(),
  last_used_at TIMESTAMP
);

-- Notification Preferences
CREATE TABLE notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  daily_reminder BOOLEAN DEFAULT true,
  friend_requests BOOLEAN DEFAULT true,
  league_updates BOOLEAN DEFAULT true,
  match_invites BOOLEAN DEFAULT true,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  type VARCHAR(50) NOT NULL,
  title VARCHAR(100) NOT NULL,
  body TEXT,
  data JSONB,
  read BOOLEAN DEFAULT false,
  sent_at TIMESTAMP DEFAULT NOW(),
  read_at TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id, sent_at);

-- Analytics Events
CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  event VARCHAR(100) NOT NULL,
  properties JSONB,
  timestamp TIMESTAMP NOT NULL,
  session_id VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_events_user ON analytics_events(user_id, timestamp);
CREATE INDEX idx_analytics_events_event ON analytics_events(event, timestamp);

-- Error Logs
CREATE TABLE error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  error_type VARCHAR(100),
  error_message TEXT,
  stack_trace TEXT,
  context JSONB,
  platform VARCHAR(20),
  app_version VARCHAR(20),
  occurred_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Daily Quests
CREATE TABLE daily_quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(50) NOT NULL, -- 'PLAY_GAMES', 'ANSWER_CORRECTLY', 'COMPLETE_DAILY_CHALLENGE', 'PLAY_WITH_FRIENDS'
  title VARCHAR(100) NOT NULL,
  description TEXT,
  target_value INTEGER NOT NULL,
  coin_reward INTEGER DEFAULT 0,
  day_of_week INTEGER, -- 1-7 (optional, for day-specific quests)
  created_at TIMESTAMP DEFAULT NOW()
);

-- User Quest Progress
CREATE TABLE user_quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  quest_id UUID REFERENCES daily_quests(id),
  current_value INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  is_claimed BOOLEAN DEFAULT false,
  quest_date DATE NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, quest_id, quest_date)
);

-- Weekly Challenges
CREATE TABLE weekly_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(100) NOT NULL,
  description TEXT,
  emoji VARCHAR(10),
  target_value INTEGER NOT NULL,
  coin_reward INTEGER DEFAULT 0,
  xp_reward INTEGER DEFAULT 0,
  week_start_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(id, week_start_date)
);

-- User Weekly Challenge Progress
CREATE TABLE user_weekly_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  challenge_id UUID REFERENCES weekly_challenges(id),
  current_progress INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  is_claimed BOOLEAN DEFAULT false,
  week_start_date DATE NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, challenge_id, week_start_date)
);

-- Collectible Cards
CREATE TABLE collectible_cards (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  emoji VARCHAR(10),
  category VARCHAR(50) NOT NULL, -- 'MATH', 'SCIENCE', 'HISTORY', 'GEOGRAPHY', 'LITERATURE', 'ACHIEVEMENT', 'MIXED'
  rarity VARCHAR(20) NOT NULL, -- 'COMMON', 'RARE', 'EPIC', 'LEGENDARY'
  unlock_condition TEXT,
  unlock_value INTEGER,
  is_education_mode BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User Cards
CREATE TABLE user_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  card_id VARCHAR(100) REFERENCES collectible_cards(id),
  quantity INTEGER DEFAULT 1,
  obtained_at TIMESTAMP DEFAULT NOW(),
  is_favorite BOOLEAN DEFAULT false,
  UNIQUE(user_id, card_id)
);

CREATE INDEX idx_user_cards_user ON user_cards(user_id);
CREATE INDEX idx_user_cards_card ON user_cards(card_id);

-- User Invites
CREATE TABLE user_invites (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  invites_sent INTEGER DEFAULT 0,
  reward_claimed BOOLEAN DEFAULT false,
  reward_claimed_at TIMESTAMP,
  invite_code VARCHAR(20) UNIQUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User Contacts (Hashed)
CREATE TABLE user_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  hashed_phone_number VARCHAR(255) NOT NULL,
  matched_user_id UUID REFERENCES users(id),
  discovered_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, hashed_phone_number)
);

CREATE INDEX idx_user_contacts_hashed ON user_contacts(hashed_phone_number);

-- App Versions
CREATE TABLE app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version VARCHAR(20) NOT NULL,
  platform VARCHAR(20) NOT NULL, -- 'ios', 'android'
  force_update BOOLEAN DEFAULT false,
  release_notes TEXT,
  release_date TIMESTAMP DEFAULT NOW(),
  active BOOLEAN DEFAULT true,
  UNIQUE(version, platform)
);

-- FAQ Items
CREATE TABLE faq_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  category VARCHAR(50),
  display_order INTEGER DEFAULT 0,
  language VARCHAR(5) DEFAULT 'en',
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Support Tickets
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  subject VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  category VARCHAR(50), -- 'GENERAL', 'TECHNICAL', 'BILLING', 'FEATURE_REQUEST'
  status VARCHAR(20) DEFAULT 'OPEN', -- 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_support_tickets_user ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);

-- Supported Languages
CREATE TABLE supported_languages (
  code VARCHAR(5) PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  native_name VARCHAR(50) NOT NULL,
  enabled BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0
);

-- Coin Packages
CREATE TABLE coin_packages (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  coins INTEGER NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  bonus INTEGER DEFAULT 0,
  popular BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 📊 API Summary Statistics

| Category | Screens | Endpoints | Real-time | Auth Required |
|----------|---------|-----------|-----------|---------------|
| **Auth & Onboarding** | 2 | 10 | 0 | 8 |
| **Home & Navigation** | 2 | 8 | 0 | 8 |
| **Quiz Gameplay** | 2 | 15 | 2 | 15 |
| **Campaign** | 3 | 8 | 0 | 8 |
| **Friends & Multiplayer** | 4 | 18 | 8 | 18 |
| **Leagues** | 1 | 10 | 2 | 10 |
| **Profile** | 1 | 12 | 0 | 12 |
| **Education** | 2 | 10 | 0 | 10 |
| **Monetization** | 2 | 12 | 0 | 10 |
| **Daily Quests** | 1 | 4 | 0 | 4 |
| **Weekly Challenges** | 1 | 3 | 0 | 3 |
| **Card Collection** | 1 | 6 | 0 | 6 |
| **Achievements** | 1 | 3 | 0 | 3 |
| **Invites & Referrals** | 1 | 4 | 0 | 4 |
| **Contacts Discovery** | 1 | 3 | 0 | 3 |
| **System & Infrastructure** | - | 25 | 0 | 20 |
| **TOTAL** | **24** | **171** | **12** | **150** |

---

## 🔐 Authentication Summary

| Auth Type | Count | Endpoints |
|-----------|-------|-----------|
| **No Auth** | 21 | Signup, Login, Public endpoints, FAQ, About, Version check |
| **Required** | 150 | All user-specific actions |
| **Admin Only** | 3 | Question generation, validation, push notifications |

---

## 🌐 Real-time vs REST

| Type | Count | Use Cases |
|------|-------|-----------|
| **REST** | 159 | Most CRUD operations, fetching data |
| **WebSocket** | 12 | Multiplayer lobbies, live matches, presence |

---

## 📦 Database Entity Count

**Total Tables:** 60+

| Category | Tables |
|----------|--------|
| **Core** | 8 (users, auth, sessions, stats, etc.) |
| **Questions** | 4 (questions, pools, answered, reports) |
| **Gameplay** | 4 (sessions, answers, rounds, progress) |
| **Multiplayer** | 6 (rooms, participants, matches, messages) |
| **Social** | 5 (friends, requests, presence, invites) |
| **Leagues** | 5 (leagues, participants, matches, scores) |
| **Education** | 1 (profiles) |
| **Monetization** | 7 (subscriptions, payments, ads, rewards) |
| **Quests & Challenges** | 4 (daily_quests, user_quest_progress, weekly_challenges, user_weekly_progress) |
| **Cards & Achievements** | 3 (collectible_cards, user_cards, achievements, user_achievements) |
| **Invites & Contacts** | 2 (user_invites, user_contacts) |
| **System** | 15+ (notifications, analytics, logs, app_versions, faq, support, languages, coin_packages) |

---

## 🚀 Implementation Priority

### **Phase 1: MVP (Core Gameplay)**
- ✅ Auth & User Management
- ✅ Question Bank & Fetching
- ✅ Quiz Sessions (Practice, Daily)
- ✅ Results & Stats
- ✅ Wallet & Coins
- ✅ Basic Profile

### **Phase 2: Social & Multiplayer**
- 🔄 Friends System
- 🔄 Room Management
- 🔄 Multiplayer Matches
- 🔄 Real-time WebSockets
- 🔄 Presence System

### **Phase 3: Competitive**
- 📋 League System
- 📋 Leaderboards
- 📋 Rankings
- 📋 Prizes

### **Phase 4: Education**
- 📋 Education Profiles
- 📋 Grade-based Questions
- 📋 SAT/GMAT Mode
- 📋 Education Subscriptions

### **Phase 5: Advanced**
- 📋 Campaign Mode (500 rounds)
- 📋 Daily Rewards System
- 📋 Achievements
- 📋 Push Notifications
- 📋 Analytics & Telemetry

---

## ✅ **Document Status**

**Complete:** ✅  
**Screens Mapped:** 24  
**Endpoints Defined:** 171  
**Database Tables:** 60+  
**Ready for:** Backend Development

---

## 📝 **Changelog**

### Version 1.1.0 (Updated: January 17, 2026)
- ✅ Added Daily Quests endpoints (4 endpoints)
- ✅ Added Weekly Challenges endpoints (3 endpoints)
- ✅ Added Card Collection system (6 endpoints)
- ✅ Added Achievements endpoints (3 endpoints)
- ✅ Added Friend Invites & Referrals (4 endpoints)
- ✅ Added Contacts & Friend Discovery (3 endpoints)
- ✅ Added Version Check & App Updates (2 endpoints)
- ✅ Added Language & Localization (2 endpoints)
- ✅ Added Help & Support (3 endpoints)
- ✅ Added About & Legal (3 endpoints)
- ✅ Added Coin Store (3 endpoints)
- ✅ Enhanced Daily Rewards with login rewards, free coins, and lucky spin
- ✅ Updated statistics and summaries

### Version 1.0.0 (Initial: January 11, 2026)
- Initial comprehensive backend API specification
- 19 screens mapped
- 118 endpoints defined

---

**Generated by:** Mind Rush Development Team  
**Last Updated:** January 17, 2026  
**Version:** 1.1.0

