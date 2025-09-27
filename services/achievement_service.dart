import '../models/models.dart';
import 'database_service_firebase.dart';

class AchievementService {
  final DatabaseService _databaseService = DatabaseService();

  /// Checks and unlocks achievements based on user performance
  Future<List<Achievement>> checkAndUnlockAchievements(
    String userId,
    Quiz completedQuiz,
    PerformanceAnalytics? performance,
  ) async {
    final allAchievements = await _databaseService.getAllAchievements();
    final userAchievements = await _databaseService.getUserAchievements(userId);
    final unlockedAchievementIds = userAchievements
        .map((ua) => ua.achievementId)
        .toSet();

    List<Achievement> newlyUnlocked = [];

    for (final achievement in allAchievements) {
      if (unlockedAchievementIds.contains(achievement.id)) continue;

      if (await _shouldUnlockAchievement(
        achievement,
        userId,
        completedQuiz,
        performance,
      )) {
        await _databaseService.unlockAchievement(userId, achievement.id);
        newlyUnlocked.add(
          achievement.copyWith(isUnlocked: true, unlockedAt: DateTime.now()),
        );
      }
    }

    return newlyUnlocked;
  }

  /// Determines if an achievement should be unlocked
  Future<bool> _shouldUnlockAchievement(
    Achievement achievement,
    String userId,
    Quiz completedQuiz,
    PerformanceAnalytics? performance,
  ) async {
    switch (achievement.category) {
      case AchievementCategory.progress:
        return await _checkProgressAchievement(
          achievement,
          userId,
          completedQuiz,
        );

      case AchievementCategory.consistency:
        return await _checkConsistencyAchievement(achievement, userId);

      case AchievementCategory.milestone:
        return await _checkMilestoneAchievement(
          achievement,
          completedQuiz,
          performance,
        );

      case AchievementCategory.subject:
        return await _checkSubjectAchievement(
          achievement,
          completedQuiz,
          performance,
        );
    }
  }

  /// Checks progress-based achievements
  Future<bool> _checkProgressAchievement(
    Achievement achievement,
    String userId,
    Quiz completedQuiz,
  ) async {
    switch (achievement.id) {
      case 'badge_first_quiz':
        return completedQuiz.isCompleted;

      default:
        // Check generic progress criteria
        final requiredQuizzes =
            achievement.criteria['quizzes_completed'] as int?;
        if (requiredQuizzes != null) {
          final userQuizzes = await _databaseService.getAllQuizzes();
          final completedQuizzes = userQuizzes
              .where((q) => q.isCompleted)
              .length;
          return completedQuizzes >= requiredQuizzes;
        }
        return false;
    }
  }

  /// Checks consistency-based achievements
  Future<bool> _checkConsistencyAchievement(
    Achievement achievement,
    String userId,
  ) async {
    switch (achievement.id) {
      case 'badge_study_streak_5':
        return await _checkWeeklyStudySessions(userId, 5);

      case 'badge_focused_learner':
        // This would require implementing focus time tracking
        // For now, assume 30 minutes if quiz takes more than that time
        return true; // Placeholder

      default:
        return false;
    }
  }

  /// Checks milestone-based achievements
  Future<bool> _checkMilestoneAchievement(
    Achievement achievement,
    Quiz completedQuiz,
    PerformanceAnalytics? performance,
  ) async {
    switch (achievement.id) {
      case 'medal_perfect_score':
        return completedQuiz.percentage == 100.0;

      case 'medal_first_month':
        // Check if user has been active for a full month
        return await _checkMonthlyActivity();

      default:
        return false;
    }
  }

  /// Checks subject-specific achievements
  Future<bool> _checkSubjectAchievement(
    Achievement achievement,
    Quiz completedQuiz,
    PerformanceAnalytics? performance,
  ) async {
    if (performance == null || achievement.subject.isEmpty) return false;

    final subjectPerformance = performance.getSubjectPerformance(
      achievement.subject,
    );
    if (subjectPerformance == null) return false;

    final minPercentage =
        achievement.criteria['min_percentage'] as double? ?? 85.0;
    final minQuizzes = achievement.criteria['min_quizzes'] as int? ?? 3;

    return subjectPerformance.percentage >= minPercentage &&
        subjectPerformance.quizzesTaken >= minQuizzes;
  }

  /// Helper method to check weekly study sessions
  Future<bool> _checkWeeklyStudySessions(
    String userId,
    int requiredSessions,
  ) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final allQuizzes = await _databaseService.getAllQuizzes();
    final weeklyQuizzes = allQuizzes
        .where(
          (quiz) =>
              quiz.completedAt != null &&
              quiz.completedAt!.isAfter(weekStart) &&
              quiz.completedAt!.isBefore(weekEnd),
        )
        .length;

