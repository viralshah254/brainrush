# 🔍 API Compatibility Report: Frontend vs Backend

**Generated:** January 17, 2026  
**Purpose:** Identify mismatches between frontend expectations and backend API implementation

---

## ⚠️ Critical Issues

### 1. **Response Format Mismatch**

**Backend API Documentation:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Frontend Specification (BACKEND_API_SPECIFICATION.md):**
- Expects direct data objects (no wrapper)
- Example: `{ "sessionId": "uuid", "questions": [...] }`

**Action Required:**
- Frontend must handle `response.data` wrapper for all API calls
- OR Backend must be updated to match frontend expectations
- **Recommendation:** Update frontend to handle wrapper (more standard)

---

### 2. **Base URL Configuration**

**Backend API Documentation:**
```
Development: http://localhost:3000/api/v1
Production: https://api.mindrush.com/api/v1
```

**Frontend Specification:**
- Mentions various URLs: `api.brainzrush.com`, `api.mindrush.com`
- No consistent base URL defined

**Action Required:**
- Create API configuration file with base URL
- Use: `http://localhost:3000/api/v1` (dev) and `https://api.mindrush.com/api/v1` (prod)

---

## 📋 Endpoint Compatibility Issues

### **Authentication Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `POST /auth/signup` | `POST /auth/signup` | ✅ Match | None |
| `POST /auth/google` | `POST /auth/google` | ✅ Match | None |
| `POST /auth/facebook` | `POST /auth/facebook` | ✅ Match | None |
| `POST /auth/apple` | `POST /auth/apple` | ✅ Match | None |
| `POST /auth/guest` | `POST /auth/guest` | ✅ Match | None |
| `GET /auth/session` | `GET /auth/session` | ✅ Match | None |
| `POST /auth/refresh` | `POST /auth/refresh` | ✅ Match | None |
| `POST /auth/logout` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /auth/guest/upgrade` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Backend missing `POST /auth/logout` endpoint
- Backend missing `POST /auth/guest/upgrade` endpoint

---

### **User Management Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /users/me` | `GET /users/me` | ✅ Match | Handle `data` wrapper |
| `PUT /users/me/username` | `PUT /users/me/username` | ✅ Match | Handle `data` wrapper |
| `PUT /users/me/age` | `PUT /users/me/age` | ✅ Match | Handle `data` wrapper |
| `PUT /users/me/photo` | `PUT /users/me/photo` | ✅ Match | Handle `data` wrapper |
| `GET /users/me/stats` | `GET /users/me/stats` | ✅ Match | Handle `data` wrapper |
| `GET /users/me/wallet` | `GET /users/me/wallet` | ✅ Match | Handle `data` wrapper |
| `GET /users/me/streak` | `GET /users/me/streak` | ✅ Match | Handle `data` wrapper |
| `PUT /users/me/preferences` | `PUT /users/me/preferences` | ✅ Match | Handle `data` wrapper |
| `PUT /users/me/language` | `PUT /users/me/language` | ✅ Match | Handle `data` wrapper |
| `GET /users/search` | `GET /users/search?query=...` | ⚠️ Different | Query param vs body |
| `DELETE /users/me` | `DELETE /users/me` | ✅ Match | Handle `data` wrapper |
| `GET /users/me/preferences` | ❌ Missing | ⚠️ Missing | Add to backend |
| `PUT /users/me/mode` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /users/me/education` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /users/me/login-reward` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /users/me/free-coins` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /users/me/lucky-spin` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /users/me/coins` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- User search: Backend uses query params, frontend spec suggests body
- Missing several user endpoints in backend

---

### **Questions & Quiz Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `POST /questions/practice` | `POST /questions/practice` | ✅ Match | Handle `data` wrapper |
| `POST /questions/education` | `POST /questions/education` | ✅ Match | Handle `data` wrapper |
| `GET /questions/daily` | `GET /questions/daily` | ✅ Match | Handle `data` wrapper |
| `GET /questions/daily-pool` | `GET /questions/daily-pool` | ✅ Match | Handle `data` wrapper |
| `GET /questions/categories` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /quiz/sessions/:id/answer` | `POST /quiz/sessions/:sessionId/answer` | ✅ Match | Handle `data` wrapper |
| `POST /quiz/sessions/:id/extra-time` | `POST /quiz/sessions/:sessionId/extra-time` | ✅ Match | Handle `data` wrapper |
| `POST /quiz/sessions/:id/try-again` | `POST /quiz/sessions/:sessionId/try-again` | ✅ Match | Handle `data` wrapper |
| `POST /quiz/sessions/:id/complete` | `POST /quiz/sessions/:sessionId/complete` | ✅ Match | Handle `data` wrapper |
| `GET /quiz/sessions` | `GET /quiz/sessions?limit=20&offset=0` | ✅ Match | Handle `data` wrapper |
| `GET /challenges/daily/questions` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /challenges/daily/status` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /challenges/daily/reward` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /ads/rewarded/try-again` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /quiz/sessions/:id/timeout` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /users/me/answered-questions` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Missing daily challenge endpoints
- Missing ad reward endpoints
- Missing question categories endpoint

---

### **Campaign Mode Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /campaign/progress` | `GET /campaign/:campaignId/progress` | ⚠️ Different | Path parameter required |
| `GET /campaign/rounds` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /campaign/rounds/:roundId/questions` | `GET /campaign/:campaignId/round/:roundId/questions` | ⚠️ Different | Different path structure |
| `POST /campaign/rounds/:roundId/start` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /campaign/rounds/:roundId/answer` | `POST /campaign/:campaignId/round/:roundId/answer` | ⚠️ Different | Different path structure |
| `POST /campaign/rounds/:roundId/complete` | `POST /campaign/:campaignId/round/:roundId/complete` | ⚠️ Different | Different path structure |
| `GET /campaign/leaderboard` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /campaign` | `GET /campaign` | ✅ Match | Handle `data` wrapper |

**Issues:**
- Backend requires `campaignId` in path, frontend expects campaign-less endpoints
- Missing campaign rounds list endpoint
- Missing campaign leaderboard

---

### **Multiplayer Rooms Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `POST /rooms/create` | `POST /rooms/create` | ✅ Match | Handle `data` wrapper |
| `POST /rooms/:roomCode/join` | `POST /rooms/:roomCode/join` | ✅ Match | Handle `data` wrapper |
| `POST /rooms/join/:inviteToken` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /rooms/:roomCode/leave` | `POST /rooms/:roomCode/leave` | ✅ Match | Handle `data` wrapper |
| `GET /rooms/:roomCode` | `GET /rooms/:roomCode` | ✅ Match | Handle `data` wrapper |
| `PUT /rooms/:roomCode/settings` | `PUT /rooms/:roomCode/settings` | ✅ Match | Handle `data` wrapper |
| `POST /rooms/:roomCode/kick/:userId` | `POST /rooms/:roomCode/kick/:userId` | ✅ Match | Handle `data` wrapper |
| `GET /rooms/:roomCode/questions` | `GET /rooms/:roomCode/questions` | ✅ Match | Handle `data` wrapper |
| `POST /rooms/:roomCode/complete` | `POST /rooms/:roomCode/complete` | ✅ Match | Handle `data` wrapper |
| `GET /rooms/:roomCode/match/:matchId/time-remaining` | `GET /rooms/:roomCode/match/:matchId/time-remaining` | ✅ Match | Handle `data` wrapper |
| `POST /rooms/:roomCode/rematch` | `POST /rooms/:roomCode/rematch` | ✅ Match | Handle `data` wrapper |
| `PATCH /rooms/:roomCode/ready` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /rooms/:roomCode/start` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Missing room ready status endpoint (PATCH)
- Missing room start game endpoint
- Missing invite token join endpoint

---

### **Leagues Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /leagues/active` | `GET /leagues/active` | ✅ Match | Handle `data` wrapper |
| `GET /leagues` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /leagues/:leagueId/join` | `POST /leagues/:leagueId/join` | ✅ Match | Handle `data` wrapper |
| `GET /leagues/:leagueId/leaderboard` | `GET /leagues/:leagueId/leaderboard` | ✅ Match | Handle `data` wrapper |
| `GET /leagues/:leagueId/match/questions` | `GET /leagues/:leagueId/match/questions` | ✅ Match | Handle `data` wrapper |
| `POST /leagues/:leagueId/match/:matchId/complete` | `POST /leagues/:leagueId/match/:matchId/complete` | ✅ Match | Handle `data` wrapper |
| `GET /leagues/:leagueId/results` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /leagues/:leagueId/score` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /leagues/tiers` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /leagues/education/grade/:gradeLevel` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Missing general leagues list endpoint
- Missing league results endpoint
- Missing league score submission endpoint
- Missing league tiers endpoint
- Missing education grade league endpoint

