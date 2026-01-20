# 👥 Friends Feature - Backend API Specification

## Overview

This document provides comprehensive backend API specifications for the Friends feature in MindRush. The Friends feature allows users to:
- Add friends by username or from contacts
- Send and receive friend requests
- View friends list with stats
- See online status
- Play games with friends
- Track multiplayer stats with friends

---

## Database Schema

### Friendships Table

```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, friend_id),
  CHECK (user_id != friend_id)
);

CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);
CREATE INDEX idx_friendships_created ON friendships(created_at DESC);
```

**Notes:**
- Bidirectional relationship: When user A adds user B, create two rows:
  - `(user_id: A, friend_id: B)`
  - `(user_id: B, friend_id: A)` (optional, or handle in application logic)
- Or use a single row and query both directions in application

### Friend Requests Table

```sql
CREATE TABLE friend_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'ACCEPTED', 'DECLINED', 'CANCELLED'
  created_at TIMESTAMP DEFAULT NOW(),
  responded_at TIMESTAMP,
  expires_at TIMESTAMP, -- Optional: auto-expire after 7 days
  UNIQUE(from_user_id, to_user_id, status),
  CHECK (from_user_id != to_user_id),
  CHECK (status IN ('PENDING', 'ACCEPTED', 'DECLINED', 'CANCELLED'))
);

CREATE INDEX idx_friend_requests_from ON friend_requests(from_user_id);
CREATE INDEX idx_friend_requests_to ON friend_requests(to_user_id);
CREATE INDEX idx_friend_requests_status ON friend_requests(status);
CREATE INDEX idx_friend_requests_pending ON friend_requests(to_user_id, status) WHERE status = 'PENDING';
```

### User Presence Table

```sql
CREATE TABLE user_presence (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'OFFLINE', -- 'ONLINE', 'OFFLINE', 'PLAYING', 'AWAY'
  current_activity VARCHAR(100), -- e.g., 'In Game', 'In Lobby', 'Viewing Profile'
  last_seen TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_presence_status ON user_presence(status);
CREATE INDEX idx_user_presence_last_seen ON user_presence(last_seen DESC);
```

### Friend Activity/Stats View (Optional)

```sql
-- View to get friend stats efficiently
CREATE VIEW friend_stats_view AS
SELECT 
  f.user_id,
  f.friend_id,
  u.username as friend_username,
  u.photo_url as friend_avatar_url,
  us.total_score,
  us.total_games as games_played,
  us.avg_accuracy as accuracy,
  ul.level,
  us.current_streak,
  up.status as online_status,
  up.last_seen,
  f.created_at as friends_since
FROM friendships f
JOIN users u ON f.friend_id = u.id
LEFT JOIN user_stats us ON f.friend_id = us.user_id
LEFT JOIN user_levels ul ON f.friend_id = ul.user_id
LEFT JOIN user_presence up ON f.friend_id = up.user_id;
```

---

## API Endpoints

### Base URL
```
https://api.mindrushgame.com/v1
```

### Authentication
All endpoints require Bearer token authentication:
```
Authorization: Bearer <access_token>
```

---

## 1. Get Friends List

**Endpoint:** `GET /friends`

**Description:** Get the authenticated user's friends list with stats and online status.

**Query Parameters:**
- `status` (optional): Filter by status
  - `accepted` (default): Only accepted friends
  - `all`: All friends including pending
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 50, max: 100)
- `sort` (optional): Sort order
  - `recent`: Recently added (default)
  - `online`: Online friends first
  - `score`: Highest score first
  - `level`: Highest level first

