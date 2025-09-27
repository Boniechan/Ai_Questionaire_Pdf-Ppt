import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service_firebase.dart';

class PerformanceProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  PerformanceAnalytics? _performanceAnalytics;
  bool _isLoading = false;
  String? _error;

  // Getters
  PerformanceAnalytics? get performanceAnalytics => _performanceAnalytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add this getter for overall percentage
  double get overallPercentage {
    return _performanceAnalytics?.overallPercentage ?? 0.0;
  }

  // Add alias method for home screen compatibility
  Future<void> loadPerformanceAnalytics(String userId) async {
    await loadPerformanceData(userId);
  }

  /// Load performance data for the current user
  Future<void> loadPerformanceData([String? userId]) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Use current user ID from database service if not provided
      final currentUserId = userId ?? _databaseService.currentUserId;

      _performanceAnalytics = await _databaseService.getPerformanceAnalytics(
        currentUserId,
      );

      // If no data exists, create initial empty analytics
      if (_performanceAnalytics == null) {
        _performanceAnalytics = PerformanceAnalytics(
          userId: currentUserId,
          subjectPerformances: [],
          totalQuizzes: 0,
          totalQuestions: 0,
          totalCorrectAnswers: 0,
          overallPercentage: 0.0,
          totalStudyTime: Duration.zero,
          lastUpdated: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update performance after quiz completion
  Future<void> updateQuizPerformance({
    required String subject,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    try {
      // Update quiz count first
      final performanceRef = FirebaseFirestore.instance
          .collection('performance_analytics')
          .doc(_databaseService.currentUserId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(performanceRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final analytics = PerformanceAnalytics.fromJson(data);

          // Update total quiz count
          final updatedAnalytics = analytics.copyWith(
            totalQuizzes: analytics.totalQuizzes + 1,
            lastUpdated: DateTime.now(),
          );

          transaction.update(performanceRef, updatedAnalytics.toJson());
        } else {
          // Create new analytics with first quiz
          final newAnalytics = PerformanceAnalytics(
            userId: _databaseService.currentUserId,
            subjectPerformances: [],
            totalQuizzes: 1,
            totalQuestions: 0,
            totalCorrectAnswers: 0,
            overallPercentage: 0.0,
            totalStudyTime: Duration.zero,
            lastUpdated: DateTime.now(),
          );

          transaction.set(performanceRef, newAnalytics.toJson());
        }
      });

      // Update each question's performance
      for (int i = 0; i < totalQuestions; i++) {
        final isCorrect = i < correctAnswers;
        await _databaseService.updatePerformanceAnalytics(
          _databaseService.currentUserId,
          subject,
          isCorrect,
          totalQuestions,
        );
      }

      // Reload performance data to get updated stats
      await loadPerformanceData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get subject category based on percentage
  String getSubjectCategory(double percentage) {
    if (percentage >= 85) return 'Expert';
    if (percentage >= 70) return 'Good';
    return 'Needs Improvement';
  }

  /// Get color for subject category
  Color getSubjectCategoryColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  /// Get performance color based on percentage
  Color getPerformanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  /// Get expert subjects (85% and above)
  List<SubjectPerformance> get expertSubjects {
    if (_performanceAnalytics == null) return [];
    return _performanceAnalytics!.subjectPerformances
        .where((subject) => subject.percentage >= 85)
        .toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  /// Get good subjects (70-84%)
  List<SubjectPerformance> get goodSubjects {
    if (_performanceAnalytics == null) return [];
    return _performanceAnalytics!.subjectPerformances
        .where((subject) => subject.percentage >= 70 && subject.percentage < 85)
        .toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  /// Get subjects that need improvement (<70%)
  List<SubjectPerformance> get needsImprovementSubjects {
    if (_performanceAnalytics == null) return [];
    return _performanceAnalytics!.subjectPerformances
        .where((subject) => subject.percentage < 70)
        .toList()
      ..sort((a, b) => a.percentage.compareTo(b.percentage));
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