---

### **Friends Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /friends` | `GET /friends` | ✅ Match | Handle `data` wrapper |
| `GET /friends/list` | ❌ Missing | ⚠️ Missing | Use `/friends` instead |
| `GET /friends/search` | `GET /friends/search?query=...` | ✅ Match | Handle `data` wrapper |
| `GET /users/search` | `GET /users/search?query=...` | ✅ Match | Handle `data` wrapper |
| `POST /friends/request` | `POST /friends/request` | ✅ Match | Handle `data` wrapper |
| `POST /friends/request/:requestId/accept` | `POST /friends/request/:requestId/accept` | ✅ Match | Handle `data` wrapper |
| `PUT /friends/request/:requestId/accept` | `POST /friends/request/:requestId/accept` | ⚠️ Different | Method mismatch |
| `PUT /friends/request/:requestId/decline` | `POST /friends/request/:requestId/reject` | ⚠️ Different | Method + path mismatch |
| `GET /friends/requests` | `GET /friends/requests` | ✅ Match | Handle `data` wrapper |
| `DELETE /friends/:friendshipId` | `DELETE /friends/:friendshipId` | ✅ Match | Handle `data` wrapper |
| `DELETE /friends/:userId/remove` | ❌ Missing | ⚠️ Missing | Use friendshipId endpoint |
| `POST /friends/:userId/invite` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /friends/find-from-contacts` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /friends/presence` | ❌ Missing | ⚠️ Missing | Add to backend |
| `PUT /presence` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Accept/decline friend request: Frontend expects PUT, backend uses POST
- Decline endpoint: Frontend expects `/decline`, backend uses `/reject`
- Missing friend invite endpoint
- Missing contacts discovery endpoint
- Missing presence endpoints

