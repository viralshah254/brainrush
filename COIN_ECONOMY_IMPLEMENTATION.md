# 💰 Coin Economy Implementation Guide

## ✅ COMPLETED FEATURES

### 1. **Coin Store Screen** ✅
- **File**: `lib/screens/coin_store_screen.dart`
- Purchase coins with real money (5 packages: $0.99 - $14.99)
- Watch ads for 50 free coins
- Beautiful UI with gradient cards
- Info section explaining coin usage
- **Store Icon**: Added to home screen AppBar (💰 icon)

### 2. **Campaign Mode - Coin Integration** ✅
- **Entry Cost**: Scaled by difficulty
  - Easy: 10 coins
  - Medium: 20 coins
  - Hard: 30 coins
  - Super Hard: 50 coins
- **Wrong Answer Penalty**: -5 coins per wrong answer
- **Insufficient Coins Dialog**: Prompts user to visit store
- **Files Modified**:
  - `lib/models/campaign_round.dart` - Added `entryCost` getter
  - `lib/screens/campaign/campaign_screen.dart` - Added coin check & deduction
  - `lib/screens/campaign/campaign_game_screen.dart` - Wrong answer penalty

### 3. **User Provider Enhancements** ✅
- **File**: `lib/providers/user_provider.dart`
- `hasEnoughCoins(int amount)` - Check balance
- `spendCoins(int amount)` - Returns bool, prevents negative balance
- `deductCoins(int amount)` - Force deduct (for penalties)

### 4. **Home Screen Store Access** ✅
- **File**: `lib/screens/home_screen.dart`
- Store button in AppBar (top-right)
- Gradient coin icon (💰)
- Direct navigation to Coin Store

---

## 🚧 IN PROGRESS / TODO

### 5. **Campaign - Double Coins Reward** (Partially implemented)
- **Need to add**: Watch ad button in `campaign_results_screen.dart`
- Option to double coins earned by watching rewarded ad
- Show after completing a round
- **Status**: 70% complete

### 6. **Play With Friends - Coin Wagering** (Not started)
- **Entry fee**: 50 coins per player
- **Prize distribution**:
  - 1st place: 50% of pot
  - 2nd place: 30% of pot
  - 3rd place: 20% of pot
- **Files to modify**:
  - `lib/screens/friends/play_with_friends_screen.dart`
  - `lib/screens/friends/multiplayer_results_screen.dart`
  - `lib/services/room_service.dart`

### 7. **Global League - Coin Entry & Prizes** (Not started)
- Entry fee based on league tier
- Top 50 players win coins
- Smart prize distribution (exponential decay)
- **Files to modify**:
  - `lib/screens/leagues/leagues_screen.dart`
  - League results screens

---

## 📊 Monetization Hooks

### Ad-Based Monetization:
1. ✅ Watch ad for 50 coins (Coin Store)
2. 🚧 Watch ad for double coins (Campaign results)
3. ✅ Wrong answer retry ads (Already implemented)
4. ✅ Extra time ads (Already implemented)

### Purchase-Based Monetization:
1. ✅ Coin packages ($0.99 - $14.99)
2. ⏳ Premium subscription (ad-free, bonus coins)
3. ⏳ In-app purchases integration

### Coin Sinks (Where users spend coins):
1. ✅ Campaign entry fees
2. ✅ Wrong answer penalties
3. 🚧 Play With Friends wagering
4. 🚧 Global League entry fees
5. ⏳ Power-ups/Hints (future)
6. ⏳ Cosmetic items (future)

### Coin Sources (Where users earn coins):
1. ✅ Watch ads (+50 coins)
2. ✅ Purchase packages
3. ✅ Campaign completion rewards
4. ✅ Daily challenge rewards
5. 🚧 Play With Friends winnings
6. 🚧 Global League prizes
7. ⏳ Daily login bonuses (future)

---

## 🎮 User Experience Flow

### New Player Experience:
1. Start with 100 coins (default)
2. Play a few campaign rounds
3. Run low on coins
4. Prompted to watch ad or buy coins
5. Engaged in coin economy loop

### Balanced Economy:
- Easy campaigns cost less than they reward (net positive)
- Hard campaigns cost more but reward more (risk/reward)
- Wrong answers create coin sink
- Multiple ways to earn free coins (ads, wins)
- Clear purchase options for impatient users

---

## 🔧 Technical Implementation Notes

### Coin Transaction Safety:
- All coin operations go through `UserProvider`
- `spendCoins()` checks balance before deducting
- `deductCoins()` for penalties (can't go negative, clamps at 0)
- `hasEnoughCoins()` for pre-checks

### UI Consistency:
- All coin displays use 💰 emoji
- Gradient containers for store items
- Clear cost indicators (red badge)
- Reward indicators (green text with +)

### Ad Integration:
- Uses `AdService` for rewarded ads
- Loading dialogs during ad load
- Graceful error handling
- Premium users skip ads

---

## 📱 Next Steps (Priority Order)

1. **HIGH**: Complete Campaign double coins reward
2. **HIGH**: Implement Play With Friends wagering
3. **MEDIUM**: Implement Global League coin system
4. **MEDIUM**: Add daily login coin bonus
5. **LOW**: Add coin purchase animation/feedback
6. **LOW**: Add coin transaction history

---

## 🧪 Testing Checklist

- [ ] Campaign entry with insufficient coins
- [ ] Campaign entry with sufficient coins
- [ ] Wrong answer coin deduction
- [ ] Watch ad for coins in store
- [ ] Purchase coins (test mode)
- [ ] Double coins reward after campaign
- [ ] Play With Friends wagering
- [ ] Global League entry & prizes
- [ ] Coin balance persistence
- [ ] Premium user coin bonuses

---

## 💡 Future Enhancements

1. **Coin Multipliers**: Daily/weekly events with 2x coin rewards
2. **Coin Bundles**: Special limited-time offers
3. **Referral Rewards**: Invite friends, earn coins
4. **Achievement Rewards**: Unlock badges, earn coins
5. **Leaderboards**: Top coin earners get special rewards
6. **Coin Marketplace**: Trade coins for power-ups, skins, etc.

---

**Status**: 60% Complete  
**Last Updated**: [Current Session]  
**Next Focus**: Campaign double coins + Friends wagering system