**Response:** `200 OK`
```json
{
  "friends": [
    {
      "id": "friendship_uuid",
      "userId": "user_uuid",
      "username": "Alex",
      "avatarUrl": "https://cdn.mindrushgame.com/avatars/user_uuid.jpg",
      "status": "accepted",
      "stats": {
        "totalScore": 15230,
        "gamesPlayed": 245,
        "level": 12,
        "accuracy": 0.87,
        "currentStreak": 5
      },
      "presence": {
        "status": "ONLINE",
        "lastSeen": "2026-01-17T14:30:00Z",
        "currentActivity": "In Lobby"
      },
      "createdAt": "2026-01-10T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 12,
    "totalPages": 1
  }
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid or missing token
- `500 Internal Server Error`: Server error

---

## 2. Search Users

**Endpoint:** `GET /users/search`

**Description:** Search for users by username. Used to find friends to add.

**Query Parameters:**
- `query` (required): Search query (username, min 3 characters)
- `limit` (optional): Max results (default: 20, max: 50)
- `excludeFriends` (optional): Exclude already-friended users (default: true)

**Response:** `200 OK`
```json
{
  "users": [
    {
      "userId": "user_uuid",
      "username": "Alex",
      "avatarUrl": "https://cdn.mindrushgame.com/avatars/user_uuid.jpg",
      "stats": {
        "totalScore": 12000,
        "gamesPlayed": 180,
        "level": 10,
        "accuracy": 0.85
      },
      "relationship": {
        "isFriend": false,
        "hasPendingRequest": false,
        "pendingRequestDirection": null // 'incoming' or 'outgoing'
      },
      "privacy": {
        "profileVisible": true,
        "searchable": true
      }
    }
  ],
  "total": 5
}
```

**Error Responses:**
- `400 Bad Request`: Query too short (< 3 characters)
- `401 Unauthorized`: Invalid token

**Privacy Notes:**
- Users can opt out of search (`searchable: false`)
- Only return public profile data
- Don't return email or sensitive info

---

## 3. Send Friend Request

**Endpoint:** `POST /friends/requests`

**Description:** Send a friend request to another user.

**Request Body:**
```json
{
  "toUserId": "user_uuid"
}
```

**Response:** `201 Created`
```json
{
  "request": {
    "id": "request_uuid",
    "fromUserId": "current_user_uuid",
    "fromUsername": "CurrentUser",
    "fromAvatarUrl": "https://cdn.mindrushgame.com/avatars/current_user_uuid.jpg",
    "toUserId": "user_uuid",
    "status": "PENDING",
    "createdAt": "2026-01-17T14:30:00Z"
  },
  "message": "Friend request sent successfully"
}
```

**Error Responses:**
- `400 Bad Request`: 
  - Cannot send request to yourself
  - Already friends
  - Request already exists
  - Target user not found
- `403 Forbidden`: Target user has blocked you or disabled friend requests
- `404 Not Found`: Target user doesn't exist
- `429 Too Many Requests`: Rate limit exceeded (max 10 requests per hour)

**Business Logic:**
- Check if already friends
- Check if pending request exists
- Check if target user allows friend requests
- Create friend request record
- Send push notification to target user (optional)

---

## 4. Get Pending Friend Requests

**Endpoint:** `GET /friends/requests`

**Description:** Get pending friend requests (both incoming and outgoing).

**Query Parameters:**
- `direction` (optional): Filter direction
  - `incoming` (default): Requests sent to current user
  - `outgoing`: Requests sent by current user
  - `all`: Both directions
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Response:** `200 OK`
```json
{
  "requests": {
    "incoming": [
      {
        "id": "request_uuid",
        "fromUserId": "user_uuid",
        "fromUsername": "Alex",
        "fromAvatarUrl": "https://cdn.mindrushgame.com/avatars/user_uuid.jpg",
        "stats": {
          "totalScore": 12000,
          "level": 10
        },
        "createdAt": "2026-01-17T10:00:00Z"
      }
    ],
    "outgoing": [
      {
        "id": "request_uuid_2",
        "toUserId": "user_uuid_2",
        "toUsername": "Sam",
        "toAvatarUrl": "https://cdn.mindrushgame.com/avatars/user_uuid_2.jpg",
        "createdAt": "2026-01-17T09:00:00Z"
      }
    ]
  },
  "counts": {
    "incoming": 3,
    "outgoing": 1
  }
}
```

---

## 5. Accept Friend Request

**Endpoint:** `PUT /friends/requests/{requestId}/accept`

**Description:** Accept an incoming friend request.

**Path Parameters:**
- `requestId`: Friend request ID

**Response:** `200 OK`
```json
{
  "friendship": {
    "id": "friendship_uuid",
    "userId": "user_uuid",
    "username": "Alex",
    "avatarUrl": "https://cdn.mindrushgame.com/avatars/user_uuid.jpg",
    "status": "accepted",
    "createdAt": "2026-01-17T14:30:00Z"
  },
  "message": "Friend request accepted"
}
```

**Error Responses:**
- `400 Bad Request`: Request already processed
- `403 Forbidden`: Not authorized to accept this request
- `404 Not Found`: Request not found
- `409 Conflict`: Already friends

**Business Logic:**
- Verify request belongs to current user (toUserId matches)
- Check request status is PENDING
- Create bidirectional friendship records (or single record with query logic)
- Update request status to ACCEPTED
- Set responded_at timestamp
- Send push notification to requester (optional)
- Award bonus coins to both users (optional)

---

## 6. Decline Friend Request

**Endpoint:** `PUT /friends/requests/{requestId}/decline`

**Description:** Decline an incoming friend request.

**Path Parameters:**
- `requestId`: Friend request ID

**Response:** `200 OK`
```json
{
  "message": "Friend request declined"
}
```

**Error Responses:**
- `400 Bad Request`: Request already processed
- `403 Forbidden`: Not authorized to decline this request
- `404 Not Found`: Request not found

**Business Logic:**
- Verify request belongs to current user
- Update request status to DECLINED
- Set responded_at timestamp
- Optionally delete request after 30 days

---

## 7. Cancel Friend Request

**Endpoint:** `DELETE /friends/requests/{requestId}`

**Description:** Cancel an outgoing friend request.

**Path Parameters:**
- `requestId`: Friend request ID

**Response:** `204 No Content`

**Error Responses:**
- `403 Forbidden`: Not authorized (not the sender)
- `404 Not Found`: Request not found
- `400 Bad Request`: Request already accepted/declined

---

## 8. Remove Friend

**Endpoint:** `DELETE /friends/{friendshipId}`

**Description:** Remove a friend from friends list.

**Path Parameters:**
- `friendshipId`: Friendship ID (or use userId)

**Alternative:** `DELETE /friends/users/{userId}`

**Response:** `204 No Content`

**Error Responses:**
- `404 Not Found`: Friendship not found
- `403 Forbidden`: Not authorized

**Business Logic:**
- Delete friendship record(s)
- Optionally keep history for analytics
- Soft delete: Mark as deleted instead of hard delete

---

## 9. Get Friend Stats

**Endpoint:** `GET /friends/{userId}/stats`

**Description:** Get detailed stats for a specific friend.

**Path Parameters:**
- `userId`: Friend's user ID

**Response:** `200 OK`
```json
{
  "userId": "user_uuid",
  "username": "Alex",
  "avatarUrl": "https://cdn.mindrushgame.com/avatars/user_uuid.jpg",
  "stats": {
    "totalScore": 15230,
    "gamesPlayed": 245,
    "wins": 180,
    "losses": 65,
    "level": 12,
    "xp": 450,
    "xpForNextLevel": 1200,
    "accuracy": 0.87,
    "currentStreak": 5,
    "longestStreak": 12,
    "totalQuestionsAnswered": 2450,
    "correctAnswers": 2132
  },
  "multiplayerStats": {
    "gamesPlayedTogether": 15,
    "winsTogether": 8,
    "averageScoreTogether": 1250
  },
  "presence": {
    "status": "ONLINE",
    "lastSeen": "2026-01-17T14:30:00Z",
    "currentActivity": "In Lobby"
  }
}
```

**Error Responses:**
- `403 Forbidden`: Not friends or user blocked
- `404 Not Found`: User not found

---

## 10. Find Friends from Contacts

**Endpoint:** `POST /friends/find-from-contacts`

**Description:** Find which contacts (by phone numbers) have the app installed.

**Request Body:**
```json
{
  "phoneNumbers": [
    "+1234567890",
    "+0987654321",
    "+1122334455"
  ]
}
```

**Response:** `200 OK`
```json
{
  "matches": [
    {
      "phoneNumber": "+1234567890",
      "userId": "user_uuid",
      "username": "Alex",
      "avatarUrl": "https://cdn.mindrushgame.com/avatars/user_uuid.jpg",
      "isFriend": false,
      "hasPendingRequest": false
    }
  ],
  "totalMatches": 1
}
```

**Privacy Notes:**
- Hash phone numbers before storage/comparison
- Only return users who have opted in to contact discovery
- Don't return phone numbers in response
- Rate limit: Max 100 phone numbers per request

**Error Responses:**
- `400 Bad Request`: Invalid phone numbers or too many (> 100)
- `429 Too Many Requests`: Rate limit exceeded

---

## 11. Update User Presence

**Endpoint:** `PUT /presence`

**Description:** Update current user's online status and activity.

**Request Body:**
```json
{
  "status": "ONLINE", // 'ONLINE', 'OFFLINE', 'PLAYING', 'AWAY'
  "currentActivity": "In Lobby" // Optional
}
```

**Response:** `200 OK`
```json
{
  "presence": {
    "status": "ONLINE",
    "currentActivity": "In Lobby",
    "lastSeen": "2026-01-17T14:30:00Z",
    "updatedAt": "2026-01-17T14:30:00Z"
  }
}
```

**Business Logic:**
- Auto-update `lastSeen` on any API call
- Auto-set to OFFLINE after 5 minutes of inactivity
- WebSocket can be used for real-time updates

---

## 12. Get Friends Presence

**Endpoint:** `GET /friends/presence`

**Description:** Get online status for all friends.

**Response:** `200 OK`
```json
{
  "presence": [
    {
      "userId": "user_uuid",
      "status": "ONLINE",
      "currentActivity": "In Game",
      "lastSeen": "2026-01-17T14:30:00Z"
    }
  ]
}
```

---

## 13. Invite Friend to Play

**Endpoint:** `POST /friends/{userId}/invite`

**Description:** Send a game invite to a friend.

**Request Body:**
```json
{
  "roomCode": "ABC123", // Optional: if inviting to existing room
  "message": "Join me for a game!" // Optional
}
```

**Response:** `201 Created`
```json
{
  "invite": {
    "id": "invite_uuid",
    "fromUserId": "current_user_uuid",
    "toUserId": "user_uuid",
    "roomCode": "ABC123",
    "message": "Join me for a game!",
    "createdAt": "2026-01-17T14:30:00Z",
    "expiresAt": "2026-01-17T14:45:00Z"
  },
  "message": "Game invite sent"
}
```

**Business Logic:**
- Create game invite record
- Send push notification
- Invite expires after 15 minutes
- Auto-join room if roomCode provided

---

## WebSocket Events (Optional)

### Friend Status Updates

**Connection:** `wss://api.mindrushgame.com/ws/presence`