---

### **Quests & Challenges Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /quests/daily` | `GET /quests/daily` | ✅ Match | Handle `data` wrapper |
| `POST /quests/daily/:id/progress` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /quests/daily/:id/claim` | `POST /quests/:questId/claim` | ⚠️ Different | Path structure different |
| `POST /quests/daily/bonus/claim` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /challenges/weekly` | `GET /challenges/weekly` | ✅ Match | Handle `data` wrapper |
| `PUT /challenges/:challengeId/progress` | `PUT /challenges/:challengeId/progress` | ✅ Match | Handle `data` wrapper |
| `POST /challenges/:challengeId/claim` | `POST /challenges/:challengeId/claim` | ✅ Match | Handle `data` wrapper |

**Issues:**
- Missing daily quest progress update endpoint
- Quest claim endpoint path structure differs

---

### **Rewards Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /rewards/daily/today` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /rewards/daily/claim` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /rewards/daily/calendar` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /rewards/available` | `GET /rewards/available` | ✅ Match | Handle `data` wrapper |
| `POST /rewards/:rewardId/claim` | `POST /rewards/:rewardId/claim` | ✅ Match | Handle `data` wrapper |
| `GET /rewards/history` | `GET /rewards/history?limit=20&offset=0` | ✅ Match | Handle `data` wrapper |

**Issues:**
- Missing daily rewards endpoints

---

### **Cards Collection Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /cards/collection` | `GET /cards/collection` | ✅ Match | Handle `data` wrapper |
| `GET /cards/available` | `GET /cards/available` | ✅ Match | Handle `data` wrapper |
| `POST /cards/:cardId/unlock` | `POST /cards/:cardId/unlock` | ✅ Match | Handle `data` wrapper |
| `POST /cards/pack/open` | `POST /cards/pack/open` | ✅ Match | Handle `data` wrapper |
| `PUT /cards/:cardId/favorite` | `PUT /cards/:cardId/favorite` | ✅ Match | Handle `data` wrapper |
| `GET /cards/stats` | `GET /cards/stats` | ✅ Match | Handle `data` wrapper |

