import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service_firebase.dart';
import '../services/document_service.dart';
import '../services/ai_service.dart';

class QuizProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final DocumentService _documentService = DocumentService();
  final AIService _aiService = AIService();

  List<Quiz> _quizzes = [];
  Quiz? _currentQuiz;
  bool _isLoading = false;
  String? _error;

  List<Quiz> get quizzes => _quizzes;
  Quiz? get currentQuiz => _currentQuiz;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all quizzes from database
  Future<void> loadQuizzes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _quizzes = await _databaseService.getAllQuizzes();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create quiz from document file (PDF or PowerPoint)
  Future<Quiz?> createQuizFromDocument({
    required File documentFile,
    required String title,
    required int numberOfQuestions,
    required List<QuestionType> questionTypes,
    required DifficultyLevel difficulty,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('=== DEBUG: Creating quiz from document ===');
      print('File: ${documentFile.path}');
      print('Title: $title');
      print('Number of questions: $numberOfQuestions');
      print('Question types: ${questionTypes.map((t) => t.name).join(', ')}');
      print('Difficulty: ${difficulty.name}');

      // Check if file format is supported
      if (!_documentService.isSupportedDocument(documentFile.path)) {
        throw Exception(
          'Unsupported file format. Supported formats: PDF, PPT, PPTX',
        );
      }

      // Extract text from document
      print('Extracting text from document...');
      final extractedText = await _documentService.extractTextFromDocument(
        documentFile,
      );
      final cleanText = _documentService.preprocessText(extractedText);
      print('Extracted text length: ${cleanText.length}');

      // Determine subject
      final subject = _aiService.determineSubject(cleanText);
      print('Determined subject: $subject');

      // Generate questions
      print('Generating questions...');
      final questions = await _aiService.generateQuestions(
        content: cleanText,
        subject: subject,
        numberOfQuestions: numberOfQuestions,
        questionTypes: questionTypes,
        difficulty: difficulty,
      );

      print('Generated ${questions.length} questions');

      // Create quiz
      final quiz = Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        subject: subject,
        sourceFileName: documentFile.path.split('/').last,
        questions: questions,
        createdAt: DateTime.now(),
        status: QuizStatus.notStarted,
      );

      print('Created quiz with ID: ${quiz.id}');

      // Save to database
      print('Saving quiz to database...');
      await _databaseService.saveQuiz(quiz);

      // Add to local list
      _quizzes.insert(0, quiz);

      _isLoading = false;
      notifyListeners();

      print('Quiz creation completed successfully');
      return quiz;
    } catch (e) {
      print('Error creating quiz: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Create quiz from PDF file (deprecated - use createQuizFromDocument)
  @Deprecated('Use createQuizFromDocument instead')
  Future<Quiz?> createQuizFromPdf({
    required File pdfFile,
    required String title,
    required int numberOfQuestions,
    required List<QuestionType> questionTypes,
    required DifficultyLevel difficulty,
  }) async {
    return createQuizFromDocument(
      documentFile: pdfFile,
      title: title,
      numberOfQuestions: numberOfQuestions,
      questionTypes: questionTypes,
      difficulty: difficulty,
    );
  }

  /// Start a quiz
  Future<void> startQuiz(String quizId) async {
    try {
      final quiz = await _databaseService.getQuiz(quizId);
      if (quiz != null) {
        // Create updated quiz with in-progress status
        final updatedQuiz = Quiz(
          id: quiz.id,
          title: quiz.title,
          subject: quiz.subject,
          questions: quiz.questions,
          createdAt: quiz.createdAt,
          sourceFileName: quiz.sourceFileName,
          status: QuizStatus.inProgress,
        );

        _currentQuiz = updatedQuiz;
        await _databaseService.updateQuiz(_currentQuiz!);

        // Update in local list too
        final index = _quizzes.indexWhere((q) => q.id == quizId);
        if (index != -1) {
          _quizzes[index] = updatedQuiz;
        }

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Submit answer for current question
  Future<void> submitAnswer({
    required String questionId,
    required String answer,
    required bool isCorrect, // Add this parameter
    List<String>? answers,
  }) async {
    if (_currentQuiz == null) return;

    try {
      final userAnswer = UserAnswer(
        questionId: questionId,
        answer: answer,
        answers: answers ?? [],
        isCorrect: isCorrect, // Use the passed value
        answeredAt: DateTime.now(),
      );

      // Save answer to database
      await _databaseService.saveUserAnswer(_currentQuiz!.id, userAnswer);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Complete the current quiz
  Future<void> completeQuiz({
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    if (_currentQuiz == null) return;

    try {
      final percentage = (correctAnswers / totalQuestions) * 100;

      // Create completed quiz
      final completedQuiz = Quiz(
        id: _currentQuiz!.id,
        title: _currentQuiz!.title,
        subject: _currentQuiz!.subject,
        questions: _currentQuiz!.questions,
        createdAt: _currentQuiz!.createdAt,
        sourceFileName: _currentQuiz!.sourceFileName,
        status: QuizStatus.completed,
        percentage: percentage,
      );

      await _databaseService.updateQuiz(completedQuiz);

      // Update quiz in the list
      final index = _quizzes.indexWhere((q) => q.id == _currentQuiz!.id);
      if (index != -1) {
        _quizzes[index] = completedQuiz;
      }

      _currentQuiz = completedQuiz;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get quiz by ID
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      return await _databaseService.getQuiz(quizId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update quiz
  Future<void> updateQuiz(Quiz updatedQuiz) async {
    try {
      print('Updating quiz: ${updatedQuiz.title}');
      await _databaseService.updateQuiz(updatedQuiz);

      // Update the quiz in the local list
      final index = _quizzes.indexWhere((quiz) => quiz.id == updatedQuiz.id);
      if (index != -1) {
        _quizzes[index] = updatedQuiz;
      }

      // Update current quiz if it's the same one
      if (_currentQuiz?.id == updatedQuiz.id) {
        _currentQuiz = updatedQuiz;
      }

      notifyListeners();
      print('Quiz updated successfully: ${updatedQuiz.title}');
    } catch (e) {
      print('Error updating quiz: $e');
      _error = 'Failed to update quiz: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _databaseService.deleteQuiz(quizId);

      // Remove from local list
      _quizzes.removeWhere((quiz) => quiz.id == quizId);

      // Clear current quiz if it's the deleted one
      if (_currentQuiz?.id == quizId) {
        _currentQuiz = null;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear current quiz
  void clearCurrentQuiz() {
    _currentQuiz = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh quizzes
  Future<void> refreshQuizzes() async {
    await loadQuizzes();
  }

  /// Get quiz statistics
  Map<String, int> getQuizStatistics() {
    final total = _quizzes.length;
    final completed = _quizzes
        .where((q) => q.status == QuizStatus.completed)
        .length;
    final inProgress = _quizzes
        .where((q) => q.status == QuizStatus.inProgress)
        .length;
    final notStarted = _quizzes
        .where((q) => q.status == QuizStatus.notStarted)
        .length;

    return {
      'total': total,
      'completed': completed,
      'inProgress': inProgress,
      'notStarted': notStarted,
    };
  }

  /// Get average score
  double getAverageScore() {
    final completedQuizzes = _quizzes
        .where((q) => q.status == QuizStatus.completed && q.percentage != null)
        .toList();

    if (completedQuizzes.isEmpty) return 0.0;

    final totalScore = completedQuizzes
        .map((q) => q.percentage!)
        .reduce((a, b) => a + b);

    return totalScore / completedQuizzes.length;
  }
}
