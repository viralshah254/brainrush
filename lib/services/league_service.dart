import 'dart:math';
import '../models/league.dart';

class LeagueService {
  static final LeagueService _instance = LeagueService._internal();
  factory LeagueService() => _instance;
  LeagueService._internal();

  // Mock league data
  final List<League> _leagues = [
    League(
      id: 'l1',
      name: 'Math Masters League',
      description: 'Test your mathematical prowess against the best!',
      topic: 'Math',
      tier: 'Gold',
      entryFee: 50,
      maxParticipants: 100,
      participants: _generateMockParticipants(45),
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      isActive: true,
      totalQuestions: 10,
    ),
    League(
      id: 'l2',
      name: 'Science Champions',
      description: 'Explore the wonders of science in this competitive league!',
      topic: 'Science',
      tier: 'Diamond',
      entryFee: 100,
      maxParticipants: 50,
      participants: _generateMockParticipants(38),
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      isActive: true,
      totalQuestions: 15,
    ),
    League(
      id: 'l3',
      name: 'History Buffs Challenge',
      description: 'Journey through time and test your historical knowledge!',
      topic: 'History',
      tier: 'Silver',
      entryFee: 30,
      maxParticipants: 150,
      participants: _generateMockParticipants(89),
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 6)),
      isActive: true,
      totalQuestions: 12,
    ),
    League(
      id: 'l4',
      name: 'Geography Explorers',
      description: 'Navigate the world of geography in this exciting league!',
      topic: 'Geography',
      tier: 'Bronze',
      entryFee: 20,
      maxParticipants: 200,
      participants: _generateMockParticipants(156),
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 8)),
      isActive: false,
      totalQuestions: 10,
    ),
    League(
      id: 'l5',
      name: 'Literature Legends',
      description: 'Immerse yourself in the world of books and authors!',
      topic: 'Literature',
      tier: 'Gold',
      entryFee: 50,
      maxParticipants: 80,
      participants: _generateMockParticipants(62),
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 4)),
      isActive: true,
      totalQuestions: 10,
    ),
  ];

  static List<LeagueParticipant> _generateMockParticipants(int count) {
    final names = ['Alex', 'Sam', 'Jordan', 'Casey', 'Riley', 'Taylor', 'Morgan', 'Avery'];
    return List.generate(count, (i) {
      return LeagueParticipant(
        userId: 'user_$i',
        username: '${names[i % names.length]}${i + 1}',
        score: 1000 - (i * 10) + Random().nextInt(50),
        rank: i + 1,
      );
    });
  }

  Future<List<League>> getLeagues({String? topic, String? status}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = List<League>.from(_leagues);

    if (topic != null && topic != 'All') {
      filtered = filtered.where((l) => l.topic == topic).toList();
    }

    if (status != null) {
      if (status == 'Active') {
        filtered = filtered.where((l) => l.isActive).toList();
      } else if (status == 'Upcoming') {
        filtered = filtered.where((l) => !l.isActive && DateTime.now().isBefore(l.startDate)).toList();
      } else if (status == 'Completed') {
        filtered = filtered.where((l) => DateTime.now().isAfter(l.endDate)).toList();
      }
    }

    return filtered;
  }

  Future<League?> getLeagueById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _leagues.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updatePlayerScore(String leagueId, String userId, int score) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final leagueIndex = _leagues.indexWhere((l) => l.id == leagueId);
    if (leagueIndex == -1) return false;

    final league = _leagues[leagueIndex];
    final participantIndex = league.participants.indexWhere((p) => p.userId == userId);
    
    if (participantIndex == -1) return false;

    // Update participant's score
    final updatedParticipants = List<LeagueParticipant>.from(league.participants);
    updatedParticipants[participantIndex] = LeagueParticipant(
      userId: userId,
      username: updatedParticipants[participantIndex].username,
      score: score,
      rank: updatedParticipants[participantIndex].rank, // Will be recalculated below
    );

    // Sort by score and update ranks
    updatedParticipants.sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < updatedParticipants.length; i++) {
      updatedParticipants[i] = LeagueParticipant(
        userId: updatedParticipants[i].userId,
        username: updatedParticipants[i].username,
        score: updatedParticipants[i].score,
        rank: i + 1,
      );
    }

    // Update league
    _leagues[leagueIndex] = League(
      id: league.id,
      name: league.name,
      description: league.description,
      topic: league.topic,
      tier: league.tier,
      entryFee: league.entryFee,
      maxParticipants: league.maxParticipants,
      participants: updatedParticipants,
      startDate: league.startDate,
      endDate: league.endDate,
      isActive: league.isActive,
      totalQuestions: league.totalQuestions,
    );

    return true;
  }

  Future<bool> joinLeague(String leagueId, String userId, String username) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final leagueIndex = _leagues.indexWhere((l) => l.id == leagueId);
    if (leagueIndex == -1) return false;

    final league = _leagues[leagueIndex];
    if (league.participants.length >= league.maxParticipants) {
      return false; // League is full
    }

    // Check if user already joined
    if (league.participants.any((p) => p.userId == userId)) {
      return false;
    }

    // Add user to league
    final newParticipant = LeagueParticipant(
      userId: userId,
      username: username,
      score: 0,
      rank: league.participants.length + 1,
    );

    final updatedParticipants = [...league.participants, newParticipant];
    _leagues[leagueIndex] = League(
      id: league.id,
      name: league.name,
      description: league.description,
      topic: league.topic,
      tier: league.tier,
      entryFee: league.entryFee,
      maxParticipants: league.maxParticipants,
      participants: updatedParticipants,
      startDate: league.startDate,
      endDate: league.endDate,
      isActive: league.isActive,
      totalQuestions: league.totalQuestions,
    );

    return true;
  }

  List<String> getAvailableTopics() {
    return ['All', 'Math', 'Science', 'History', 'Geography', 'Literature'];
  }
}