**Status:** ✅ All endpoints match

---

### **Achievements Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /achievements` | `GET /achievements` | ✅ Match | Handle `data` wrapper |
| `GET /achievements/:achievementId` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /achievements/:achievementId/progress` | `GET /achievements/:achievementId/progress` | ✅ Match | Handle `data` wrapper |

**Issues:**
- Missing achievement details endpoint

---

### **Education Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /education/profile` | `GET /education/profile` | ✅ Match | Handle `data` wrapper |
| `PUT /education/profile` | `PUT /education/profile` | ✅ Match | Handle `data` wrapper |
| `PUT /education/age` | `PUT /education/age` | ✅ Match | Handle `data` wrapper |
| `PUT /education/school-system` | `PUT /education/school-system` | ✅ Match | Handle `data` wrapper |
| `PUT /education/grade` | `PUT /education/grade` | ✅ Match | Handle `data` wrapper |
| `PUT /education/exam` | `PUT /education/exam` | ✅ Match | Handle `data` wrapper |
| `GET /subscriptions/education/sat` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /subscriptions/education/gmat` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /subscriptions/education/sat/purchase` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /subscriptions/education/gmat/purchase` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Missing education subscription endpoints

---

### **Subscriptions Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /subscriptions` | `GET /subscriptions` | ✅ Match | Handle `data` wrapper |
| `GET /subscriptions/me` | `GET /subscriptions/status` | ⚠️ Different | Path mismatch |
| `POST /subscriptions/purchase` | `POST /subscriptions/purchase` | ✅ Match | Handle `data` wrapper |
| `POST /subscriptions/:subscriptionId/cancel` | `POST /subscriptions/:subscriptionId/cancel` | ✅ Match | Handle `data` wrapper |
| `POST /subscriptions/restore` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /subscriptions/premium/benefits` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /subscriptions/premium/monthly` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /subscriptions/premium/yearly` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /subscriptions/me/cancel` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Subscription status endpoint path differs
- Missing restore purchases endpoint
- Missing premium subscription endpoints

---

### **Notifications Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /notifications` | `GET /notifications?limit=20&offset=0&unreadOnly=true` | ✅ Match | Handle `data` wrapper |
| `PUT /notifications/:notificationId/read` | `PUT /notifications/:notificationId/read` | ✅ Match | Handle `data` wrapper |
| `PUT /notifications/read-all` | `PUT /notifications/read-all` | ✅ Match | Handle `data` wrapper |
| `DELETE /notifications/:notificationId` | `DELETE /notifications/:notificationId` | ✅ Match | Handle `data` wrapper |
| `GET /notifications/preferences` | `GET /notifications/preferences` | ✅ Match | Handle `data` wrapper |
| `PUT /notifications/preferences` | `PUT /notifications/preferences` | ✅ Match | Handle `data` wrapper |
| `POST /notifications/device` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /notifications/send` | ❌ Missing | ⚠️ Missing | Add to backend (admin) |
| `GET /notifications/history` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Missing device registration endpoint
- Missing notification history endpoint

---

### **Analytics Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `POST /analytics/event` | `POST /analytics/event` | ✅ Match | Handle `data` wrapper |
| `POST /analytics/screen` | `POST /analytics/screen` | ✅ Match | Handle `data` wrapper |
| `POST /analytics/performance` | `POST /analytics/performance` | ✅ Match | Handle `data` wrapper |
| `POST /analytics/error` | `POST /analytics/error` | ✅ Match | Handle `data` wrapper |

**Status:** ✅ All endpoints match

---

### **System & App Info Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /app/version-check` | `GET /app/version` | ⚠️ Different | Path mismatch |
| `GET /app/force-update` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /health` | `GET /health` | ✅ Match | Handle `data` wrapper |
| `GET /help/faq` | `GET /help/faq` | ✅ Match | Handle `data` wrapper |
| `POST /help/support` | `POST /help/support` | ✅ Match | Handle `data` wrapper |
| `GET /help/contact` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /about` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /legal/terms` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /legal/privacy` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /languages` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /store/items` | `GET /store/items` | ✅ Match | Handle `data` wrapper |
| `POST /store/purchase` | `POST /store/purchase` | ✅ Match | Handle `data` wrapper |
| `GET /store/coins/packages` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /store/coins/purchase` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /store/purchases` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- Version check endpoint path differs
- Missing several system endpoints

