# MindRush Backend API Specification

**Version:** 1.0  
**Stack:** Node.js + TypeScript + PostgreSQL  
**Base URL:** `https://api.mindrush.com/v1`  
**Auth:** JWT Access Tokens + Refresh Tokens

---

## Table of Contents

1. [Overview & Authentication](#overview--authentication)
2. [Auth & Account Endpoints](#auth--account-endpoints)
3. [User Profile Endpoints](#user-profile-endpoints)
4. [Questions & Content Endpoints](#questions--content-endpoints)
5. [Game Session Endpoints](#game-session-endpoints)
6. [Campaign Mode Endpoints](#campaign-mode-endpoints)
7. [Multiplayer/Rooms Endpoints](#multiplayerrooms-endpoints)
8. [Leagues Endpoints](#leagues-endpoints)
9. [Friends & Social Endpoints](#friends--social-endpoints)
10. [Daily Quests Endpoints](#daily-quests-endpoints)
11. [Retention & Rewards Endpoints](#retention--rewards-endpoints)
12. [Monetization Endpoints](#monetization-endpoints)
13. [Leaderboards Endpoints](#leaderboards-endpoints)
14. [Admin & Moderation Endpoints](#admin--moderation-endpoints)
15. [Data Model (PostgreSQL Tables)](#data-model-postgresql-tables)
16. [Realtime/Multiplayer (Socket.IO)](#realtimemultiplayer-socketio)
17. [Error Responses](#error-responses)
18. [Rate Limiting](#rate-limiting)
19. [Third-Party Integrations](#third-party-integrations)
20. [Missing/Ambiguous Items & Assumptions](#missingambiguous-items--assumptions)
21. [Frontend Screen → Endpoints Mapping](#frontend-screen--endpoints-mapping)

---

## Overview & Authentication

### Authentication Model

- **JWT Access Tokens**: Short-lived (15 minutes), used for API requests
- **Refresh Tokens**: Long-lived (30 days), used to obtain new access tokens
- **Guest Mode**: Anonymous users get temporary tokens (converted to full account later)
- **Age Verification**: COPPA compliance for users under 13 (require parental consent)

### Token Usage

```
Authorization: Bearer <access_token>
```

### Rate Limiting

- **Default**: 100 requests/minute per user
- **Auth endpoints**: 5 requests/minute
- **Question fetch**: 30 requests/minute
- **Game submission**: 60 requests/minute

---

## Auth & Account Endpoints

### POST /auth/guest
Create anonymous guest account

**Auth:** None  
**Request Body:**
```json
{
  "deviceId": "string",
  "platform": "ios" | "android"
}
```

**Response:** `201 Created`
```json
{
  "user": {
    "id": "string (UUID)",
    "username": "Guest_12345",
    "isGuest": true,
    "coins": 100,
    "createdAt": "ISO8601"
  },
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 900
}
```

**Example:**
```bash
curl -X POST https://api.mindrush.com/v1/auth/guest \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"abc123","platform":"ios"}'
```

---

### POST /auth/register
Convert guest to registered user or create new account

**Auth:** Bearer token (guest) OR None  
**Request Body:**
```json
{
  "username": "string (3-20 chars, alphanumeric + underscore)",
  "email": "string (optional, for recovery)",
  "age": "number (required for COPPA)",
  "country": "string (ISO 3166-1)",
  "parentalConsent": "boolean (required if age < 13)",
  "parentEmail": "string (required if age < 13)",
  "guestUserId": "string (optional, if upgrading from guest)"
}
```

**Response:** `201 Created`
```json
{
  "user": {
    "id": "string",
    "username": "string",
    "email": "string | null",
    "isGuest": false,
    "age": "number",
    "country": "string",
    "coins": 100,
    "createdAt": "ISO8601"
  },
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 900
}
```

**Validations:**
- Username must be unique
- Age must be >= 5
- If age < 13, parentalConsent must be true and parentEmail must be valid
- Email format validation

**Error Response:** `400 Bad Request`
```json
{
  "error": "validation_error",
  "message": "Username already taken",
  "field": "username"
}
```

---

### POST /auth/login
Login with username

**Auth:** None  
**Request Body:**
```json
{
  "username": "string",
  "deviceId": "string"
}
```

**Response:** `200 OK`
```json
{
  "user": {...},
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 900
}
```

---

### POST /auth/refresh
Refresh access token

**Auth:** None  
**Request Body:**
```json
{
  "refreshToken": "string"
}
```

**Response:** `200 OK`
```json
{
  "accessToken": "string",
  "expiresIn": 900
}
```

**Error Response:** `401 Unauthorized`
```json
{
  "error": "invalid_token",
  "message": "Refresh token expired or invalid"
}
```

---

### POST /auth/logout
Logout and invalidate refresh token

**Auth:** Bearer token  
**Request Body:**
```json
{
  "refreshToken": "string"
}
```

**Response:** `204 No Content`

---

### DELETE /auth/account
Delete user account (COPPA compliance)

**Auth:** Bearer token  
**Response:** `204 No Content`

**Notes:**
- Soft delete with 30-day grace period
- Anonymize PII immediately
- Keep aggregated stats (anonymized)

---

## User Profile Endpoints

### GET /users/me
Get current user profile

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "id": "string",
  "username": "string",
  "email": "string | null",
  "isGuest": false,
  "age": 15,
  "country": "Kenya",
  "coins": 450,
  "streakCount": 7,
  "consecutiveLoginDays": 7,
  "lastLoginDate": "ISO8601",
  "lastDailyChallenge": "ISO8601",
  "hasClaimedDailyLoginReward": false,
  "lastFreeCoinsClaimDate": "ISO8601 | null",
  "lastLuckySpinDate": "ISO8601 | null",
  "stats": {
    "questionsAnswered": 245,
    "correctAnswers": 198,
    "totalScore": 12450,
    "accuracy": 0.8081
  },
  "education": {
    "educationModeEnabled": false,
    "schoolSystem": "CBC" | null,
    "gradeLevel": "GRADE_8" | null,
    "challengeGradeLevel": "GRADE_9" | null,
    "examFocus": "NONE" | "SAT" | "GMAT"
  },
  "subscriptions": {
    "hasSatSubscription": false,
    "hasGmatSubscription": false,
    "hasAllAccessSubscription": false,
    "isPremium": false
  },
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

---

### PATCH /users/me
Update user profile

**Auth:** Bearer token  
**Request Body:** (all fields optional)
```json
{
  "username": "string",
  "email": "string",
  "country": "string",
  "education": {
    "educationModeEnabled": boolean,
    "schoolSystem": "string",
    "gradeLevel": "string",
    "challengeGradeLevel": "string",
    "examFocus": "string"
  }
}
```

**Response:** `200 OK` (same as GET /users/me)

**Validations:**
- Username change requires uniqueness check
- Email change triggers verification

---

### POST /users/me/coins
Update user coins (internal use for rewards, purchases)

**Auth:** Bearer token + Server validation  
**Request Body:**
```json
{
  "amount": "number (can be negative)",
  "reason": "purchase" | "reward" | "quest" | "daily_login" | "lucky_spin" | "ad_watched" | "game_win" | "refund",
  "metadata": {
    "questId": "string",
    "gameSessionId": "string",
    "purchaseId": "string"
  }
}
```

**Response:** `200 OK`
```json
{
  "coins": 500,
  "transaction": {
    "id": "string",
    "amount": 50,
    "reason": "quest",
    "timestamp": "ISO8601"
  }
}
```

**Validations:**
- Coins cannot go negative
- Reason must be valid enum
- Rate limit: 60 requests/minute

---

### POST /users/me/login-reward
Claim daily login reward

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "claimed": true,
  "day": 3,
  "reward": {
    "coins": 100,
    "emoji": "💸"
  },
  "nextReward": {
    "day": 4,
    "coins": 150,
    "availableAt": "ISO8601"
  },
  "user": {
    "coins": 550,
    "consecutiveLoginDays": 3,
    "hasClaimedDailyLoginReward": true
  }
}
```

**Error Response:** `409 Conflict`
```json
{
  "error": "already_claimed",
  "message": "Daily login reward already claimed today",
  "nextAvailableAt": "ISO8601"
}
```

---

### POST /users/me/free-coins
Claim 4-hour free coins

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "claimed": true,
  "coins": 50,
  "nextClaimAt": "ISO8601",
  "user": {
    "coins": 600
  }
}
```

**Error Response:** `429 Too Many Requests`
```json
{
  "error": "cooldown_active",
  "message": "Free coins available in 2 hours 30 minutes",
  "nextClaimAt": "ISO8601",
  "remainingSeconds": 9000
}
```

---

### POST /users/me/lucky-spin
Spin the lucky wheel (once per day)

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "result": {
    "coins": 500,
    "emoji": "🏆",
    "isJackpot": true
  },
  "nextSpinAt": "ISO8601",
  "user": {
    "coins": 1100,
    "lastLuckySpinDate": "ISO8601"
  }
}
```

**Error Response:** `409 Conflict`
```json
{
  "error": "already_spun",
  "message": "Lucky spin already used today",
  "nextSpinAt": "ISO8601"
}
```

---

### GET /users/:userId
Get public user profile (for friends, leaderboards)

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "id": "string",
  "username": "string",
  "stats": {
    "totalScore": 12450,
    "accuracy": 0.81,
    "gamesPlayed": 245
  },
  "rank": {
    "global": 1523,
    "weekly": 89
  },
  "createdAt": "ISO8601"
}
```

**Privacy:**
- Only public fields exposed
- No email, age, or personal info
- User can opt out of discovery

---

## Questions & Content Endpoints

### GET /questions
Fetch questions for a game session

**Auth:** Bearer token  
**Query Params:**
```
category: string (required) - "Math", "Science", "History", "Geography", "Literature", "Mixed"
difficulty: string (optional) - "easy", "medium", "hard", "super_hard"
mode: string (required) - "GENERAL", "EDUCATION_SCHOOL", "EDUCATION_SAT", "EDUCATION_GMAT", "DAILY_CHALLENGE"
gradeLevel: string (optional) - "GRADE_5" to "GRADE_12" (required for EDUCATION_SCHOOL)
count: number (optional, default 10, max 20)
excludeIds: string[] (optional) - comma-separated question IDs to exclude
```

**Response:** `200 OK`
```json
{
  "questions": [
    {
      "id": "string (UUID)",
      "text": "What is the capital of France?",
      "options": [
        "Paris",
        "London",
        "Berlin",
        "Madrid"
      ],
      "correctIndex": 0,
      "explanation": "Paris is the capital and largest city of France...",
      "category": "Geography",
      "difficulty": "easy",
      "topic": "capitals",
      "mode": "GENERAL",
      "gradeLevel": null,
      "source": "CURATED",
      "language": "EN"
    }
  ],
  "metadata": {
    "count": 10,
    "category": "Geography",
    "difficulty": "easy"
  }
}
```

**Validations:**
- If mode = "EDUCATION_SCHOOL", gradeLevel is required
- If mode = "EDUCATION_SAT" or "EDUCATION_GMAT", gradeLevel is null
- Daily challenge questions must be fetched with mode = "DAILY_CHALLENGE"

**Cache:** Questions can be cached client-side for 24 hours

**Example:**
```bash
curl -X GET "https://api.mindrush.com/v1/questions?category=Math&difficulty=medium&mode=GENERAL&count=10" \
  -H "Authorization: Bearer <token>"
```

---

### GET /questions/daily-challenge
Get today's daily challenge questions

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "challengeId": "string",
  "date": "2024-01-15",
  "questions": [...],
  "metadata": {
    "count": 10,
    "difficulty": "medium",
    "expiresAt": "ISO8601"
  }
}
```

**Notes:**
- Questions rotate daily at midnight UTC
- Same questions for all users on same day
- User can only complete once per day

---

### GET /questions/categories
Get available question categories

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "categories": [
    {
      "id": "math",
      "name": "Math",
      "description": "Mathematics and arithmetic questions",
      "questionCount": 1250,
      "icon": "📐"
    },
    {
      "id": "science",
      "name": "Science",
      "description": "Biology, Chemistry, Physics questions",
      "questionCount": 980,
      "icon": "🔬"
    }
  ]
}
```

**Cache:** Can be cached for 7 days

---

### POST /questions/report
Report a question for review

**Auth:** Bearer token  
**Request Body:**
```json
{
  "questionId": "string",
  "reason": "incorrect_answer" | "typo" | "offensive" | "duplicate" | "other",
  "description": "string (optional, max 500 chars)"
}
```

**Response:** `201 Created`
```json
{
  "reportId": "string",
  "status": "pending",
  "message": "Thank you for your report. We'll review it shortly."
}
```

---

### POST /questions/generate (AI-powered)
Request AI-generated questions (admin/internal)

**Auth:** Bearer token + Admin role  
**Request Body:**
```json
{
  "category": "string",
  "difficulty": "string",
  "gradeLevel": "string | null",
  "count": number,
  "prompt": "string (optional)"
}
```

**Response:** `201 Created`
```json
{
  "jobId": "string",
  "status": "processing",
  "estimatedTime": 30
}
```

**Notes:**
- Async job, use polling or webhooks
- Questions need manual review before going live
- AI provider: OpenAI/Gemini (configured server-side)

---

## Game Session Endpoints

### POST /game-sessions
Start a new game session

**Auth:** Bearer token  
**Request Body:**
```json
{
  "mode": "PRACTICE" | "DAILY_CHALLENGE" | "LEAGUE" | "MULTIPLAYER" | "CAMPAIGN",
  "category": "string",
  "difficulty": "string",
  "questionCount": number,
  "metadata": {
    "leagueId": "string | null",
    "roomCode": "string | null",
    "campaignRoundNumber": "number | null"
  }
}
```

**Response:** `201 Created`
```json
{
  "sessionId": "string (UUID)",
  "mode": "PRACTICE",
  "questions": [...], // Full question objects with correctIndex
  "startedAt": "ISO8601",
  "expiresAt": "ISO8601" // 30 minutes from start
}
```

**Validations:**
- For DAILY_CHALLENGE: Check if already completed today
- For LEAGUE: Verify user is enrolled and has paid entry fee
- For CAMPAIGN: Verify round is unlocked
- For MULTIPLAYER: Verify room exists and user is member

**Security:**
- Questions stored server-side with session
- correctIndex NOT sent to client initially
- Server validates all answers

---

### POST /game-sessions/:sessionId/answer
Submit answer for a question

**Auth:** Bearer token  
**Request Body:**
```json
{
  "questionId": "string",
  "selectedIndex": number,
  "timeSpent": number, // milliseconds
  "timestamp": "ISO8601"
}
```

**Response:** `200 OK`
```json
{
  "correct": true,
  "correctIndex": 0,
  "explanation": "Paris is the capital...",
  "score": 150,
  "timeBonus": 25,
  "currentScore": 675,
  "questionsAnswered": 7,
  "correctAnswers": 6
}
```

**Scoring Logic:**
- Base score: difficulty multiplier (100-300)
- Time bonus: 0-75 points based on speed
- Wrong answer: 0 points
- Server-side validation prevents cheating

---

### POST /game-sessions/:sessionId/complete
Complete game session and get final results

**Auth:** Bearer token  
**Request Body:**
```json
{
  "questionsAnswered": number,
  "correctAnswers": number,
  "totalScore": number,
  "timeSpent": number // total milliseconds
}
```

**Response:** `200 OK`
```json
{
  "sessionId": "string",
  "finalScore": 875,
  "accuracy": 0.8,
  "rank": "A",
  "rewards": {
    "coins": 87,
    "xp": 175,
    "bonuses": [
      {
        "type": "perfect_score",
        "amount": 50,
        "description": "All answers correct!"
      }
    ]
  },
  "stats": {
    "questionsAnswered": 10,
    "correctAnswers": 8,
    "averageTimePerQuestion": 12.5
  },
  "userUpdates": {
    "coins": 537,
    "totalScore": 13325,
    "questionsAnswered": 255,
    "accuracy": 0.809
  }
}
```

**Server Actions:**
- Validate client-submitted score matches server records
- Award coins and update stats
- Update quest progress
- Update leaderboards
- Check for achievements

**Anti-Cheat:**
- Compare timestamps
- Validate answer sequence
- Flag suspicious sessions (review manually)

---

## Campaign Mode Endpoints

### GET /campaign/progress
Get user's campaign progress

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "currentRound": 15,
  "totalStars": 38,
  "completedRounds": 14,
  "rounds": [
    {
      "roundNumber": 1,
      "title": "🎮 Welcome Challenge",
      "description": "Master the basics of Math",
      "difficulty": "easy",
      "questionCount": 10,
      "category": "Math",
      "coinsReward": 50,
      "entryCost": 10,
      "starsRequired": 0,
      "isLocked": false,
      "isCompleted": true,
      "bestScore": 1250,
      "starsEarned": 3
    }
  ]
}
```

---

### POST /campaign/rounds/:roundNumber/start
Start a campaign round

**Auth:** Bearer token  
**Path Param:** roundNumber (number)  
**Request Body:**
```json
{
  "entryCost": number // Coins to enter
}
```

**Response:** `201 Created`
```json
{
  "sessionId": "string",
  "round": {...},
  "questions": [...],
  "userCoins": 440 // After deduction
}
```

**Validations:**
- Round must be unlocked
- User must have enough coins for entry cost
- User must meet stars requirement

**Error Response:** `403 Forbidden`
```json
{
  "error": "insufficient_stars",
  "message": "Need 25 stars to unlock this round",
  "required": 25,
  "current": 20
}
```

---

### POST /campaign/rounds/:roundNumber/complete
Complete a campaign round

**Auth:** Bearer token  
**Request Body:**
```json
{
  "sessionId": "string",
  "score": number,
  "correctAnswers": number,
  "totalQuestions": number
}
```

**Response:** `200 OK`
```json
{
  "round": {
    "roundNumber": 15,
    "isCompleted": true,
    "bestScore": 1450,
    "starsEarned": 3
  },
  "rewards": {
    "coins": 100,
    "stars": 3
  },
  "nextRound": {
    "roundNumber": 16,
    "isLocked": false,
    "title": "Round 16"
  },
  "userUpdates": {
    "currentRound": 16,
    "totalStars": 41,
    "coins": 540
  }
}
```

---

### GET /campaign/leaderboard
Get campaign leaderboard (by total stars)

**Auth:** Bearer token  
**Query Params:**
```
page: number (default 1)
limit: number (default 50, max 100)
```

**Response:** `200 OK`
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "string",
      "username": "ProPlayer",
      "totalStars": 487,
      "completedRounds": 165,
      "currentRound": 166
    }
  ],
  "myRank": {
    "rank": 523,
    "totalStars": 41,
    "completedRounds": 14
  },
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 5234,
    "hasMore": true
  }
}
```

---

## Multiplayer/Rooms Endpoints

### POST /rooms
Create a multiplayer room

**Auth:** Bearer token  
**Request Body:**
```json
{
  "topic": "Math" | "Science" | "History" | "Geography" | "Literature" | "Mixed",
  "maxPlayers": number (2-8),
  "totalQuestions": number (5-20),
  "entryFee": number (50 coins default)
}
```

**Response:** `201 Created`
```json
{
  "room": {
    "id": "string (UUID)",
    "code": "ABC123",
    "hostId": "string",
    "topic": "Math",
    "maxPlayers": 4,
    "totalQuestions": 10,
    "entryFee": 50,
    "prizePot": 50,
    "players": [
      {
        "userId": "string",
        "username": "host_user",
        "score": 0,
        "isReady": true
      }
    ],
    "isActive": true,
    "createdAt": "ISO8601"
  },
  "userCoins": 400 // After entry fee deduction
}
```

**Validations:**
- User must have enough coins for entry fee
- Topic must be valid
- maxPlayers between 2-8
- totalQuestions between 5-20

---

### POST /rooms/join
Join a room by code

**Auth:** Bearer token  
**Request Body:**
```json
{
  "code": "ABC123"
}
```

**Response:** `200 OK`
```json
{
  "room": {
    "id": "string",
    "code": "ABC123",
    "hostId": "string",
    "topic": "Math",
    "maxPlayers": 4,
    "totalQuestions": 10,
    "entryFee": 50,
    "prizePot": 100,
    "players": [
      {...},
      {
        "userId": "string",
        "username": "new_player",
        "score": 0,
        "isReady": false
      }
    ],
    "isActive": true
  },
  "userCoins": 350
}
```

**Error Response:** `404 Not Found`
```json
{
  "error": "room_not_found",
  "message": "Room with code ABC123 does not exist or has expired"
}
```

**Error Response:** `409 Conflict`
```json
{
  "error": "room_full",
  "message": "Room is full (4/4 players)"
}
```

---

### GET /rooms/:code
Get room details

**Auth:** Bearer token  
**Response:** `200 OK` (same as join response)

---

### PATCH /rooms/:code/ready
Update player ready status

**Auth:** Bearer token  
**Request Body:**
```json
{
  "isReady": true
}
```

**Response:** `200 OK`
```json
{
  "room": {...},
  "allReady": true
}
```

**Realtime:** Broadcasts to all players in room via Socket.IO

---

### POST /rooms/:code/start
Start the game (host only, all players must be ready)

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "sessionId": "string",
  "questions": [...],
  "startedAt": "ISO8601"
}
```

**Validations:**
- User must be host
- All players must be ready
- At least 2 players required

---

### DELETE /rooms/:code/leave
Leave a room

**Auth:** Bearer token  
**Response:** `204 No Content`

**Side Effects:**
- If host leaves, transfer host to next player
- If last player leaves, delete room
- Refund entry fee if game hasn't started

---

### POST /rooms/:code/score
Update player score (during game)

**Auth:** Bearer token  
**Request Body:**
```json
{
  "score": number
}
```

**Response:** `200 OK`
```json
{
  "room": {
    "players": [
      {
        "userId": "string",
        "username": "player1",
        "score": 875,
        "isReady": true
      }
    ]
  }
}
```

**Realtime:** Broadcasts score update to all players

---

### GET /rooms/:code/results
Get final results and prize distribution

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "results": {
    "rankings": [
      {
        "rank": 1,
        "userId": "string",
        "username": "winner",
        "score": 1250,
        "prize": 100
      },
      {
        "rank": 2,
        "userId": "string",
        "username": "second",
        "score": 980,
        "prize": 60
      },
      {
        "rank": 3,
        "userId": "string",
        "username": "third",
        "score": 875,
        "prize": 40
      }
    ],
    "prizePot": 200,
    "distribution": "50% / 30% / 20%"
  },
  "myRank": 1,
  "myPrize": 100,
  "userCoins": 500
}
```

**Prize Distribution:**
- 1st place: 50% of prize pot
- 2nd place: 30% of prize pot
- 3rd place: 20% of prize pot

---

## Leagues Endpoints

### GET /leagues
List available leagues

**Auth:** Bearer token  
**Query Params:**
```
topic: string (optional) - "All", "Math", "Science", etc.
status: string (optional) - "Active", "Upcoming", "Completed"
page: number (default 1)
limit: number (default 20)
```

**Response:** `200 OK`
```json
{
  "leagues": [
    {
      "id": "string (UUID)",
      "name": "Math Masters League",
      "description": "Test your mathematical prowess...",
      "topic": "Math",
      "tier": "Gold",
      "entryFee": 50,
      "maxParticipants": 100,
      "currentParticipants": 67,
      "prizePot": 3350,
      "startDate": "ISO8601",
      "endDate": "ISO8601",
      "daysRemaining": 5,
      "isActive": true,
      "totalQuestions": 10,
      "isJoined": false
    }
  ],
  "pagination": {...}
}
```

---

### POST /leagues/:leagueId/join
Join a league

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "league": {
    "id": "string",
    "name": "Math Masters League",
    "currentParticipants": 68,
    "prizePot": 3400
  },
  "participant": {
    "userId": "string",
    "username": "player",
    "score": 0,
    "rank": 68,
    "joinedAt": "ISO8601"
  },
  "userCoins": 400
}
```

**Validations:**
- User must have enough coins for entry fee
- League must not be full
- User cannot join same league twice
- League must be active

**Error Response:** `409 Conflict`
```json
{
  "error": "already_joined",
  "message": "You are already participating in this league"
}
```

---

### POST /leagues/:leagueId/score
Submit score to league

**Auth:** Bearer token  
**Request Body:**
```json
{
  "sessionId": "string",
  "score": number
}
```

**Response:** `200 OK`
```json
{
  "participant": {
    "userId": "string",
    "username": "player",
    "score": 1250,
    "rank": 15,
    "previousRank": 35
  },
  "league": {
    "id": "string",
    "name": "Math Masters League"
  }
}
```

**Validations:**
- Session must be valid league game session
- Score must match server records
- Can only submit once per league

---

### GET /leagues/:leagueId/leaderboard
Get league leaderboard

**Auth:** Bearer token  
**Query Params:**
```
page: number (default 1)
limit: number (default 50, max 100)
```

**Response:** `200 OK`
```json
{
  "league": {
    "id": "string",
    "name": "Math Masters League",
    "prizePot": 3400,
    "daysRemaining": 5
  },
  "leaderboard": [
    {
      "rank": 1,
      "userId": "string",
      "username": "TopPlayer",
      "score": 1850,
      "estimatedPrize": 680
    }
  ],
  "myRank": {
    "rank": 15,
    "score": 1250,
    "estimatedPrize": 0
  },
  "pagination": {...}
}
```

**Prize Distribution (Top 50):**
- 1st: 20%
- 2nd: 15%
- 3rd: 10%
- 4th-10th: 5% each
- 11th-50th: Remaining split equally

---

### GET /leagues/:leagueId/results
Get final league results (after completion)

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "league": {
    "id": "string",
    "name": "Math Masters League",
    "status": "completed",
    "endDate": "ISO8601"
  },
  "results": {
    "rankings": [...], // Top 50
    "prizePot": 3400,
    "distribution": {...}
  },
  "myResult": {
    "rank": 15,
    "score": 1250,
    "prize": 85,
    "awarded": true
  }
}
```

---

## Friends & Social Endpoints

### GET /friends
Get user's friend list

**Auth:** Bearer token  
**Query Params:**
```
status: "accepted" | "pending" | "blocked" (default "accepted")
page: number
limit: number
```

**Response:** `200 OK`
```json
{
  "friends": [
    {
      "id": "string",
      "userId": "string",
      "username": "friend1",
      "status": "accepted",
      "stats": {
        "totalScore": 15230,
        "gamesPlayed": 245
      },
      "lastActive": "ISO8601",
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {...}
}
```

---

### POST /friends/search
Search for users

**Auth:** Bearer token  
**Request Body:**
```json
{
  "query": "string (username search)",
  "limit": 20
}
```

**Response:** `200 OK`
```json
{
  "users": [
    {
      "userId": "string",
      "username": "searchresult",
      "stats": {
        "totalScore": 12000,
        "gamesPlayed": 180
      },
      "isFriend": false,
      "hasPendingRequest": false
    }
  ]
}
```

**Privacy:**
- Users can opt out of search
- Only public profile data returned

---

### POST /friends/request
Send friend request

**Auth:** Bearer token  
**Request Body:**
```json
{
  "userId": "string"
}
```

**Response:** `201 Created`
```json
{
  "request": {
    "id": "string",
    "fromUserId": "string",
    "toUserId": "string",
    "status": "pending",
    "createdAt": "ISO8601"
  }
}
```

**Validations:**
- Cannot send request to yourself
- Cannot send duplicate request
- Target user must exist and not be blocked

---

### POST /friends/request/:requestId/accept
Accept friend request

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "friendship": {
    "id": "string",
    "userId": "string",
    "username": "newfriend",
    "status": "accepted",
    "createdAt": "ISO8601"
  }
}
```

---

### POST /friends/request/:requestId/decline
Decline friend request

**Auth:** Bearer token  
**Response:** `204 No Content`

---

### DELETE /friends/:friendshipId
Remove friend

**Auth:** Bearer token  
**Response:** `204 No Content`

---

### POST /friends/invite-code
Generate invite/referral code

**Auth:** Bearer token  
**Response:** `201 Created`
```json
{
  "code": "PLAYER123",
  "url": null,
  "message": "Share this code with friends! Both of you get 100 bonus coins when they use it.",
  "rewards": {
    "inviter": 100,
    "invitee": 100
  },
  "expiresAt": "ISO8601",
  "usageCount": 0,
  "usageLimit": 10
}
```

**Notes:**
- Code is user-specific
- Can be used by multiple people (up to limit)
- Both users get rewards on first game completion

---

### POST /friends/redeem-code
Redeem invite/referral code

**Auth:** Bearer token  
**Request Body:**
```json
{
  "code": "PLAYER123"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "rewards": {
    "coins": 100
  },
  "inviter": {
    "userId": "string",
    "username": "inviter",
    "isNowFriend": true
  },
  "userCoins": 550
}
```

**Side Effects:**
- Adds inviter as friend automatically
- Awards bonus coins to both users
- Tracks attribution for analytics

**Validations:**
- Code must be valid and not expired
- User cannot redeem own code
- User cannot redeem same code twice

---

### POST /friends/contacts/sync
Sync contacts for friend discovery (privacy-safe)

**Auth:** Bearer token  
**Request Body:**
```json
{
  "hashedContacts": [
    "sha256_hash_1",
    "sha256_hash_2"
  ]
}
```

**Response:** `200 OK`
```json
{
  "matches": [
    {
      "userId": "string",
      "username": "friend_from_contacts",
      "contactHash": "sha256_hash_1",
      "isFriend": false
    }
  ]
}
```

**Privacy & Security:**
- Client hashes phone/email with salt (provided by server)
- Server only stores hashes, never raw contacts
- User must consent to contact sync
- Minimal data returned (only username + userId)
- User can revoke consent anytime

**Implementation:**
1. Client requests salt: `GET /contacts/salt`
2. Client hashes contacts: `SHA256(salt + E.164_phone)` or `SHA256(salt + email)`
3. Client sends hashes to server
4. Server matches against user table (indexed on hashed_contact)
5. Return matches

---

## Daily Quests Endpoints

### GET /quests/daily
Get user's daily quests

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "date": "2024-01-15",
  "quests": [
    {
      "id": "play_3_games",
      "type": "playGames",
      "title": "Play 3 Games",
      "description": "Complete 3 games in any mode",
      "targetValue": 3,
      "currentValue": 1,
      "progress": 0.33,
      "coinReward": 100,
      "emoji": "🎮",
      "isCompleted": false
    },
    {
      "id": "correct_20",
      "type": "correctAnswers",
      "title": "Answer Correctly",
      "description": "Get 20 correct answers",
      "targetValue": 20,
      "currentValue": 15,
      "progress": 0.75,
      "coinReward": 150,
      "emoji": "✅",
      "isCompleted": false
    }
  ],
  "completedCount": 0,
  "totalCount": 4,
  "allCompleted": false,
  "nextReset": "ISO8601"
}
```

**Notes:**
- Quests reset daily at midnight UTC
- 4 random quests generated per day
- Progress tracked server-side

---

### POST /quests/daily/:questId/progress
Update quest progress (internal, called by game session)

**Auth:** Bearer token + Internal validation  
**Request Body:**
```json
{
  "increment": number
}
```

**Response:** `200 OK`
```json
{
  "quest": {
    "id": "play_3_games",
    "currentValue": 2,
    "progress": 0.67,
    "isCompleted": false
  }
}
```

**Triggers:**
- Automatically called when user completes actions (game, correct answer, etc.)
- Can trigger multiple quest updates per action

---

### POST /quests/daily/:questId/claim
Claim quest reward (currently not needed - auto-awarded)

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "quest": {
    "id": "play_3_games",
    "isCompleted": true,
    "isClaimed": true
  },
  "reward": {
    "coins": 100
  },
  "userCoins": 650
}
```

---

## Retention & Rewards Endpoints

### GET /retention/comeback-bonus
Check for comeback bonus (after being away)

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "eligible": true,
  "daysAway": 5,
  "bonus": {
    "coins": 250,
    "message": "Welcome back! Here's a comeback bonus!"
  }
}
```

**Response (not eligible):**
```json
{
  "eligible": false,
  "lastLogin": "ISO8601"
}
```

**Rules:**
- 2 days away: 100 coins
- 3-6 days: 250 coins
- 7+ days: 500 coins

---

### POST /retention/comeback-bonus/claim
Claim comeback bonus

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "claimed": true,
  "bonus": {
    "coins": 250
  },
  "userCoins": 900
}
```

---

### GET /rewards/daily
Get available daily rewards (summary)

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "dailyLoginReward": {
    "available": true,
    "day": 3,
    "coins": 100
  },
  "luckySpinReward": {
    "available": true,
    "message": "Spin the wheel for a chance to win up to 1000 coins!"
  },
  "freeCoinsReward": {
    "available": false,
    "nextAvailableAt": "ISO8601",
    "cooldownMinutes": 135
  },
  "dailyQuestsReward": {
    "completedCount": 2,
    "totalCount": 4,
    "availableCoins": 200
  }
}
```

---

## Monetization Endpoints

### POST /purchases/verify
Verify in-app purchase receipt

**Auth:** Bearer token  
**Request Body:**
```json
{
  "platform": "ios" | "android",
  "receipt": "string (base64 encoded)",
  "productId": "string",
  "transactionId": "string"
}
```

**Response:** `200 OK`
```json
{
  "verified": true,
  "purchase": {
    "id": "string",
    "productId": "coin_pack_500",
    "platform": "ios",
    "transactionId": "string",
    "purchaseDate": "ISO8601",
    "status": "completed"
  },
  "rewards": {
    "coins": 500
  },
  "userCoins": 1400
}
```

**Validations:**
- Verify receipt with Apple/Google servers
- Check for duplicate transactions
- Validate product ID
- Award appropriate coins

**Error Response:** `400 Bad Request`
```json
{
  "error": "invalid_receipt",
  "message": "Receipt verification failed",
  "details": "Receipt is invalid or expired"
}
```

---

### POST /subscriptions/verify
Verify subscription receipt (for premium features)

**Auth:** Bearer token  
**Request Body:**
```json
{
  "platform": "ios" | "android",
  "receipt": "string",
  "subscriptionId": "string"
}
```

**Response:** `200 OK`
```json
{
  "verified": true,
  "subscription": {
    "id": "string",
    "type": "sat" | "gmat" | "all_access" | "premium",
    "status": "active",
    "startDate": "ISO8601",
    "expiryDate": "ISO8601",
    "autoRenew": true
  },
  "entitlements": {
    "hasSatSubscription": true,
    "hasGmatSubscription": false,
    "hasAllAccessSubscription": false,
    "isPremium": false
  }
}
```

**Notes:**
- Subscriptions require server-side validation on every app launch
- Implement webhook listeners for Apple/Google subscription notifications
- Handle grace periods, billing retry, and cancellations

---

### GET /store/products
Get available coin packages and subscriptions

**Auth:** Bearer token  
**Response:** `200 OK`
```json
{
  "coinPackages": [
    {
      "id": "coin_pack_100",
      "coins": 100,
      "price": "$0.99",
      "priceUSD": 0.99,
      "bonus": 0,
      "popular": false
    },
    {
      "id": "coin_pack_500",
      "coins": 500,
      "price": "$4.99",
      "priceUSD": 4.99,
      "bonus": 50,
      "popular": true
    }
  ],
  "subscriptions": [
    {
      "id": "premium_monthly",
      "name": "Premium Monthly",
      "price": "$9.99",
      "priceUSD": 9.99,
      "benefits": [
        "No ads",
        "Double coin rewards",
        "Unlimited energy",
        "Exclusive content"
      ],
      "billingPeriod": "month"
    }
  ]
}
```

---

### POST /ads/reward
Grant coins for watching rewarded ad

**Auth:** Bearer token + Server validation  
**Request Body:**
```json
{
  "adType": "rewarded" | "rewarded_interstitial",
  "adNetwork": "google" | "other",
  "adUnitId": "string",
  "rewardAmount": 50,
  "context": "daily_reward" | "game_over" | "lucky_spin" | "free_coins"
}
```

**Response:** `200 OK`
```json
{
  "reward": {
    "coins": 50
  },
  "userCoins": 1050,
  "transaction": {
    "id": "string",
    "type": "ad_reward",
    "timestamp": "ISO8601"
  }
}
```

**Security:**
- Validate ad completion server-side if possible (use Google Ad Manager callbacks)
- Rate limit: 20 ads per day per user
- Implement cooldown: 1 minute between ads

**Error Response:** `429 Too Many Requests`
```json
{
  "error": "rate_limit_exceeded",
  "message": "You've watched too many ads today. Try again tomorrow.",
  "nextAvailableAt": "ISO8601"
}
```

---

## Leaderboards Endpoints

### GET /leaderboards/global
Get global leaderboard

**Auth:** Bearer token  
**Query Params:**
```
period: "all_time" | "weekly" | "monthly" (default "all_time")
page: number (default 1)
limit: number (default 50, max 100)
```

**Response:** `200 OK`
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "string",
      "username": "TopPlayer",
      "totalScore": 156780,
      "gamesPlayed": 1245,
      "accuracy": 0.89,
      "country": "Kenya"
    }
  ],
  "myRank": {
    "rank": 523,
    "totalScore": 13325,
    "percentile": 75.5
  },
  "pagination": {...}
}
```

**Cache:** Can be cached for 5 minutes

---

### GET /leaderboards/friends
Get friends leaderboard

**Auth:** Bearer token  
**Query Params:**
```
period: "all_time" | "weekly" | "monthly"
```

**Response:** `200 OK`
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "string",
      "username": "friend1",
      "totalScore": 25430,
      "gamesPlayed": 345
    }
  ],
  "myRank": {
    "rank": 5,
    "totalScore": 13325
  }
}
```

---

### GET /leaderboards/countries
Get leaderboard by country

**Auth:** Bearer token  
**Query Params:**
```
country: string (ISO 3166-1, required)
period: "all_time" | "weekly" | "monthly"
page: number
limit: number
```

**Response:** `200 OK` (same structure as global)

---

## Admin & Moderation Endpoints

### POST /admin/questions
Create/update question (admin only)

**Auth:** Bearer token + Admin role  
**Request Body:**
```json
{
  "text": "string",
  "options": ["string", "string", "string", "string"],
  "correctIndex": number,
  "explanation": "string",
  "category": "string",
  "difficulty": "string",
  "mode": "string",
  "gradeLevel": "string | null",
  "source": "CURATED" | "AI",
  "language": "EN",
  "countryTag": "string | null"
}
```

**Response:** `201 Created`
```json
{
  "question": {...},
  "status": "pending_review" | "approved"
}
```

---

### GET /admin/reports
Get question reports (admin only)

**Auth:** Bearer token + Admin role  
**Query Params:**
```
status: "pending" | "reviewed" | "resolved"
page: number
limit: number
```

**Response:** `200 OK`
```json
{
  "reports": [
    {
      "id": "string",
      "questionId": "string",
      "question": {...},
      "userId": "string",
      "reason": "incorrect_answer",
      "description": "The answer is wrong...",
      "status": "pending",
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {...}
}
```

---

### PATCH /admin/reports/:reportId
Update report status

**Auth:** Bearer token + Admin role  
**Request Body:**
```json
{
  "status": "reviewed" | "resolved",
  "action": "fixed" | "dismissed" | "question_removed",
  "notes": "string"
}
```

**Response:** `200 OK`
```json
{
  "report": {
    "id": "string",
    "status": "resolved",
    "action": "fixed",
    "reviewedBy": "string",
    "reviewedAt": "ISO8601"
  }
}
```

---

### POST /admin/users/:userId/ban
Ban user (admin only)

**Auth:** Bearer token + Admin role  
**Request Body:**
```json
{
  "reason": "string",
  "duration": "number | null", // days, null = permanent
  "deleteData": boolean
}
```

**Response:** `200 OK`
```json
{
  "user": {
    "id": "string",
    "status": "banned",
    "bannedUntil": "ISO8601 | null",
    "reason": "string"
  }
}
```

---

### GET /admin/feature-flags
Get feature flags (admin only)

**Auth:** Bearer token + Admin role  
**Response:** `200 OK`
```json
{
  "flags": {
    "daily_challenges_enabled": true,
    "leagues_enabled": true,
    "multiplayer_enabled": true,
    "ai_questions_enabled": false,
    "maintenance_mode": false
  }
}
```

---

### PATCH /admin/feature-flags
Update feature flags

**Auth:** Bearer token + Admin role  
**Request Body:**
```json
{
  "flags": {
    "daily_challenges_enabled": true,
    "maintenance_mode": false
  }
}
```

**Response:** `200 OK` (same as GET)

---

## Data Model (PostgreSQL Tables)

### users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE,
  hashed_contact VARCHAR(64) UNIQUE, -- For contact sync
  is_guest BOOLEAN DEFAULT true,
  
  -- Age & consent (COPPA)
  age INTEGER,
  parental_consent BOOLEAN DEFAULT false,
  parent_email VARCHAR(255),
  
  -- Profile
  country VARCHAR(2),
  coins INTEGER DEFAULT 100 CHECK (coins >= 0),
  streak_count INTEGER DEFAULT 0,
  consecutive_login_days INTEGER DEFAULT 1,
  
  -- Timestamps for retention
  last_login_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_daily_challenge TIMESTAMP WITH TIME ZONE,
  last_free_coins_claim_date TIMESTAMP WITH TIME ZONE,
  has_claimed_daily_login_reward BOOLEAN DEFAULT false,
  last_lucky_spin_date DATE,
  
  -- Education mode
  education_mode_enabled BOOLEAN DEFAULT false,
  school_system VARCHAR(50),
  grade_level VARCHAR(20),
  challenge_grade_level VARCHAR(20),
  exam_focus VARCHAR(20) DEFAULT 'NONE',
  
  -- Subscriptions
  has_sat_subscription BOOLEAN DEFAULT false,
  has_gmat_subscription BOOLEAN DEFAULT false,
  has_all_access_subscription BOOLEAN DEFAULT false,
  is_premium BOOLEAN DEFAULT false,
  
  -- Soft delete
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  CHECK (age >= 5 OR age IS NULL),
  CHECK (age >= 13 OR parental_consent = true OR age IS NULL)
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_hashed_contact ON users(hashed_contact);
CREATE INDEX idx_users_country ON users(country);
CREATE INDEX idx_users_deleted_at ON users(deleted_at);
```

### user_stats
```sql
CREATE TABLE user_stats (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  questions_answered INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  total_score BIGINT DEFAULT 0,
  accuracy DECIMAL(5,4) DEFAULT 0.0,
  games_played INTEGER DEFAULT 0,
  
  -- Leaderboard ranks (cached)
  global_rank INTEGER,
  weekly_rank INTEGER,
  country_rank INTEGER,
  
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_stats_total_score ON user_stats(total_score DESC);
CREATE INDEX idx_user_stats_accuracy ON user_stats(accuracy DESC);
```

### auth_tokens
```sql
CREATE TABLE auth_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token VARCHAR(255) UNIQUE NOT NULL,
  device_id VARCHAR(255),
  platform VARCHAR(20),
  is_revoked BOOLEAN DEFAULT false,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_auth_tokens_user_id ON auth_tokens(user_id);
CREATE INDEX idx_auth_tokens_refresh_token ON auth_tokens(refresh_token);
CREATE INDEX idx_auth_tokens_expires_at ON auth_tokens(expires_at);
```

### questions
```sql
CREATE TABLE questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  text TEXT NOT NULL,
  options JSONB NOT NULL, -- Array of 4 options
  correct_index INTEGER NOT NULL CHECK (correct_index BETWEEN 0 AND 3),
  explanation TEXT NOT NULL,
  
  -- Classification
  category VARCHAR(50) NOT NULL,
  difficulty VARCHAR(20) NOT NULL,
  topic VARCHAR(50),
  mode VARCHAR(50) DEFAULT 'GENERAL',
  grade_level VARCHAR(20),
  
  -- Metadata
  source VARCHAR(20) DEFAULT 'CURATED', -- 'CURATED' or 'AI'
  language VARCHAR(5) DEFAULT 'EN',
  country_tag VARCHAR(2),
  
  -- Quality metrics
  times_answered INTEGER DEFAULT 0,
  times_correct INTEGER DEFAULT 0,
  avg_time_seconds DECIMAL(6,2),
  report_count INTEGER DEFAULT 0,
  
  -- Moderation
  status VARCHAR(20) DEFAULT 'approved',
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_questions_category ON questions(category);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_mode ON questions(mode);
CREATE INDEX idx_questions_grade_level ON questions(grade_level);
CREATE INDEX idx_questions_status ON questions(status);
CREATE INDEX idx_questions_mode_category_difficulty ON questions(mode, category, difficulty);
```

### game_sessions
```sql
CREATE TABLE game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Session info
  mode VARCHAR(20) NOT NULL,
  category VARCHAR(50),
  difficulty VARCHAR(20),
  question_count INTEGER,
  
  -- Results
  questions_answered INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  final_score INTEGER,
  time_spent_seconds INTEGER,
  accuracy DECIMAL(5,4),
  
  -- Related entities
  league_id UUID REFERENCES leagues(id),
  room_code VARCHAR(10),
  campaign_round_number INTEGER,
  
  -- Timestamps
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  
  -- Anti-cheat
  is_suspicious BOOLEAN DEFAULT false,
  cheat_flags JSONB
);

CREATE INDEX idx_game_sessions_user_id ON game_sessions(user_id);
CREATE INDEX idx_game_sessions_mode ON game_sessions(mode);
CREATE INDEX idx_game_sessions_started_at ON game_sessions(started_at DESC);
CREATE INDEX idx_game_sessions_suspicious ON game_sessions(is_suspicious);
```

### game_session_answers
```sql
CREATE TABLE game_session_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id),
  
  selected_index INTEGER,
  is_correct BOOLEAN,
  time_spent_ms INTEGER,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  -- Anti-cheat
  is_suspicious BOOLEAN DEFAULT false
);

CREATE INDEX idx_game_session_answers_session_id ON game_session_answers(session_id);
CREATE INDEX idx_game_session_answers_question_id ON game_session_answers(question_id);
```

### campaign_progress
```sql
CREATE TABLE campaign_progress (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  round_number INTEGER NOT NULL,
  
  is_completed BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT true,
  best_score INTEGER,
  stars_earned INTEGER CHECK (stars_earned BETWEEN 0 AND 3),
  
  completed_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  PRIMARY KEY (user_id, round_number)
);

CREATE INDEX idx_campaign_progress_user_id ON campaign_progress(user_id);
```

### rooms
```sql
CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(10) UNIQUE NOT NULL,
  host_user_id UUID NOT NULL REFERENCES users(id),
  
  -- Room config
  topic VARCHAR(50) NOT NULL,
  max_players INTEGER NOT NULL CHECK (max_players BETWEEN 2 AND 8),
  total_questions INTEGER NOT NULL CHECK (total_questions BETWEEN 5 AND 20),
  entry_fee INTEGER NOT NULL DEFAULT 50 CHECK (entry_fee >= 0),
  prize_pot INTEGER NOT NULL DEFAULT 0,
  
  -- State
  is_active BOOLEAN DEFAULT true,
  game_started BOOLEAN DEFAULT false,
  game_session_id UUID REFERENCES game_sessions(id),
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_rooms_code ON rooms(code);
CREATE INDEX idx_rooms_host_user_id ON rooms(host_user_id);
CREATE INDEX idx_rooms_is_active ON rooms(is_active);
```

### room_players
```sql
CREATE TABLE room_players (
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  username VARCHAR(20) NOT NULL,
  score INTEGER DEFAULT 0,
  is_ready BOOLEAN DEFAULT false,
  
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  PRIMARY KEY (room_id, user_id)
);

CREATE INDEX idx_room_players_room_id ON room_players(room_id);
CREATE INDEX idx_room_players_user_id ON room_players(user_id);
```

### leagues
```sql
CREATE TABLE leagues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  
  -- Config
  topic VARCHAR(50) NOT NULL,
  tier VARCHAR(20) NOT NULL,
  entry_fee INTEGER NOT NULL CHECK (entry_fee >= 0),
  max_participants INTEGER NOT NULL,
  total_questions INTEGER DEFAULT 10,
  
  -- Schedule
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  
  -- Prizes distributed
  prizes_distributed BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  CHECK (end_date > start_date)
);

CREATE INDEX idx_leagues_topic ON leagues(topic);
CREATE INDEX idx_leagues_tier ON leagues(tier);
CREATE INDEX idx_leagues_is_active ON leagues(is_active);
CREATE INDEX idx_leagues_start_date ON leagues(start_date DESC);
```

### league_participants
```sql
CREATE TABLE league_participants (
  league_id UUID NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  username VARCHAR(20) NOT NULL,
  score INTEGER DEFAULT 0,
  rank INTEGER,
  
  prize_won INTEGER DEFAULT 0,
  prize_awarded BOOLEAN DEFAULT false,
  
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  PRIMARY KEY (league_id, user_id)
);

CREATE INDEX idx_league_participants_league_id ON league_participants(league_id);
CREATE INDEX idx_league_participants_score ON league_participants(league_id, score DESC);
```

### friendships
```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id_1 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_id_2 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
  requested_by UUID NOT NULL REFERENCES users(id),
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  CHECK (user_id_1 < user_id_2), -- Ensure ordered pair
  UNIQUE(user_id_1, user_id_2)
);

CREATE INDEX idx_friendships_user_id_1 ON friendships(user_id_1);
CREATE INDEX idx_friendships_user_id_2 ON friendships(user_id_2);
CREATE INDEX idx_friendships_status ON friendships(status);
```

### invite_codes
```sql
CREATE TABLE invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(20) UNIQUE NOT NULL,
  inviter_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  usage_count INTEGER DEFAULT 0,
  usage_limit INTEGER DEFAULT 10,
  
  rewards JSONB, -- {inviter: 100, invitee: 100}
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_invite_codes_code ON invite_codes(code);
CREATE INDEX idx_invite_codes_inviter ON invite_codes(inviter_user_id);
```

### invite_code_redemptions
```sql
CREATE TABLE invite_code_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id UUID NOT NULL REFERENCES invite_codes(id) ON DELETE CASCADE,
  inviter_user_id UUID NOT NULL REFERENCES users(id),
  invitee_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  rewards_awarded BOOLEAN DEFAULT false,
  
  redeemed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  UNIQUE(code_id, invitee_user_id)
);

CREATE INDEX idx_invite_redemptions_invitee ON invite_code_redemptions(invitee_user_id);
```

### daily_quests
```sql
CREATE TABLE daily_quests (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  quest_id VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  
  quest_type VARCHAR(50) NOT NULL,
  title VARCHAR(100) NOT NULL,
  description TEXT,
  target_value INTEGER NOT NULL,
  current_value INTEGER DEFAULT 0,
  coin_reward INTEGER NOT NULL,
  
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  PRIMARY KEY (user_id, quest_id, date)
);

CREATE INDEX idx_daily_quests_user_date ON daily_quests(user_id, date);
CREATE INDEX idx_daily_quests_completed ON daily_quests(is_completed);
```

### coin_transactions
```sql
CREATE TABLE coin_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  amount INTEGER NOT NULL, -- Can be negative
  balance_after INTEGER NOT NULL,
  reason VARCHAR(50) NOT NULL,
  
  -- Related entities
  game_session_id UUID REFERENCES game_sessions(id),
  purchase_id UUID,
  quest_id VARCHAR(50),
  
  metadata JSONB,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_coin_transactions_user_id ON coin_transactions(user_id);
CREATE INDEX idx_coin_transactions_created_at ON coin_transactions(created_at DESC);
CREATE INDEX idx_coin_transactions_reason ON coin_transactions(reason);
```

### purchases
```sql
CREATE TABLE purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Purchase details
  product_id VARCHAR(100) NOT NULL,
  platform VARCHAR(20) NOT NULL,
  transaction_id VARCHAR(255) UNIQUE NOT NULL,
  receipt TEXT NOT NULL,
  
  -- Item details
  item_type VARCHAR(50) NOT NULL, -- 'coins', 'subscription'
  coins_awarded INTEGER,
  subscription_type VARCHAR(50),
  
  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  verified_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_purchases_user_id ON purchases(user_id);
CREATE INDEX idx_purchases_transaction_id ON purchases(transaction_id);
CREATE INDEX idx_purchases_status ON purchases(status);
```

### subscriptions
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  subscription_type VARCHAR(50) NOT NULL,
  platform VARCHAR(20) NOT NULL,
  product_id VARCHAR(100) NOT NULL,
  transaction_id VARCHAR(255) UNIQUE NOT NULL,
  
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
  auto_renew BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_expiry_date ON subscriptions(expiry_date);
```

### question_reports
```sql
CREATE TABLE question_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  
  reason VARCHAR(50) NOT NULL,
  description TEXT,
  
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  action_taken VARCHAR(50),
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_question_reports_question_id ON question_reports(question_id);
CREATE INDEX idx_question_reports_status ON question_reports(status);
```

### feature_flags
```sql
CREATE TABLE feature_flags (
  key VARCHAR(100) PRIMARY KEY,
  value BOOLEAN NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES users(id),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

---

## Realtime/Multiplayer (Socket.IO)

### Socket.IO Events

**Connection:**
```javascript
// Client connects with auth token
socket.on('connect', () => {
  socket.emit('authenticate', { token: '<access_token>' });
});

// Server responds
socket.emit('authenticated', { userId: '<user_id>' });
```

### Room Events

**Join Room:**
```javascript
// Client
socket.emit('room:join', { code: 'ABC123' });

// Server broadcasts to all in room
socket.broadcast.to(roomCode).emit('room:player_joined', {
  player: {
    userId: 'string',
    username: 'string',
    isReady: false
  }
});

// Server sends to joiner
socket.emit('room:joined', {
  room: {...}
});
```

**Player Ready:**
```javascript
// Client
socket.emit('room:ready', { roomCode: 'ABC123', isReady: true });

// Server broadcasts
socket.broadcast.to(roomCode).emit('room:player_ready', {
  userId: 'string',
  isReady: true
});

// If all ready
socket.to(roomCode).emit('room:all_ready', {
  allReady: true,
  canStart: true
});
```

**Game Start:**
```javascript
// Client (host only)
socket.emit('room:start_game', { roomCode: 'ABC123' });

// Server broadcasts
socket.to(roomCode).emit('room:game_started', {
  sessionId: 'string',
  questions: [...], // Questions sent to each player
  startedAt: 'ISO8601'
});
```

**Score Update:**
```javascript
// Client
socket.emit('room:score_update', {
  roomCode: 'ABC123',
  score: 875
});

// Server broadcasts
socket.broadcast.to(roomCode).emit('room:player_score', {
  userId: 'string',
  username: 'string',
  score: 875
});
```

**Game Complete:**
```javascript
// Client
socket.emit('room:game_complete', {
  roomCode: 'ABC123',
  finalScore: 1250
});

// When all players complete, server broadcasts
socket.to(roomCode).emit('room:game_ended', {
  rankings: [...],
  prizes: {...}
});
```

**Leave Room:**
```javascript
// Client
socket.emit('room:leave', { roomCode: 'ABC123' });

// Server broadcasts
socket.broadcast.to(roomCode).emit('room:player_left', {
  userId: 'string',
  username: 'string',
  newHost: 'string | null' // If host left
});
```

### Error Events
```javascript
socket.emit('error', {
  code: 'ROOM_NOT_FOUND',
  message: 'Room does not exist or has expired'
});
```

### Socket.IO Rooms
- Each multiplayer room maps to a Socket.IO room
- Players automatically subscribed/unsubscribed on join/leave
- Server maintains room state and synchronizes

---

## Error Responses

### Standard Error Format

```json
{
  "error": "error_code",
  "message": "Human-readable error message",
  "details": "Additional context (optional)",
  "field": "fieldName (for validation errors)",
  "timestamp": "ISO8601"
}
```

### Common Error Codes

**Authentication:**
- `invalid_token` - Token expired or invalid
- `unauthorized` - Not authenticated
- `forbidden` - Insufficient permissions

**Validation:**
- `validation_error` - Request validation failed
- `missing_field` - Required field missing
- `invalid_format` - Field format invalid

**Business Logic:**
- `insufficient_coins` - Not enough coins
- `insufficient_stars` - Not enough stars
- `already_claimed` - Reward already claimed
- `already_completed` - Quest/challenge already done
- `cooldown_active` - Feature on cooldown
- `rate_limit_exceeded` - Too many requests

**Resources:**
- `not_found` - Resource not found
- `already_exists` - Resource already exists
- `room_full` - Room at max capacity
- `league_full` - League at max participants

**COPPA/Age:**
- `age_restriction` - User age too young
- `parental_consent_required` - Need parent consent

---

## Rate Limiting

### Per-Endpoint Limits

| Endpoint Group | Limit | Window |
|---------------|-------|--------|
| Auth (login/register) | 5 | 1 minute |
| Auth (refresh) | 10 | 1 minute |
| Questions fetch | 30 | 1 minute |
| Game submission | 60 | 1 minute |
| User profile updates | 10 | 1 minute |
| Friend requests | 20 | 1 hour |
| Ad rewards | 20 | 1 day |
| Lucky spin | 1 | 1 day |
| Free coins | 1 | 4 hours |
| Default | 100 | 1 minute |

### Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

### Rate Limit Response

`429 Too Many Requests`
```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Please try again later.",
  "retryAfter": 30
}
```

---

## Third-Party Integrations

### 1. Google Mobile Ads

**Purpose:** Rewarded ads for free coins  
**Integration:**
- SDK integrated in Flutter app
- Server validates ad completion via callbacks (if available)
- Alternative: Trust client + rate limiting

**Ad Rewards:**
- Rewarded video: 50 coins
- Rewarded interstitial: 25 coins
- Rate limit: 20 ads/day per user

### 2. In-App Purchases (Apple/Google)

**Apple App Store:**
- Receipt validation via App Store Server API
- Webhook for subscription status updates
- Grace periods and billing retry handling

**Google Play Store:**
- Receipt validation via Google Play Developer API
- Real-time developer notifications via Pub/Sub
- Subscription lifecycle management

**Products:**
- Coin packs: 100, 500, 1000, 2500, 5000
- Subscriptions: Monthly Premium, SAT Monthly, GMAT Monthly, All-Access Monthly

### 3. AI Question Generation (OpenAI/Google Gemini)

**Purpose:** Generate quiz questions dynamically  
**Integration:**
- Server-side only (never expose API keys to client)
- Async job queue for batch generation
- Questions require manual review before approval

**API Endpoints:**
- OpenAI: `https://api.openai.com/v1/chat/completions`
- Gemini: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`

**Security:**
- API keys stored as environment variables
- Rate limiting + cost monitoring
- Implement fallback to curated questions

### 4. Analytics (Optional - not in current code)

**Recommendations:**
- Mixpanel or Amplitude for user behavior
- Google Analytics for Firebase for mobile analytics
- Custom events: game_started, game_completed, coins_earned, purchase_made, etc.

### 5. Email (Optional - for parent consent, password reset)

**Recommendations:**
- SendGrid or Amazon SES
- Templates for parental consent, account verification
- COPPA-compliant data collection

### 6. Push Notifications (Not in current code)

**Recommendations:**
- Firebase Cloud Messaging (FCM)
- Use cases: Friend request, daily challenge available, league ending soon, comeback reminder

---

## Missing/Ambiguous Items & Assumptions

### Missing/Unclear from Code

1. **Authentication:**
   - **Missing:** Password/email authentication (app only has guest + username)
   - **Assumption:** Implementing simple username-based auth + device binding
   - **Recommendation:** Add email/password auth for account recovery

2. **Friends System:**
   - **Missing:** Friend search, friend requests, contact sync implementation
   - **Assumption:** Basic friend system with username search + invite codes
   - **Recommendation:** Implement contact hashing for privacy-safe discovery

3. **Multiplayer Matchmaking:**
   - **Missing:** Automated matchmaking (only manual room codes exist)
   - **Assumption:** Phase 1 = room codes only, Phase 2 = add matchmaking
   - **Recommendation:** Implement skill-based matchmaking queue

4. **Daily Challenge:**
   - **Ambiguous:** Are questions same for all users?
   - **Assumption:** Yes, same questions for all users each day (promotes competition)

5. **Campaign Mode:**
   - **Ambiguous:** 500 rounds generated client-side, should server validate?
   - **Assumption:** Server stores round definitions, validates unlock logic
   - **Recommendation:** Migrate round generation to server for consistency

6. **Question Source:**
   - **Missing:** Question database/seeding strategy
   - **Assumption:** Initial seed with curated questions, later add AI-generated
   - **Recommendation:** Start with 1000+ curated questions per category

7. **Leaderboards:**
   - **Ambiguous:** How often to recalculate ranks?
   - **Assumption:** Update on game completion + nightly batch recalculation
   - **Recommendation:** Cache ranks, update every 5 minutes for top 100

8. **Premium Features:**
   - **Ambiguous:** What exactly does premium unlock?
   - **Assumption:** No ads, double coins, unlimited energy, exclusive questions
   - **Current Code:** Only checks isPremium flag for ads

9. **Education Subscriptions:**
   - **Ambiguous:** SAT/GMAT subscription benefits
   - **Assumption:** Unlock exam-specific question packs + study tools
   - **Current Code:** Only stores boolean flags, no enforcement

10. **Coins Anti-Cheat:**
    - **Missing:** Server-side coin balance tracking
    - **Assumption:** Server is source of truth, client updates are validated
    - **Recommendation:** All coin transactions logged, suspicious activity flagged

11. **Game Session Anti-Cheat:**
    - **Missing:** Timing validation, answer sequence validation
    - **Assumption:** Server stores questions per session, validates answers
    - **Recommendation:** Flag sessions with impossible times or patterns

12. **Data Deletion (COPPA):**
    - **Missing:** Implementation details for account deletion
    - **Assumption:** 30-day soft delete, then permanent anonymization
    - **Recommendation:** Automated job to purge data after grace period

13. **Parental Consent Flow:**
    - **Missing:** Email verification for parents
    - **Assumption:** Parent email required, verification link sent
    - **Recommendation:** Store consent timestamp, allow parent to revoke

14. **Server-Side Scoring:**
    - **Ambiguous:** How detailed should anti-cheat be?
    - **Assumption:** Store all answers with timestamps, validate on completion
    - **Recommendation:** ML model to detect cheating patterns (future)

15. **Invite Code Redemption:**
    - **Ambiguous:** When are rewards awarded?
    - **Assumption:** Rewards awarded immediately on redemption
    - **Alternative:** Award after invitee completes first game (better retention)

### Assumptions Made

1. **Token Expiry:** Access tokens expire in 15 minutes, refresh tokens in 30 days
2. **Guest Conversion:** Guest accounts can be upgraded to full accounts without losing progress
3. **Coin Floor:** Coins cannot go negative (minimum 0)
4. **Question Caching:** Questions can be cached client-side for 24 hours
5. **Session Expiry:** Game sessions expire after 30 minutes of inactivity
6. **Room Expiry:** Multiplayer rooms expire after 2 hours if game hasn't started
7. **League Duration:** Leagues typically run for 7 days
8. **Daily Reset:** All daily features reset at midnight UTC
9. **Leaderboard Update:** Global leaderboard updates every 5 minutes (cached)
10. **Ad Reward Trust:** Initially trust client for ad completion (with rate limits)

---

## Frontend Screen → Endpoints Mapping

### Splash Screen
- No API calls (loads cached data)

### Onboarding Screen (if new user)
- `POST /auth/guest` - Create guest account
- `POST /auth/register` - Register full account

### Home Screen
- `GET /users/me` - Get user profile
- `GET /quests/daily` - Get daily quests
- `GET /rewards/daily` - Get available daily rewards
- `POST /users/me/login-reward` - Claim daily login reward
- `POST /users/me/free-coins` - Claim free coins
- `POST /users/me/lucky-spin` - Spin lucky wheel

### Profile Screen
- `GET /users/me` - Get user profile
- `PATCH /users/me` - Update profile
- `GET /leaderboards/global` - Get user rank

### Education Settings Screen
- `GET /users/me` - Get education settings
- `PATCH /users/me` - Update education settings

### Category Select Screen
- `GET /questions/categories` - Get available categories

### Game Screen
- `POST /game-sessions` - Start game session
- `POST /game-sessions/:id/answer` - Submit each answer
- `POST /game-sessions/:id/complete` - Complete session

### Results Screen
- `POST /ads/reward` - Claim ad reward for double points
- (Session completion already called from Game Screen)

### Daily Quests Screen
- `GET /quests/daily` - Get daily quests
- `POST /quests/daily/:id/progress` - Update quest progress (automatic)

### Campaign Screen
- `GET /campaign/progress` - Get campaign progress
- `POST /campaign/rounds/:id/start` - Start round
- `POST /campaign/rounds/:id/complete` - Complete round
- `GET /campaign/leaderboard` - Get campaign leaderboard

### Leagues Screen
- `GET /leagues` - List leagues
- `POST /leagues/:id/join` - Join league
- `GET /leagues/:id/leaderboard` - Get league leaderboard

### League Results Screen
- `GET /leagues/:id/results` - Get final results
- `POST /leagues/:id/score` - Submit score (automatic)

### Play With Friends Screen
- `POST /rooms` - Create room
- `POST /rooms/join` - Join room by code
- `GET /rooms/:code` - Get room details
- `PATCH /rooms/:code/ready` - Set ready status
- `POST /rooms/:code/start` - Start game (host)
- `DELETE /rooms/:code/leave` - Leave room

### Multiplayer Lobby Screen (Socket.IO)
- `socket.emit('room:join')` - Join room
- `socket.emit('room:ready')` - Set ready
- `socket.on('room:player_joined')` - Player joined
- `socket.on('room:player_ready')` - Player ready
- `socket.on('room:all_ready')` - All ready
- `socket.on('room:game_started')` - Game started

### Multiplayer Results Screen
- `GET /rooms/:code/results` - Get final results
- `socket.on('room:game_ended')` - Game ended event

### Friends Screen (Future)
- `GET /friends` - Get friend list
- `POST /friends/search` - Search users
- `POST /friends/request` - Send friend request
- `POST /friends/request/:id/accept` - Accept request
- `POST /friends/request/:id/decline` - Decline request
- `DELETE /friends/:id` - Remove friend
- `POST /friends/invite-code` - Generate invite code
- `POST /friends/redeem-code` - Redeem invite code

### Coin Store Screen
- `GET /store/products` - Get coin packages
- `POST /purchases/verify` - Verify purchase
- `POST /ads/reward` - Watch ad for coins

### Premium Screen
- `GET /store/products` - Get subscription products
- `POST /subscriptions/verify` - Verify subscription
- `GET /users/me` - Check subscription status

### Lucky Spin Screen
- `POST /users/me/lucky-spin` - Spin wheel
- `GET /users/me` - Check if spin available

---

## Implementation Priority

### Phase 1: Core MVP
1. Auth endpoints (guest, register, login, refresh)
2. User profile endpoints
3. Questions endpoints (fetch, categories)
4. Game session endpoints (start, answer, complete)
5. Basic coin transactions

### Phase 2: Progression
6. Campaign endpoints
7. Daily quests endpoints
8. Daily login rewards
9. Leaderboards (global)

### Phase 3: Social
10. Friends endpoints (search, request, list)
11. Invite codes
12. Multiplayer rooms (REST + Socket.IO)
13. Friends leaderboard

### Phase 4: Competitive
14. Leagues endpoints
15. League leaderboards
16. Prize distribution

### Phase 5: Monetization
17. IAP verification
18. Subscription verification
19. Ad reward tracking
20. Coin store

### Phase 6: Polish
21. Admin endpoints
22. Moderation endpoints
23. Analytics integration
24. AI question generation

---

## Security Checklist

- [ ] JWT tokens with expiry
- [ ] Refresh token rotation
- [ ] Rate limiting on all endpoints
- [ ] Input validation (Joi/Zod)
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS protection (sanitize user inputs)
- [ ] CORS configuration
- [ ] HTTPS only
- [ ] COPPA compliance (age verification, parental consent)
- [ ] PII encryption at rest
- [ ] Contact hashing for discovery
- [ ] Server-side game validation
- [ ] Anti-cheat detection
- [ ] Receipt verification for purchases
- [ ] API key security (env vars, never client-side)
- [ ] Audit logging for sensitive actions
- [ ] Data deletion (soft delete + grace period)

---

## Performance Checklist

- [ ] Database indexes on all foreign keys
- [ ] Composite indexes for common queries
- [ ] Connection pooling (pg-pool)
- [ ] Redis caching (questions, leaderboards, user sessions)
- [ ] Pagination for all list endpoints
- [ ] Query optimization (avoid N+1)
- [ ] Background jobs for heavy tasks (Bullqueue)
- [ ] CDN for static assets
- [ ] API response compression
- [ ] Database read replicas for leaderboards
- [ ] Batch inserts for game answers
- [ ] Scheduled jobs for daily resets
- [ ] Monitoring (Prometheus, Grafana)
- [ ] Error tracking (Sentry)

---

**END OF API SPECIFICATION**

---

## Document Version History

- v1.0 (2024-01-15): Initial comprehensive API specification derived from MindRush Flutter codebase

