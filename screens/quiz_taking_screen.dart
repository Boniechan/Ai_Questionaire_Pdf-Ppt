import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/quiz_provider.dart';
import '../services/database_service_firebase.dart';
import 'quiz_results_screen.dart';

class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizTakingScreen({super.key, required this.quiz});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  List<String> userAnswers = [];
  List<String> enumerationAnswers = []; // For enumeration questions
  int correctAnswers = 0;
  bool isAnswered = false;
  TextEditingController enumerationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userAnswers = List.filled(widget.quiz.questions.length, '');
  }

  @override
  void dispose() {
    enumerationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Text('No questions available for this quiz.'),
        ),
      );
    }

    final question = widget.quiz.questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${currentQuestionIndex + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Answer Options
                  Expanded(
                    child: question.type == QuestionType.trueFalse
                        ? _buildTrueFalseOptions()
                        : question.type == QuestionType.enumeration
                        ? _buildEnumerationInput()
                        : _buildMultipleChoiceOptions(question),
                  ),

                  // Submit/Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canSubmit()
                          ? () {
                              if (!isAnswered) {
                                _submitAnswer();
                              } else {
                                _nextQuestion();
                              }
                            }
                          : null,
                      child: Text(
                        isAnswered
                            ? (currentQuestionIndex <
                                      widget.quiz.questions.length - 1
                                  ? 'Next Question'
                                  : 'Finish Quiz')
                            : 'Submit Answer',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    final question = widget.quiz.questions[currentQuestionIndex];
    switch (question.type) {
      case QuestionType.enumeration:
        return enumerationAnswers.isNotEmpty;
      default:
        return selectedAnswer != null && selectedAnswer!.isNotEmpty;
    }
  }

  Widget _buildTrueFalseOptions() {
    return Column(
      children: [_buildOptionCard('True'), _buildOptionCard('False')],
    );
  }

  Widget _buildEnumerationInput() {
    return Column(
      children: [
        TextField(
          controller: enumerationController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your answers separated by commas...',
            labelText: 'Your Answers',
          ),
          maxLines: 3,
          onChanged: (value) {
            setState(() {
              enumerationAnswers = value
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Separate multiple answers with commas',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceOptions(Question question) {
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        return _buildOptionCard(option);
      },
    );
  }

  Widget _buildOptionCard(String option) {
    final isSelected = selectedAnswer == option;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: isSelected ? 4 : 2,
        color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : null,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16.0),
          onTap: isAnswered
              ? null
              : () {
                  setState(() {
                    selectedAnswer = option;
                  });
                },
          leading: Radio<String>(
            value: option,
            groupValue: selectedAnswer,
            onChanged: isAnswered
                ? null
                : (value) {
                    setState(() {
                      selectedAnswer = value;
                    });
                  },
            activeColor: const Color(0xFF6366F1),
          ),
          title: Text(
            option,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF6366F1) : null,
            ),
          ),
        ),
      ),
    );
  }

  void _submitAnswer() {
    final question = widget.quiz.questions[currentQuestionIndex];
    bool isCorrect = false;

    // Determine if answer is correct based on question type
    switch (question.type) {
      case QuestionType.enumeration:
        isCorrect = _validateEnumerationAnswer(question);
        userAnswers[currentQuestionIndex] = enumerationAnswers.join(', ');
        break;
      default:
        isCorrect = selectedAnswer == question.correctAnswer;
        userAnswers[currentQuestionIndex] = selectedAnswer!;
        break;
    }

    if (isCorrect) {
      correctAnswers++;
    }

    setState(() {
      isAnswered = true;
    });

    _showAnswerFeedback(question, isCorrect);
  }

  bool _validateEnumerationAnswer(Question question) {
    final normalizedCorrect = question.correctAnswers
        .map((a) => a.toLowerCase().trim())
        .toSet();
    final normalizedUser = enumerationAnswers
        .map((a) => a.toLowerCase().trim())
        .toSet();

    return normalizedCorrect.containsAll(normalizedUser) &&
        normalizedUser.containsAll(normalizedCorrect);
  }

  void _showAnswerFeedback(Question question, bool isCorrect) {
    String yourAnswer;
    String correctAnswer;

    switch (question.type) {
      case QuestionType.enumeration:
        yourAnswer = enumerationAnswers.join(', ');
        correctAnswer = question.correctAnswers.join(', ');
        break;
      default:
        yourAnswer = selectedAnswer ?? '';
        correctAnswer = question.correctAnswer;
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isCorrect ? 'Correct!' : 'Incorrect',
              style: TextStyle(
                color: isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your answer: $yourAnswer',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (!isCorrect) ...[
              Text(
                'Correct answer: $correctAnswer',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (question.explanation.isNotEmpty) ...[
              const Text(
                'Explanation:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(question.explanation, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: Text(
              currentQuestionIndex < widget.quiz.questions.length - 1
                  ? 'Next Question'
                  : 'Finish Quiz',
            ),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        enumerationAnswers.clear();
        enumerationController.clear();
        isAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    final percentage = (correctAnswers / widget.quiz.questions.length * 100)
        .round();

    try {
      // Create updated quiz with completed status and percentage
      final updatedQuiz = Quiz(
        id: widget.quiz.id,
        title: widget.quiz.title,
        subject: widget.quiz.subject,
        questions: widget.quiz.questions,
        createdAt: widget.quiz.createdAt,
        sourceFileName: widget.quiz.sourceFileName,
        status: QuizStatus.completed,
        percentage: percentage.toDouble(),
      );

      // Update quiz in provider
      await context.read<QuizProvider>().updateQuiz(updatedQuiz);

      // Save performance data
      await _savePerformanceData(percentage);

      // Show results
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultsScreen(
              quiz: updatedQuiz,
              correctAnswers: correctAnswers,
              totalQuestions: widget.quiz.questions.length,
              userAnswers: userAnswers,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error finishing quiz: $e');
      // Still show results even if update fails
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultsScreen(
              quiz: widget.quiz,
              correctAnswers: correctAnswers,
              totalQuestions: widget.quiz.questions.length,
              userAnswers: userAnswers,
            ),
          ),
        );
      }
    }
  }

  Future<void> _savePerformanceData(int percentage) async {
    try {
      final databaseService = DatabaseService();

      // Update quiz performance analytics
      await databaseService.updateQuizPerformanceAnalytics(
        widget.quiz.questions.length,
        correctAnswers,
        widget.quiz.subject,
      );

      print('Performance data saved successfully');
    } catch (e) {
      print('Error saving performance data: $e');
    }
  }
}