---

### **Ad Monetization Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `POST /ads/view` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /ads/reward` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /ads/rewarded/try-again` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /ads/eligible` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- All ad endpoints missing from backend

---

### **Leaderboard Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /leaderboards/global` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /leaderboards/weekly` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /leaderboards/monthly` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /leaderboards/category/:category` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /leaderboards/friends` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- All leaderboard endpoints missing from backend

---

### **Invites & Referrals Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `GET /invites/status` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /invites/track` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /invites/reward/claim` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /invites/link` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- All invite endpoints missing from backend

---

### **Contacts Discovery Endpoints**

| Frontend Expects | Backend Provides | Status | Action |
|-----------------|------------------|--------|--------|
| `POST /friends/find-from-contacts` | ❌ Missing | ⚠️ Missing | Add to backend |
| `POST /contacts/upload` | ❌ Missing | ⚠️ Missing | Add to backend |
| `GET /contacts/matches` | ❌ Missing | ⚠️ Missing | Add to backend |

**Issues:**
- All contacts discovery endpoints missing from backend

---

## 🔧 Required Changes


### **Backend Changes Required:**

1. **Add Missing Endpoints** (Priority Order):
   - **High Priority:**
     - `POST /auth/logout`
     - `POST /auth/guest/upgrade`
     - `GET /users/me/preferences`
     - `PUT /users/me/mode`
     - `GET /users/me/education`
     - `POST /users/me/login-reward`
     - `POST /users/me/free-coins`
     - `POST /users/me/lucky-spin`
     - `GET /questions/categories`
     - `GET /challenges/daily/questions`
     - `GET /challenges/daily/status`
     - `GET /challenges/daily/reward`
     - `POST /quests/daily/:id/progress`
     - `POST /quests/daily/bonus/claim`
     - `PATCH /rooms/:roomCode/ready`
     - `POST /rooms/:roomCode/start`
     - `GET /leagues`
     - `GET /leagues/:leagueId/results`
     - `POST /leagues/:leagueId/score`
     - `GET /leaderboards/global`
     - `GET /leaderboards/weekly`
     - `GET /leaderboards/monthly`
     - `POST /ads/view`
     - `POST /ads/reward`

   - **Medium Priority:**
     - `GET /campaign/rounds`
     - `GET /campaign/leaderboard`
     - `POST /campaign/rounds/:roundId/start`
     - `GET /rewards/daily/today`
     - `POST /rewards/daily/claim`
     - `GET /rewards/daily/calendar`
     - `GET /achievements/:achievementId`
     - `GET /app/force-update`
     - `GET /help/contact`
     - `GET /about`
     - `GET /legal/terms`
     - `GET /legal/privacy`
     - `GET /languages`
     - `GET /store/coins/packages`
     - `POST /store/coins/purchase`
     - `GET /store/purchases`

   - **Low Priority:**
     - `POST /friends/:userId/invite`
     - `POST /friends/find-from-contacts`
     - `GET /friends/presence`
     - `PUT /presence`
     - `GET /invites/status`
     - `POST /invites/track`
     - `POST /invites/reward/claim`
     - `GET /invites/link`
     - `POST /contacts/upload`
     - `GET /contacts/matches`
     - `POST /notifications/device`
     - `GET /notifications/history`
     - `POST /subscriptions/restore`
     - `GET /subscriptions/premium/benefits`
     - `POST /subscriptions/premium/monthly`
     - `POST /subscriptions/premium/yearly`
     - `GET /subscriptions/education/sat`
     - `GET /subscriptions/education/gmat`
     - `POST /subscriptions/education/sat/purchase`
     - `POST /subscriptions/education/gmat/purchase`

