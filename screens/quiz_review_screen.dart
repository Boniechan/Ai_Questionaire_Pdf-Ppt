import 'package:flutter/material.dart';
import '../models/models.dart';

class QuizReviewScreen extends StatelessWidget {
  final Quiz quiz;
  final List<String> userAnswers;

  const QuizReviewScreen({
    super.key,
    required this.quiz,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Answers')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: quiz.questions.length,
        itemBuilder: (context, index) {
          final question = quiz.questions[index];
          final userAnswer = index < userAnswers.length
              ? userAnswers[index]
              : '';
          final isCorrect = userAnswer == question.correctAnswer;

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(question.text, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),

                  // Show all options with indicators
                  ...question.options.map((option) {
                    final isUserAnswer = option == userAnswer;
                    final isCorrectAnswer = option == question.correctAnswer;

                    Color? backgroundColor;
                    IconData? icon;
                    Color? iconColor;

                    if (isCorrectAnswer) {
                      backgroundColor = Colors.green.withOpacity(0.1);
                      icon = Icons.check_circle;
                      iconColor = Colors.green;
                    } else if (isUserAnswer && !isCorrect) {
                      backgroundColor = Colors.red.withOpacity(0.1);
                      icon = Icons.cancel;
                      iconColor = Colors.red;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: (isUserAnswer || isCorrectAnswer)
                            ? Border.all(
                                color: isCorrectAnswer
                                    ? Colors.green
                                    : Colors.red,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: iconColor, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Expanded(child: Text(option)),
                          if (isUserAnswer && !isCorrectAnswer)
                            const Text(
                              'Your answer',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (isCorrectAnswer)
                            const Text(
                              'Correct answer',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (question.explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explanation:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(question.explanation),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
