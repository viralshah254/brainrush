import 'package:flutter/material.dart';

/// App Localizations - Base class for translations
abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Common
  String get appName;
  String get appTagline;
  String get loading;
  String get error;
  String get retry;
  String get cancel;
  String get confirm;
  String get done;
  String get next;
  String get back;
  String get close;
  String get save;
  String get delete;
  String get edit;
  String get share;
  String get settings;
  String get profile;
  String get home;
  String get play;
  String get start;
  String get continueText;
  String get skip;
  String get yes;
  String get no;
  String get ok;

  // Navigation
  String get leagues;
  String get friends;
  String get leaderboard;
  String get achievements;
  String get cards;
  String get general;
  String get education;

  // Game Modes
  String get dailyChallenge;
  String get campaignMode;
  String get practiceMode;
  String get playWithFriends;
  String get studyWithFriends;
  String get gradeLeague;

  // Stats
  String get score;
  String get coins;
  String get streak;
  String get accuracy;
  String get level;
  String get xp;
  String get correct;
  String get wrong;
  String get questions;
  String get gamesPlayed;

  // Results
  String get results;
  String get yourScore;
  String get correctAnswers;
  String get wrongAnswers;
  String get performance;
  String get excellent;
  String get good;
  String get tryAgain;
  String get playAgain;
  String get notQuite;
  

  // Daily Challenge
  String get dailyChallengeComplete;
  String get dailyReward;
  String get doublePoints;

  // Campaign
  String get round;
  String get roundComplete;
  String get stars;
  String get totalStars;
  String get completed;
  String get currentRound;
  String get locked;
  String get masterTheBasics;
  String get welcomeChallenge;

  // Multiplayer
  String get createRoom;
  String get joinRoom;
  String get roomCode;
  String get players;
  String get waitingForPlayers;
  String get ready;
  String get notReady;
  String get startGame;
  String get leaveRoom;

  // Friends
  String get friendsList;
  String get findFriends;
  String get inviteFriends;
  String get addFriend;
  String get removeFriend;
  String get accept;
  String get decline;
  String get pending;
  String get online;
  String get offline;
  String get playWithYourFriends;
  String get createOrJoinRoom;
  String get startPlaying;
  String get seeWhichContactsPlay;

  // Profile
  String get signIn;
  String get signUp;
  String get signOut;
  String get guest;
  String get account;
  String get notifications;
  String get language;
  String get helpSupport;
  String get about;
  String get deleteAccount;
  String get logOut;

  // Auth
  String get welcomeBack;
  String get createAccount;
  String get email;
  String get password;
  String get confirmPassword;
  String get fullName;
  String get forgotPassword;
  String get resetPassword;
  String get termsPrivacy;
  String get agreeToTerms;

  // Settings
  String get notificationSettings;
  String get manageNotifications;
  String get selectLanguage;
  String get english;
  String get spanish;
  String get hindi;
  String get chinese;
  String get arabic;

  // Store
  String get coinStore;
  String get buyCoins;
  String get watchAdForCoins;
  String get freeCoins;
  String get earnCoins;

  // Quests
  String get dailyQuests;
  String get questComplete;
  String get claimReward;
  String get allQuestsComplete;
  String get dailyMissions;
  String get completeQuestsToEarnCoins;
  String get progress;
  String get playGames;
  String get completeGamesInAnyMode;
  String get completeTodaysDailyChallenge;

  // Leaderboard
  String get global;
  String get weekly;
  String get monthly;
  String get yourRank;
  String get rank;
  String get globalLeagues;
  String get all;
  String get active;
  String get upcoming;
  String get joinAndPlay;
  String get daysLeft;
  String get live;

  // Achievements
  String get achievementUnlocked;
  String get viewProgress;

  // Cards
  String get cardCollection;
  String get collectibleCards;
  String get newCard;
  String get cardUnlocked;

  // Invite
  String get inviteYourFriends;
  String get invite5Friends;
  String get get500Coins;
  String get invitesSent;
  String get moreToUnlock;
  String get rewardUnlocked;
  String get claimCoins;
  String get rewardClaimed;
  String get maybeLater;

  // Help
  String get weAreHereToHelp;
  String get emailUs;
  String get frequentlyAskedQuestions;
  String get needMoreHelp;
  String get responseTime;

  // About
  String get aboutMindRush;
  String get aboutDVTech;
  String get ourMission;
  String get credits;
  String get developer;
  String get copyright;
  String get madeWithLove;

  // Errors
  String get somethingWentWrong;
  String get networkError;
  String get tryAgainLater;
  String get insufficientCoins;
  String get notEnoughCoins;

  // Success
  String get success;
  String get coinsEarned;
  String get levelUp;
  String get congratulations;

  // Time
  String get today;
  String get yesterday;
  String get daysAgo;
  String get hoursAgo;
  String get minutesAgo;
  String get justNow;
  
  // Game
  String get question;
  String get seconds;
  String get errorLoadingQuestions;
  String get goBack;
  String get grade;
  
  // Categories
  String get math;
  String get science;
  String get history;
  String get geography;
  String get generalKnowledge;
}

