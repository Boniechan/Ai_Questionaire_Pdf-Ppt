import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _quizzesCollection = 'quizzes';
  static const String _questionsCollection = 'questions';
  static const String _userAnswersCollection = 'user_answers';
  static const String _achievementsCollection = 'achievements';
  static const String _userAchievementsCollection = 'user_achievements';
  static const String _performanceCollection = 'performance_analytics';

  Future<void> initialize() async {
    try {
      await FirebaseService.initialize();
      await FirebaseService.getCurrentUser();
      await initializeDefaultAchievements();
      print('Database service initialized with Firebase backend');
    } catch (e) {
      print('Error initializing database service: $e');
      rethrow;
    }
  }

  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }
    return user.uid;
  }

  // Add method to check if user is anonymous
  bool get isAnonymousUser {
    return _auth.currentUser?.isAnonymous ?? false;
  }

  // Add method to get user display name
  String get currentUserDisplayName {
    return _auth.currentUser?.displayName ?? 'User';
  }

  Future<String> saveQuiz(Quiz quiz) async {
    try {
      final batch = _firestore.batch();

      final quizRef = _firestore.collection(_quizzesCollection).doc(quiz.id);
      final quizData = quiz.toJson();
      quizData['userId'] = currentUserId;
      quizData.remove('questions');

      batch.set(quizRef, quizData);

      for (final question in quiz.questions) {
        final questionRef = quizRef
            .collection(_questionsCollection)
            .doc(question.id);
        batch.set(questionRef, question.toJson());
      }

      await batch.commit();
      print('Successfully saved quiz: ${quiz.title}');
      return quiz.id;
    } catch (e) {
      print('Error saving quiz: $e');
      rethrow;
    }
  }

  Future<void> updateQuiz(Quiz quiz) async {
    try {
      final quizRef = _firestore.collection(_quizzesCollection).doc(quiz.id);
      final quizData = quiz.toJson();
      quizData['userId'] = currentUserId;
      quizData.remove('questions');

      await quizRef.update(quizData);
      print('Successfully updated quiz: ${quiz.title}');
    } catch (e) {
      print('Error updating quiz: $e');
      rethrow;
    }
  }

  Future<Quiz?> getQuiz(String quizId) async {
    try {
      final quizDoc = await _firestore
          .collection(_quizzesCollection)
          .doc(quizId)
          .get();

      if (!quizDoc.exists) {
        return null;
      }

      final quizData = quizDoc.data()!;

      final questionsSnapshot = await quizDoc.reference
          .collection(_questionsCollection)
          .orderBy('order')
          .get();

      final questions = questionsSnapshot.docs
          .map((doc) => Question.fromJson(doc.data()))
          .toList();

      quizData['questions'] = questions.map((q) => q.toJson()).toList();

      return Quiz.fromJson(quizData);
    } catch (e) {
      print('Error fetching quiz $quizId: $e');
      return null;
    }
  }

  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final snapshot = await _firestore
          .collection(_quizzesCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final quizzes = <Quiz>[];

      for (final doc in snapshot.docs) {
        final quizData = doc.data();

        final questionsSnapshot = await doc.reference
            .collection(_questionsCollection)
            .orderBy('order')
            .get();

        final questions = questionsSnapshot.docs
            .map((qDoc) => Question.fromJson(qDoc.data()))
            .toList();

        quizData['questions'] = questions.map((q) => q.toJson()).toList();

        quizzes.add(Quiz.fromJson(quizData));
      }

      return quizzes;
    } catch (e) {
      print('Error fetching quizzes: $e');
      return [];
    }
  }

  Future<void> saveUserAnswer(String quizId, UserAnswer answer) async {
    try {
      final answerData = answer.toJson();
      answerData['userId'] = currentUserId;
      answerData['quizId'] = quizId;

      await _firestore
          .collection(_userAnswersCollection)
          .doc('${currentUserId}_${quizId}_${answer.questionId}')
          .set(answerData);

      print(
        'Successfully saved answer for quiz: $quizId, question: ${answer.questionId}',
      );
    } catch (e) {
      print('Error saving user answer: $e');
      rethrow;
    }
  }

  Future<List<UserAnswer>> getUserAnswers(String quizId) async {
    try {
      final snapshot = await _firestore
          .collection(_userAnswersCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('quizId', isEqualTo: quizId)
          .orderBy('answeredAt')
          .get();

      return snapshot.docs
          .map((doc) => UserAnswer.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching user answers for quiz $quizId: $e');
      return [];
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      final batch = _firestore.batch();

      final quizRef = _firestore.collection(_quizzesCollection).doc(quizId);
      batch.delete(quizRef);

      final questionsSnapshot = await quizRef
          .collection(_questionsCollection)
          .get();
      for (final doc in questionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final answersSnapshot = await _firestore
          .collection(_userAnswersCollection)
          .where('quizId', isEqualTo: quizId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (final doc in answersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Successfully deleted quiz: $quizId');
    } catch (e) {
      print('Error deleting quiz: $e');
      rethrow;
    }
  }

  Future<List<String>> checkForNewAchievements(String userId) async {
    try {
      final unlockedAchievements = <String>[];
      final userAchievements = await getUserAchievements(userId);
      final unlockedIds = userAchievements
          .map((ua) => ua.achievementId)
          .toSet();

      final allAchievements = await getAllAchievements();
      final analytics = await getPerformanceAnalytics(userId);

      if (analytics == null) return unlockedAchievements;

      for (final achievement in allAchievements) {
        if (unlockedIds.contains(achievement.id)) continue;

        bool shouldUnlock = false;

        switch (achievement.id) {
          case 'badge_first_quiz':
            shouldUnlock = analytics.totalQuizzes >= 1;
            break;
          case 'medal_perfect_score':
            shouldUnlock = analytics.subjectPerformances.any(
              (sp) => sp.percentage == 100.0,
            );
            break;
          case 'ribbon_english_master':
          case 'ribbon_math_master':
          case 'ribbon_science_master':
            final subject = achievement.subject;
            final subjectPerf = analytics.getSubjectPerformance(subject);
            shouldUnlock =
                subjectPerf != null &&
                subjectPerf.percentage >= 85.0 &&
                subjectPerf.quizzesTaken >= 3;
            break;
        }

        if (shouldUnlock) {
          await unlockAchievement(userId, achievement.id);
          unlockedAchievements.add(achievement.id);
        }
      }

      return unlockedAchievements;
    } catch (e) {
      print('Error checking for new achievements: $e');
      return [];
    }
  }

  Future<void> updatePerformanceAnalytics(
    String userId,
    String subject,
    bool isCorrect,
    int totalQuestions,
  ) async {
    try {
      final performanceRef = _firestore
          .collection(_performanceCollection)
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(performanceRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final analytics = PerformanceAnalytics.fromJson(data);

          final subjectPerformances = List<SubjectPerformance>.from(
            analytics.subjectPerformances,
          );
          final subjectIndex = subjectPerformances.indexWhere(
            (sp) => sp.subject == subject,
          );

          if (subjectIndex >= 0) {
            final existing = subjectPerformances[subjectIndex];
            final newCorrect = existing.correctAnswers + (isCorrect ? 1 : 0);
            final newTotal = existing.totalQuestions + 1;
            final newPercentage = (newCorrect / newTotal) * 100;

            subjectPerformances[subjectIndex] = SubjectPerformance(
              subject: subject,
              totalQuestions: newTotal,
              correctAnswers: newCorrect,
              percentage: newPercentage,
              quizzesTaken: existing.quizzesTaken,
              lastActivity: DateTime.now(),
            );
          } else {
            subjectPerformances.add(
              SubjectPerformance(
                subject: subject,
                totalQuestions: 1,
                correctAnswers: isCorrect ? 1 : 0,
                percentage: isCorrect ? 100.0 : 0.0,
                quizzesTaken: 1,
                lastActivity: DateTime.now(),
              ),
            );
          }

          final totalCorrect =
              analytics.totalCorrectAnswers + (isCorrect ? 1 : 0);
          final totalQs = analytics.totalQuestions + 1;
          final overallPercentage = (totalCorrect / totalQs) * 100;

          final updatedAnalytics = analytics.copyWith(
            subjectPerformances: subjectPerformances,
            totalQuestions: totalQs,
            totalCorrectAnswers: totalCorrect,
            overallPercentage: overallPercentage,
            lastUpdated: DateTime.now(),
          );

          transaction.update(performanceRef, updatedAnalytics.toJson());
        } else {
          final newAnalytics = PerformanceAnalytics(
            userId: userId,
            subjectPerformances: [
              SubjectPerformance(
                subject: subject,
                totalQuestions: 1,
                correctAnswers: isCorrect ? 1 : 0,
                percentage: isCorrect ? 100.0 : 0.0,
                quizzesTaken: 1,
                lastActivity: DateTime.now(),
              ),
            ],
            totalQuizzes: 1,
            totalQuestions: 1,
            totalCorrectAnswers: isCorrect ? 1 : 0,
            overallPercentage: isCorrect ? 100.0 : 0.0,
            totalStudyTime: Duration.zero,
            lastUpdated: DateTime.now(),
          );

          transaction.set(performanceRef, newAnalytics.toJson());
        }
      });

      print(
        'Performance analytics updated for $subject: ${isCorrect ? 'correct' : 'incorrect'}',
      );
    } catch (e) {
      print('Error updating performance analytics: $e');
      rethrow;
    }
  }

  Future<PerformanceAnalytics?> getPerformanceAnalytics(String userId) async {
    try {
      final doc = await _firestore
          .collection(_performanceCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return PerformanceAnalytics.fromJson(doc.data()!);
    } catch (e) {
      print('Error fetching performance analytics for: $userId');
      return null;
    }
  }

  Future<List<Achievement>> getAllAchievements() async {
    try {
      final snapshot = await _firestore
          .collection(_achievementsCollection)
          .get();

      if (snapshot.docs.isEmpty) {
        await initializeDefaultAchievements();
        return _getDefaultAchievements();
      }

      return snapshot.docs
          .map((doc) => Achievement.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching achievements: $e');
      return _getDefaultAchievements();
    }
  }

  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_userAchievementsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => UserAchievement.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching user achievements for: $userId');
      return [];
    }
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      final userAchievementRef = _firestore
          .collection(_userAchievementsCollection)
          .doc('${userId}_$achievementId');

      final existing = await userAchievementRef.get();
      if (existing.exists) {
        print('Achievement $achievementId already unlocked for user $userId');
        return;
      }

      final userAchievement = UserAchievement(
        userId: userId,
        achievementId: achievementId,
        unlockedAt: DateTime.now(),
      );

      await userAchievementRef.set(userAchievement.toJson());
      print(
        'Successfully unlocked achievement: $achievementId for user: $userId',
      );
    } catch (e) {
      print('Error unlocking achievement: $e');
      rethrow;
    }
  }

  Future<void> initializeDefaultAchievements() async {
    try {
      final batch = _firestore.batch();
      final defaultAchievements = _getDefaultAchievements();

      for (final achievement in defaultAchievements) {
        final achievementRef = _firestore
            .collection(_achievementsCollection)
            .doc(achievement.id);

        batch.set(achievementRef, achievement.toJson());
      }

      await batch.commit();
      print(
        'Successfully initialized ${defaultAchievements.length} default achievements',
      );
    } catch (e) {
      print('Error initializing default achievements: $e');
      rethrow;
    }
  }

  Future<bool> isConnected() async {
    try {
      await _firestore.collection('_health_check').limit(1).get();
      return true;
    } catch (e) {
      print('Database connection check failed: $e');
      return false;
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final stats = <String, int>{};

      final quizzesSnapshot = await _firestore
          .collection(_quizzesCollection)
          .where('userId', isEqualTo: currentUserId)
          .count()
          .get();
      stats['quizzes'] = quizzesSnapshot.count ?? 0;

      final answersSnapshot = await _firestore
          .collection(_userAnswersCollection)
          .where('userId', isEqualTo: currentUserId)
          .count()
          .get();
      stats['answers'] = answersSnapshot.count ?? 0;

      final achievementsSnapshot = await _firestore
          .collection(_achievementsCollection)
          .count()
          .get();
      stats['total_achievements'] = achievementsSnapshot.count ?? 0;

      final userAchievementsSnapshot = await _firestore
          .collection(_userAchievementsCollection)
          .where('userId', isEqualTo: currentUserId)
          .count()
          .get();
      stats['unlocked_achievements'] = userAchievementsSnapshot.count ?? 0;

      return stats;
    } catch (e) {
      print('Error getting database stats: $e');
      return {};
    }
  }

  Future<void> cleanupOldData({int daysOld = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

      final oldQuizzesSnapshot = await _firestore
          .collection(_quizzesCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: QuizStatus.notStarted.index)
          .where('createdAt', isLessThan: cutoffTimestamp)
          .get();

      final batch = _firestore.batch();

      for (final doc in oldQuizzesSnapshot.docs) {
        batch.delete(doc.reference);

        final questionsSnapshot = await doc.reference
            .collection(_questionsCollection)
            .get();

        for (final questionDoc in questionsSnapshot.docs) {
          batch.delete(questionDoc.reference);
        }
      }

      await batch.commit();
      print('Cleaned up ${oldQuizzesSnapshot.docs.length} old quizzes');
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: 'badge_first_quiz',
        name: 'First Steps',
        description: 'Completed your first quiz',
        type: AchievementType.badge,
        category: AchievementCategory.progress,
        iconPath: 'assets/badges/first_quiz.png',
        criteria: {'quizzes_completed': 1},
      ),
      Achievement(
        id: 'badge_study_streak_5',
        name: 'Study Streak',
        description: 'Completed 5 study sessions this week',
        type: AchievementType.badge,
        category: AchievementCategory.consistency,
        iconPath: 'assets/badges/study_streak.png',
        criteria: {'weekly_sessions': 5},
      ),
      Achievement(
        id: 'badge_focused_learner',
        name: 'Focused Learner',
        description: 'Focused for 30 minutes without distraction',
        type: AchievementType.badge,
        category: AchievementCategory.consistency,
        iconPath: 'assets/badges/focused.png',
        criteria: {'focus_time_minutes': 30},
      ),

      Achievement(
        id: 'medal_first_month',
        name: 'Monthly Scholar',
        description: 'First full month of studying',
        type: AchievementType.medal,
        category: AchievementCategory.milestone,
        iconPath: 'assets/medals/first_month.png',
        criteria: {'active_days_in_month': 20},
      ),
      Achievement(
        id: 'medal_perfect_score',
        name: 'Perfect Scholar',
        description: 'Achieved 100% on a quiz',
        type: AchievementType.medal,
        category: AchievementCategory.milestone,
        iconPath: 'assets/medals/perfect_score.png',
        criteria: {'perfect_quiz': true},
      ),

      Achievement(
        id: 'ribbon_english_master',
        name: 'English Master',
        description: 'Best in English',
        type: AchievementType.ribbon,
        category: AchievementCategory.subject,
        iconPath: 'assets/ribbons/english.png',
        subject: 'English',
        criteria: {'subject_mastery': 'English', 'min_percentage': 85.0},
      ),
      Achievement(
        id: 'ribbon_math_master',
        name: 'Math Master',
        description: 'Best in Math',
        type: AchievementType.ribbon,
        category: AchievementCategory.subject,
        iconPath: 'assets/ribbons/math.png',
        subject: 'Math',
        criteria: {'subject_mastery': 'Math', 'min_percentage': 85.0},
      ),
      Achievement(
        id: 'ribbon_science_master',
        name: 'Science Master',
        description: 'Best in Science',
        type: AchievementType.ribbon,
        category: AchievementCategory.subject,
        iconPath: 'assets/ribbons/science.png',
        subject: 'Science',
        criteria: {'subject_mastery': 'Science', 'min_percentage': 85.0},
      ),
    ];
  }

  // Add this method to your DatabaseService class
  Future<void> updateQuizPerformanceAnalytics(
    int totalQuestions,
    int correctAnswers,
    String subject,
  ) async {
    try {
      final userId = currentUserId;
      final performance = {
        'userId': userId,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'incorrectAnswers': totalQuestions - correctAnswers,
        'subject': subject,
        'percentage': (correctAnswers / totalQuestions) * 100,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_performanceCollection)
          .doc(userId)
          .collection('quiz_attempts')
          .add(performance);

      print('Performance analytics updated successfully');
    } catch (e) {
      print('Error updating performance analytics: $e');
      throw e;
    }
  }
}
