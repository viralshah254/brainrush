# 📚 Questions System & Persistence - Implementation Plan

## ✅ Changes Completed

### 1. Campaign Service Updates
- ✅ **500 Rounds with Different Subjects**
  - Rotates through 10 subjects: General Knowledge, Science, Math, History, Geography, Literature, Technology, Sports, Entertainment, Nature
  - Each round has a different subject (1-500)
  - Fixed 10 questions per round

- ✅ **Difficulty Progression**
  - **Rounds 1-17**: Easy
  - **Rounds 18-34**: Medium  
  - **Rounds 35-50**: Hard
  - **Rounds 51+**: Introduces Super Hard
  - First 50 rounds = Easy, Medium, Hard only (NO super hard)
  - After round 50 = All difficulties including Super Hard

### 2. Navigation Locks
- ✅ **Bottom Navigation Tabs Locked**
  - Leagues tab (index 1): Locked with 🔒 icon
  - Friends tab (index 2): Locked with 🔒 icon
  - Shows "Coming Soon!" snackbar when tapped
  - Visual indicators: Dimmed icons and lock badge

## 🔧 Remaining Tasks

### 3. Home Screen Locks (To Implement)

```dart
// In home_screen.dart - Lock Global League card
_buildModeCard(
  context,
  title: 'Global League',
  subtitle: 'Ranked • 10 rounds • Worldwide',
  emoji: '🏆',
  color: Colors.amber,
  isLocked: true, // ADD THIS
  onTap: () {
    _showLockedFeatureDialog(context, 'Global League');
  },
),

// Lock Education Mode section entirely
// Wrap education cards in a locked container with overlay
```

### 4. Daily Rewards Persistence (To Implement)

Current Issue: Daily reward dialog shows every time app opens.

**Fix in `lib/providers/user_provider.dart`:**

```dart
// Add to UserProvider
Future<void> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Load last claimed date
  final lastClaimedStr = prefs.getString('last_daily_reward_claim');
  if (lastClaimedStr != null) {
    final lastClaimed = DateTime.parse(lastClaimedStr);
    final today = DateTime.now();
    
    // Check if already claimed today
    if (lastClaimed.year == today.year &&
        lastClaimed.month == today.month &&
        lastClaimed.day == today.day) {
      _user = _user!.copyWith(hasClaimedDailyLoginReward: true);
    }
  }
  
  // Load coins
  final coins = prefs.getInt('user_coins') ?? 100;
  _user = _user!.copyWith(coins: coins);
  
  // Load streak
  final streak = prefs.getInt('consecutive_login_days') ?? 1;
  _user = _user!.copyWith(consecutiveLoginDays: streak);
  
  notifyListeners();
}

Future<void> _saveUserData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('user_coins', _user?.coins ?? 0);
  await prefs.setInt('consecutive_login_days', _user?.consecutiveLoginDays ?? 1);
  if (_user?.hasClaimedDailyLoginReward == true) {
    await prefs.setString('last_daily_reward_claim', DateTime.now().toIso8601String());
  }
}

// Call _saveUserData() whenever coins change
void addCoins(int amount) {
  if (_user == null) return;
  _user = _user!.copyWith(coins: _user!.coins + amount);
  _saveUserData(); // ADD THIS
  notifyListeners();
}

void claimDailyLoginReward() {
  if (_user == null) return;
  _user = _user!.copyWith(hasClaimedDailyLoginReward: true);
  _saveUserData(); // ADD THIS
  notifyListeners();
}
```

### 5. Question Bank Expansion (To Implement)

Need to create a comprehensive question database with:
- **Difficulty levels**: Easy, Medium, Hard, Super Hard
- **Multiple subjects**: 10 categories rotating
- **Minimum 500+ questions** to support all rounds

**Create `lib/services/expanded_question_bank.dart`:**

```dart
class ExpandedQuestionBank {
  static final Map<String, Map<String, List<Question>>> questionsBySubjectAndDifficulty = {
    'General Knowledge': {
      'easy': [/* 20+ easy questions */],
      'medium': [/* 20+ medium questions */],
      'hard': [/* 20+ hard questions */],
      'super_hard': [/* 15+ super hard questions */],
    },
    'Science': {
      'easy': [/* 20+ questions */],
      'medium': [/* 20+ questions */],
      'hard': [/* 20+ questions */],
      'super_hard': [/* 15+ questions */],
    },
    // ... repeat for all 10 subjects
  };
  
  static List<Question> getQuestionsForRound(int roundNumber) {
    final subjects = [
      'General Knowledge', 'Science', 'Math', 'History', 'Geography',
      'Literature', 'Technology', 'Sports', 'Entertainment', 'Nature'
    ];
    
    final subject = subjects[(roundNumber - 1) % subjects.length];
    final difficulty = _getDifficultyForRound(roundNumber);
    
    final questions = questionsBySubjectAndDifficulty[subject]?[difficulty] ?? [];
    questions.shuffle();
    return questions.take(10).toList();
  }
  
  static String _getDifficultyForRound(int round) {
    if (round <= 17) return 'easy';
    if (round <= 34) return 'medium';
    if (round <= 50) return 'hard';
    if (round <= 150) return 'medium';
    if (round <= 300) return 'hard';
    return 'super_hard';
  }
}
```