    return weeklyQuizzes >= requiredSessions;
  }

  /// Helper method to check monthly activity
  Future<bool> _checkMonthlyActivity() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    final allQuizzes = await _databaseService.getAllQuizzes();
    final monthlyQuizzes = allQuizzes
        .where(
          (quiz) =>
              quiz.completedAt != null &&
              quiz.completedAt!.isAfter(monthStart) &&
              quiz.completedAt!.isBefore(monthEnd),
        )
        .length;

    // Consider 20 days of activity as a full month
    return monthlyQuizzes >= 20;
  }

  /// Gets all achievements with their unlock status for a user
  Future<List<Achievement>> getUserAchievementsWithStatus(String userId) async {
    final allAchievements = await _databaseService.getAllAchievements();
    final userAchievements = await _databaseService.getUserAchievements(userId);
    final unlockedMap = {for (var ua in userAchievements) ua.achievementId: ua};

    return allAchievements.map((achievement) {
      final userAchievement = unlockedMap[achievement.id];
      return achievement.copyWith(
        isUnlocked: userAchievement != null,
        unlockedAt: userAchievement?.unlockedAt,
      );
    }).toList();
  }

  /// Gets achievements grouped by type
  Future<Map<AchievementType, List<Achievement>>> getAchievementsByType(
    String userId,
  ) async {
    final achievements = await getUserAchievementsWithStatus(userId);

    final Map<AchievementType, List<Achievement>> grouped = {
      AchievementType.badge: [],
      AchievementType.medal: [],
      AchievementType.ribbon: [],
    };

    for (final achievement in achievements) {
      grouped[achievement.type]!.add(achievement);
    }

    return grouped;
  }

  /// Gets recently unlocked achievements (last 7 days)
  Future<List<Achievement>> getRecentlyUnlocked(String userId) async {
    final achievements = await getUserAchievementsWithStatus(userId);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return achievements
        .where(
          (a) =>
              a.isUnlocked &&
              a.unlockedAt != null &&
              a.unlockedAt!.isAfter(weekAgo),
        )
        .toList();
  }

  /// Gets progress towards specific achievement
  Future<double> getAchievementProgress(
    String userId,
    String achievementId,
  ) async {
    try {
      final achievement = (await _databaseService.getAllAchievements())
          .firstWhere((a) => a.id == achievementId);

      final performance = await _databaseService.getPerformanceAnalytics(
        userId,
      );
      final userQuizzes = await _databaseService.getAllQuizzes();

      switch (achievement.id) {
        case 'badge_first_quiz':
          final completedQuizzes = userQuizzes
              .where((q) => q.isCompleted)
              .length;
          return completedQuizzes >= 1 ? 1.0 : 0.0;

        case 'badge_study_streak_5':
          final weeklyQuizzes = await _countWeeklyStudySessions(userId);
          return (weeklyQuizzes / 5.0).clamp(0.0, 1.0);

        case 'medal_perfect_score':
          if (performance != null) {
            final hasPerfectScore = performance.subjectPerformances.any(
              (sp) => sp.percentage >= 100.0,
            );
            return hasPerfectScore ? 1.0 : 0.0;
          }
          return 0.0;

        case 'medal_first_month':
          final monthlyQuizzes = await _countMonthlyQuizzes(userId);
          return (monthlyQuizzes / 20.0).clamp(0.0, 1.0);

        case 'ribbon_english_master':
        case 'ribbon_math_master':
        case 'ribbon_science_master':
          if (performance != null && achievement.subject.isNotEmpty) {
            final subjectPerformance = performance.getSubjectPerformance(
              achievement.subject,
            );
            if (subjectPerformance != null) {
              final percentageProgress = (subjectPerformance.percentage / 85.0)
                  .clamp(0.0, 1.0);
              final quizProgress = (subjectPerformance.quizzesTaken / 3.0)
                  .clamp(0.0, 1.0);
              // Combined progress (both percentage and quiz count matter)
              return (percentageProgress + quizProgress) / 2.0;
            }
          }
          return 0.0;

        default:
          return 0.0;
      }
    } catch (e) {
      print('Error calculating progress for $achievementId: $e');
      return 0.0;
    }
  }

  /// Helper to count weekly study sessions
  Future<int> _countWeeklyStudySessions(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final allQuizzes = await _databaseService.getAllQuizzes();
    return allQuizzes
        .where(
          (quiz) =>
              quiz.completedAt != null &&
              quiz.completedAt!.isAfter(weekStart) &&
              quiz.completedAt!.isBefore(weekEnd),
        )
        .length;
  }

  /// Helper to count monthly quizzes
  Future<int> _countMonthlyQuizzes(String userId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    final allQuizzes = await _databaseService.getAllQuizzes();
    return allQuizzes
        .where(
          (quiz) =>
              quiz.completedAt != null &&
              quiz.completedAt!.isAfter(monthStart) &&
              quiz.completedAt!.isBefore(monthEnd),
        )
        .length;
  }
}