2. **Fix Endpoint Path Mismatches:**
   - Campaign endpoints: Decide on structure (with/without campaignId)
   - Friend request decline: Change `/reject` to `/decline` OR update frontend
   - Friend request accept: Change POST to PUT OR update frontend
   - Subscription status: Change `/status` to `/me` OR update frontend
   - Version check: Change `/version` to `/version-check` OR update frontend
   - Quest claim: Standardize path structure

3. **Standardize Response Formats:**
   - Ensure all endpoints return `{ success, data }` wrapper
   - Ensure all error responses follow `{ success: false, error: {...} }` format

---

## 📊 Summary Statistics

| Category | Frontend Endpoints | Backend Endpoints | Matches | Mismatches | Missing in Backend |
|----------|-------------------|-------------------|---------|------------|-------------------|
| **Authentication** | 9 | 7 | 7 | 0 | 2 |
| **User Management** | 17 | 11 | 11 | 1 | 6 |
| **Questions & Quiz** | 15 | 10 | 10 | 0 | 5 |
| **Campaign** | 8 | 6 | 1 | 5 | 2 |
| **Multiplayer** | 12 | 10 | 10 | 0 | 2 |
| **Leagues** | 10 | 5 | 5 | 0 | 5 |
| **Friends** | 13 | 7 | 7 | 2 | 4 |
| **Quests** | 7 | 5 | 5 | 1 | 1 |
| **Rewards** | 6 | 3 | 3 | 0 | 3 |
| **Cards** | 6 | 6 | 6 | 0 | 0 |
| **Achievements** | 3 | 2 | 2 | 0 | 1 |
| **Education** | 9 | 6 | 6 | 0 | 3 |
| **Subscriptions** | 9 | 4 | 4 | 1 | 4 |
| **Notifications** | 9 | 6 | 6 | 0 | 3 |
| **Analytics** | 4 | 4 | 4 | 0 | 0 |
| **System** | 15 | 5 | 5 | 1 | 9 |
| **Ads** | 4 | 0 | 0 | 0 | 4 |
| **Leaderboards** | 5 | 0 | 0 | 0 | 5 |
| **Invites** | 4 | 0 | 0 | 0 | 4 |
| **Contacts** | 3 | 0 | 0 | 0 | 3 |
| **TOTAL** | **171** | **97** | **98** | **11** | **62** |

---

## 🎯 Action Items

### **Immediate (Before Integration):**

1. ✅ **Create API Client Service**
   - Base URL configuration
   - Response wrapper handling
   - Error handling
   - Token management

2. ✅ **Fix Response Format**
   - Update all service files to handle `data` wrapper
   - Create response model classes

3. ✅ **Add Missing Critical Endpoints to Backend**
   - Authentication endpoints (logout, guest upgrade)
   - User endpoints (preferences, mode, education, rewards)
   - Daily challenge endpoints
   - Quest progress endpoints
   - Room ready/start endpoints
   - Leaderboard endpoints
   - Ad endpoints

4. ✅ **Resolve Path Mismatches**
   - Campaign endpoint structure
   - Friend request endpoints
   - Subscription endpoints
   - Version check endpoint

### **Before Production:**

1. ✅ Add all missing endpoints
2. ✅ Standardize all endpoint paths
3. ✅ Implement WebSocket connection
4. ✅ Add rate limiting handling
5. ✅ Add retry logic for failed requests
6. ✅ Add request/response logging
7. ✅ Add offline mode support

---

## 📝 Notes

1. **Response Wrapper:** Backend uses `{ success, data }` wrapper. Frontend must extract `data` from all responses.

2. **Error Handling:** Backend returns `{ success: false, error: { message, code } }`. Frontend must handle these consistently.

3. **Authentication:** JWT tokens in `Authorization: Bearer <token>` header. Frontend must store and refresh tokens.

4. **Base URL:** Must be configurable for dev/prod environments.

5. **WebSocket:** Backend uses Socket.IO. Frontend needs Socket.IO client implementation.

6. **Rate Limiting:** Backend implements rate limiting. Frontend should handle 429 responses gracefully.

---

**Report Generated:** January 17, 2026  
**Status:** ⚠️ **Action Required** - 62 endpoints missing in backend, 11 path mismatches