### 6. Daily Challenge Random Questions

**Update `lib/screens/daily_challenge_screen.dart`:**

```dart
// Use mixed questions from all subjects
final allSubjects = ['General Knowledge', 'Science', 'Math', 'History', 
                     'Geography', 'Literature', 'Technology', 'Sports', 
                     'Entertainment', 'Nature'];
                     
// Get random questions from different subjects
final questions = ExpandedQuestionBank.getMixedQuestions(
  subjects: allSubjects,
  difficulty: 'mixed', // Random mix of all difficulties
  count: 10,
);
```

## 📊 Question Distribution Plan

### Total Questions Needed: ~750+

**Per Subject (10 subjects × 75 questions each):**
- Easy: 20 questions
- Medium: 20 questions
- Hard: 20 questions
- Super Hard: 15 questions
- **Total per subject: 75 questions**

**This ensures:**
- 500 rounds × 10 questions = 5000 questions needed
- With 750 questions, we can cycle and shuffle for variety
- Questions appear in different orders
- No repeated patterns

## 🎯 Implementation Priority

1. **HIGH PRIORITY** ✅
   - ✅ Lock Leagues and Friends tabs
   - ✅ Campaign difficulty progression
   - ✅ Subject rotation for 500 rounds

2. **HIGH PRIORITY** (Next)
   - 🔲 Fix daily rewards persistence
   - 🔲 Save coins to SharedPreferences
   - 🔲 Lock Global League on home screen
   - 🔲 Lock Education section on home screen

3. **MEDIUM PRIORITY**
   - 🔲 Create expanded question bank (750+ questions)
   - 🔲 Implement question fetching by round
   - 🔲 Add difficulty indicators in UI

4. **LOW PRIORITY**
   - 🔲 AI question generation integration
   - 🔲 Question analytics and tracking
   - 🔲 User-submitted questions

## 📝 Code Snippets for Quick Implementation

### Lock Feature Dialog

```dart
void _showLockedFeatureDialog(BuildContext context, String featureName) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1f2e), Color(0xFF2d1b3d)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.deepPurple, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text(
              '$featureName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Locked Mode Card Overlay

```dart
Widget _buildLockedModeCard(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String emoji,
  required Color color,
}) {
  return Opacity(
    opacity: 0.5,
    child: Stack(
      children: [
        _buildModeCard(context,
          title: title,
          subtitle: subtitle,
          emoji: emoji,
          color: color,
          onTap: () => _showLockedFeatureDialog(context, title),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.lock, size: 48, color: Colors.white70),
            ),
          ),
        ),
      ],
    ),
  );
}
```

## 🎮 Testing Checklist

### Campaign Mode
- [ ] Round 1-17 shows only Easy questions
- [ ] Round 18-34 shows only Medium questions
- [ ] Round 35-50 shows only Hard questions
- [ ] Round 51+ includes Super Hard questions
- [ ] Each round has different subject
- [ ] Subjects rotate predictably (Gen Knowledge → Science → Math → etc.)

### Persistence
- [ ] Daily reward claimed → doesn't show again on restart
- [ ] Coins persist across app restarts
- [ ] Streak count persists
- [ ] Campaign progress saves

### Locks
- [ ] Leagues tab shows lock icon and is dimmed
- [ ] Friends tab shows lock icon and is dimmed
- [ ] Tapping locked tabs shows "Coming Soon" message
- [ ] Global League card on home screen is locked
- [ ] Education section is locked

## 📚 Next Steps

1. Implement user data persistence in `UserProvider`
2. Create locked card variants for home screen
3. Generate 750+ questions database
4. Test all persistence features
5. Verify campaign difficulty progression

---

**Files Modified:**
- ✅ `lib/services/campaign_service.dart`
- ✅ `lib/screens/main_navigation.dart`
- 🔲 `lib/providers/user_provider.dart` (needs persistence)
- 🔲 `lib/screens/home_screen.dart` (needs locks)
- 🔲 `lib/services/expanded_question_bank.dart` (needs creation)

**Status**: 50% Complete - Core structure ready, persistence and questions needed