**Events:**
- `friend.online` - Friend came online
- `friend.offline` - Friend went offline
- `friend.request.received` - New friend request received
- `friend.request.accepted` - Friend request accepted
- `friend.added` - New friend added
- `friend.removed` - Friend removed you

**Example:**
```json
{
  "event": "friend.online",
  "data": {
    "userId": "user_uuid",
    "username": "Alex",
    "status": "ONLINE",
    "currentActivity": "In Lobby"
  }
}
```

---

## Rate Limiting

- **Send Friend Request**: 10 requests per hour
- **Search Users**: 30 searches per minute
- **Find from Contacts**: 5 requests per hour
- **Update Presence**: 60 updates per minute

---

## Error Codes

| Code | Description |
|------|-------------|
| `FRIEND_001` | Already friends |
| `FRIEND_002` | Friend request already exists |
| `FRIEND_003` | Cannot send request to yourself |
| `FRIEND_004` | User not found |
| `FRIEND_005` | Friend request not found |
| `FRIEND_006` | Not authorized to perform this action |
| `FRIEND_007` | User has blocked friend requests |
| `FRIEND_008` | Rate limit exceeded |
| `FRIEND_009` | Invalid friendship ID |

---

## Data Privacy & Security

### Privacy Settings

Users should be able to control:
- **Search Visibility**: Opt out of username search
- **Contact Discovery**: Opt in/out of being found via phone number
- **Friend Requests**: Allow/block friend requests
- **Profile Visibility**: Control what friends can see

