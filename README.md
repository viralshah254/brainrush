# 🧠⚡ BrainRush - Educational Speed Quiz

**BrainRush** is a viral, educational mobile game built with Flutter that combines speed, learning, and social competition. Think "Who Wants to Be a Millionaire" meets daily brain training!

## 🎯 Core Features (MVP - Phase 1)

### ✅ Implemented
- **Practice Mode**: Unlimited solo play with category selection and difficulty levels
- **Daily Challenge**: 5 questions with double points for fast, accurate completion
- **Educational Content**: 25+ curated questions across 10 categories
- **Smart Scoring System**: Speed bonuses, streak rewards, and accuracy tracking
- **Coin Economy**: Earn coins based on performance
- **User Stats**: Track accuracy, avg time, and category strengths
- **Push Notifications**: Daily 8:00 AM reminders (Africa/Nairobi timezone)
- **Share Results**: Screenshot and share your achievements
- **Modern UI**: Neon-dark theme with smooth animations

### 📚 Categories
1. General Knowledge
2. Geography
3. Science
4. Math & Logic
5. Business & Money
6. Technology
7. Health
8. History
9. English Vocabulary
10. Kenya & Africa

### 🎮 Game Mechanics
- **4 Options per Question**: Multiple choice with plausible distractors
- **Time Pressure**: 12 seconds per question
- **Speed Bonus**: Faster answers = more points (up to +60)
- **Streak System**: +50 bonus every 3 correct answers
- **Educational Explanations**: Learn after each question

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.9.0 or higher
- Dart 3.0+
- iOS 12.0+ / Android 5.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd brainrush
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # iOS
   flutter run -d ios
   
   # Android
   flutter run -d android
   
   # Web (for testing)
   flutter run -d chrome
   ```

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── question.dart
│   └── match.dart
├── providers/                # State management (Provider)
│   ├── user_provider.dart
│   └── game_provider.dart
├── services/                 # Business logic
│   ├── question_bank.dart    # Curated questions
│   ├── scoring_service.dart  # Score calculations
│   ├── storage_service.dart  # Local persistence
│   └── notification_service.dart
├── screens/                  # UI screens
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   ├── category_select_screen.dart
│   ├── game_screen.dart
│   └── results_screen.dart
└── theme/
    └── app_theme.dart        # Neon-dark theme
```

## 📖 How to Play

### Onboarding
1. Enter your username
2. Enable notifications (recommended)
3. Start playing!

### Practice Mode
1. Select a category (or Random)
2. Choose difficulty (1-5)
3. Answer 10 questions as fast as you can
4. Earn coins and improve your stats

### Daily Challenge
1. Complete 5 questions every day
2. Finish in under 45 seconds with 4+ correct
3. Earn **DOUBLE POINTS**
4. Compete on the daily leaderboard (coming soon)

## 🎨 Scoring System

### Base Points
- ✅ Correct: +100 points
- ❌ Wrong: -50 points
- ⏱️ Timeout: -25 points

### Speed Bonus (Correct Answers Only)
- Formula: `(timeLimitMs - answerTimeMs) / 200`
- Maximum: +60 points
- Example: Answer in 2s → +50 speed bonus

### Streak Bonus
- Every 3 correct in a row: +50 points

### Daily Challenge Multiplier
- Complete with 4+/5 correct in ≤45s total: **2x points**

### Coins Earned
- Based on final score: `score / 10`

## 🔔 Notifications

### Daily Reminder
- Time: 8:00 AM Africa/Nairobi
- Message: "BrainRush Daily Challenge is live!"

### Inactivity Reminder
- After 10 hours of inactivity
- Message: "Quick round? Keep your streak alive!"

### Settings
Users can toggle notifications in their profile (coming in Phase 2).

## 🛣️ Roadmap

### Phase 2 (Friends Mode)
- [ ] Create/join rooms (2-5 players)
- [ ] Real-time multiplayer scoring
- [ ] Friend leaderboards
- [ ] In-game chat

### Phase 3 (Global League)
- [ ] Worldwide matchmaking
- [ ] 10-round leagues
- [ ] Server-authoritative timing (anti-cheat)
- [ ] Seasonal rewards & rankings
- [ ] League entry fees (coins)

### Phase 4 (Polish & Growth)
- [ ] AI-generated questions
- [ ] More categories & difficulty levels
- [ ] Cosmetic shop (themes, avatars)
- [ ] Hints system (50/50, Time Freeze)
- [ ] Analytics dashboard
- [ ] Social sharing improvements

## 🏗️ Technical Stack

- **Framework**: Flutter 3.9+
- **State Management**: Provider
- **Local Storage**: SharedPreferences
- **Notifications**: flutter_local_notifications + timezone
- **UI**: Google Fonts, custom neon-dark theme
- **Sharing**: screenshot + share_plus
- **Animations**: Confetti, implicit animations

## 🎯 Key Design Principles

1. **Educational First**: Every question teaches something
2. **Speed Matters**: Fast answers are rewarded
3. **Fair Competition**: No pay-to-win mechanics
4. **Daily Habit**: Push notifications at optimal times
5. **Social & Viral**: Easy sharing, friend challenges

## 📱 Supported Platforms

- ✅ iOS 12.0+
- ✅ Android 5.0+ (API 21+)
- ✅ Web (testing only)
- ❌ Desktop (not optimized)

## 🐛 Known Issues & Limitations

- Question bank currently has 25 questions (will expand to 500+)
- Friends mode and League mode are placeholders
- No backend integration yet (local storage only)
- Notifications require manual permission on iOS

## 🤝 Contributing

### Adding Questions

Questions are defined in `lib/services/question_bank.dart`:

```dart
Question(
  id: _uuid.v4(),
  category: 'Science',
  difficulty: 2,
  prompt: 'Your question here?',
  options: ['Option A', 'Option B', 'Option C', 'Option D'],
  correctIndex: 0, // Index of correct answer (0-3)
  explanation: 'Brief explanation for learning.',
  tags: ['chemistry', 'elements'],
)
```

### Guidelines for Questions
- 4 plausible options (no "all/none of the above")
- 1 correct answer
- Short, clear explanation
- Difficulty levels:
  - 1: Common knowledge
  - 2: Requires thinking
  - 3: Deeper knowledge
  - 4: Expert level
  - 5: Master (rare)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by quiz games like Trivia HQ and Who Wants to Be a Millionaire
- Built with ❤️ for educational purposes
- Special focus on Kenya & Africa content

## 📧 Contact

For questions, suggestions, or bug reports, please open an issue on GitHub.

---

**Keep your brain fresh every morning! 🧠⚡**
# brainrush
