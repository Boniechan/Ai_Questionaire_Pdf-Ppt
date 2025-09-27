import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/achievement_provider.dart';
import '../providers/performance_provider.dart';
import '../services/database_service_firebase.dart';
import 'quiz_review_screen.dart';

class QuizResultsScreen extends StatefulWidget {
  final Quiz quiz;
  final int correctAnswers;
  final int totalQuestions;
  final List<String> userAnswers;

  const QuizResultsScreen({
    super.key,
    required this.quiz,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.userAnswers,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Achievement> newAchievements = [];
  bool hasCheckedAchievements = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePerformanceAndCheckAchievements();
    });
  }

  Future<void> _updatePerformanceAndCheckAchievements() async {
    if (hasCheckedAchievements) return;

    final achievementProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );
    final performanceProvider = Provider.of<PerformanceProvider>(
      context,
      listen: false,
    );

    try {
      final userId = _databaseService.currentUserId;

      // Update performance analytics in Firebase first
      await performanceProvider.updateQuizPerformance(
        subject: widget.quiz.subject,
        totalQuestions: widget.totalQuestions,
        correctAnswers: widget.correctAnswers,
      );

      // Load achievements if not already loaded
      if (achievementProvider.achievements.isEmpty) {
        await achievementProvider.loadAchievements(userId);
      }

      // Check for newly unlocked achievements
      final achievements = await achievementProvider.checkAchievementsAfterQuiz(
        userId: userId,
        correctAnswers: widget.correctAnswers,
        totalQuestions: widget.totalQuestions,
        subject: widget.quiz.subject,
        quizStreak: 1, // You can implement actual streak tracking later
        totalQuizzesCompleted:
            performanceProvider.performanceAnalytics?.totalQuizzes ?? 0,
      );

      if (achievements.isNotEmpty && mounted) {
        setState(() {
          newAchievements = achievements;
          hasCheckedAchievements = true;
        });
        _showAchievementDialog();
      } else {
        setState(() {
          hasCheckedAchievements = true;
        });
      }
    } catch (e) {
      debugPrint('Error updating performance and checking achievements: $e');
      setState(() {
        hasCheckedAchievements = true;
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save performance data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAchievementDialog() {
    if (newAchievements.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Achievement Unlocked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: newAchievements
              .map(
                (achievement) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              achievement.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.correctAnswers / widget.totalQuestions * 100)
        .round();
    final passed = percentage >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Results Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      passed ? Icons.emoji_events : Icons.info_outline,
                      size: 64,
                      color: passed ? Colors.amber : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      passed ? 'Congratulations!' : 'Keep Learning!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You scored $percentage%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: passed ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.correctAnswers} out of ${widget.totalQuestions} correct answers',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Consumer<PerformanceProvider>(
                      builder: (context, provider, child) {
                        final category = provider.getSubjectCategory(
                          percentage.toDouble(),
                        );
                        final color = provider.getSubjectCategoryColor(
                          percentage.toDouble(),
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$category Level',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizReviewScreen(
                        quiz: widget.quiz,
                        userAnswers: widget.userAnswers,
                      ),
                    ),
                  );
                },
                child: const Text('Review Answers'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