### Security Considerations

1. **Phone Number Hashing**: Hash phone numbers before storage/comparison
2. **Rate Limiting**: Prevent abuse of friend request system
3. **Spam Prevention**: Limit friend requests per user per day
4. **Blocking**: Allow users to block other users
5. **Data Minimization**: Only return necessary friend data

---

## Implementation Notes

### Database Optimization

1. **Indexes**: Ensure proper indexes on `user_id`, `friend_id`, and `status`
2. **Bidirectional Queries**: Query both directions for friendships
3. **Caching**: Cache friends list for active users (Redis)
4. **Pagination**: Always paginate large friends lists

### Performance

1. **Batch Operations**: Support batch friend lookups
2. **Lazy Loading**: Load friend stats on demand
3. **Presence Updates**: Use WebSocket for real-time presence
4. **Caching**: Cache friend presence status (TTL: 1 minute)

### Scalability

1. **Sharding**: Shard friendships by user_id
2. **Read Replicas**: Use read replicas for friend queries
3. **Async Processing**: Process friend requests asynchronously
4. **Background Jobs**: Clean up expired requests

---

## Testing Checklist

- [ ] Send friend request
- [ ] Accept friend request
- [ ] Decline friend request
- [ ] Cancel outgoing request
- [ ] Remove friend
- [ ] Search users
- [ ] Find friends from contacts
- [ ] Get friends list with pagination
- [ ] Get friend stats
- [ ] Update presence
- [ ] Get friends presence
- [ ] Invite friend to play
- [ ] Rate limiting
- [ ] Privacy settings
- [ ] Error handling

---

## Future Enhancements

1. **Friend Groups**: Organize friends into groups
2. **Friend Recommendations**: Suggest friends based on mutual connections
3. **Friend Activity Feed**: Show friend achievements and activities
4. **Friend Challenges**: Challenge friends to beat your score
5. **Friend Leaderboards**: Leaderboard filtered to friends only
6. **Friend Gifting**: Send coins/gifts to friends
7. **Friend Tags**: Custom tags for friends

---

**Last Updated**: January 17, 2026  
**Version**: 1.0.0  
**Status**: Ready for Implementation


