import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service_firebase.dart';
import '../services/achievement_service.dart';

class AchievementProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AchievementService _achievementService = AchievementService();

  List<Achievement> _achievements = [];
  Map<AchievementType, List<Achievement>> _achievementsByType = {};
  List<Achievement> _recentlyUnlocked = [];
  Map<String, double> _achievementProgress = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Achievement> get achievements => _achievements;
  Map<AchievementType, List<Achievement>> get achievementsByType =>
      _achievementsByType;
  List<Achievement> get recentlyUnlocked => _recentlyUnlocked;
  Map<String, double> get achievementProgress => _achievementProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Achievement> get badges =>
      _achievementsByType[AchievementType.badge] ?? [];
  List<Achievement> get medals =>
      _achievementsByType[AchievementType.medal] ?? [];
  List<Achievement> get ribbons =>
      _achievementsByType[AchievementType.ribbon] ?? [];

  /// Load all achievements for a user with progress
  Future<void> loadAchievements(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Use AchievementService to get achievements with status
      _achievements = await _achievementService.getUserAchievementsWithStatus(
        userId,
      );

      // Get achievements grouped by type
      _achievementsByType = await _achievementService.getAchievementsByType(
        userId,
      );

      // Get recently unlocked achievements
      _recentlyUnlocked = await _achievementService.getRecentlyUnlocked(userId);

      // Load progress for locked achievements
      await _loadAchievementProgress(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load progress for all achievements using AchievementService
  Future<void> _loadAchievementProgress(String userId) async {
    for (final achievement in _achievements) {
      if (!achievement.isUnlocked) {
        final progress = await _achievementService.getAchievementProgress(
          userId,
          achievement.id,
        );
        _achievementProgress[achievement.id] = progress;
      }
    }
  }

  /// Get progress for a specific achievement
  double getProgressForAchievement(String achievementId) {
    return _achievementProgress[achievementId] ?? 0.0;
  }

  /// Check achievements after quiz completion using AchievementService
  Future<List<Achievement>> checkAchievementsAfterQuiz({
    required String userId,
    required int correctAnswers,
    required int totalQuestions,
    required String subject,
    required int quizStreak,
    required int totalQuizzesCompleted,
  }) async {
    try {
      final newAchievements = <Achievement>[];
      final percentage = (correctAnswers / totalQuestions * 100);

      // Get current achievements if not loaded
      if (_achievements.isEmpty) {
        await loadAchievements(userId);
      }

      // Get current performance analytics
      final analytics = await _databaseService.getPerformanceAnalytics(userId);

      // Create a completed quiz object for the achievement service
      final completedQuiz = Quiz(
        id: 'temp_quiz_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Quiz',
        subject: subject,
        questions: [],
        sourceFileName: 'temp.pdf',
        status: QuizStatus.completed,
        percentage: percentage,
        completedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Use AchievementService to check and unlock achievements
      final unlockedAchievements = await _achievementService
          .checkAndUnlockAchievements(userId, completedQuiz, analytics);

      // Update local state with newly unlocked achievements
      for (final unlockedAchievement in unlockedAchievements) {
        final index = _achievements.indexWhere(
          (a) => a.id == unlockedAchievement.id,
        );
        if (index != -1) {
          _achievements[index] = unlockedAchievement;
          newAchievements.add(unlockedAchievement);
          // Remove from progress tracking since it's now unlocked
          _achievementProgress.remove(unlockedAchievement.id);
        }
      }

      // Update progress for remaining locked achievements
      await _loadAchievementProgress(userId);

      if (newAchievements.isNotEmpty) {
        // Update recently unlocked
        _recentlyUnlocked.addAll(newAchievements);

        // Refresh grouped achievements
        _achievementsByType = await _achievementService.getAchievementsByType(
          userId,
        );

        notifyListeners();
      }

      return newAchievements;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get unlocked achievements count by type
  int getUnlockedCount(AchievementType type) {
    final typeAchievements = _achievementsByType[type] ?? [];
    return typeAchievements.where((a) => a.isUnlocked).length;
  }

  /// Get total achievements count by type
  int getTotalCount(AchievementType type) {
    return _achievementsByType[type]?.length ?? 0;
  }

  /// Clear recently unlocked achievements (after showing notification)
  void clearRecentlyUnlocked() {
    _recentlyUnlocked.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
