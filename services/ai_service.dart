import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

class AIService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<List<Question>> generateQuestions({
    required String content,
    required String subject,
    required int numberOfQuestions,
    required List<QuestionType> questionTypes,
    required DifficultyLevel difficulty,
  }) async {
    try {
      print('=== DEBUG: Starting quiz generation with Gemini ===');
      print('Content length: ${content.length}');
      print('Subject: $subject');
      print('Number of questions: $numberOfQuestions');
      print('Question types: ${questionTypes.map((t) => t.name).join(', ')}');
      print('API Key exists: ${_apiKey.isNotEmpty}');

      if (_apiKey.isEmpty) {
        print('ERROR: No Gemini API key found');
        throw Exception('Gemini API key is missing from .env file');
      }

      if (content.length < 50) {
        throw Exception(
          'Content is too short (${content.length} chars). Please upload a document with more text.',
        );
      }

      // Show content preview for debugging
      print(
        'Content preview: ${content.substring(0, min(300, content.length))}...',
      );

      // Generate all questions in one API call for efficiency
      final questions = await _generateAllQuestionsAtOnce(
        content: content,
        subject: subject,
        numberOfQuestions: numberOfQuestions,
        questionTypes: questionTypes,
        difficulty: difficulty,
      );

      print('=== FINAL QUESTIONS GENERATED ===');
      for (int i = 0; i < questions.length; i++) {
        print('Q${i + 1} [${questions[i].type.name}]: ${questions[i].text}');
        if (questions[i].type == QuestionType.multipleChoice) {
          print('   Options: ${questions[i].options.join(", ")}');
          print('   Correct: ${questions[i].correctAnswer}');
        }
      }

      return questions.take(numberOfQuestions).toList();
    } catch (e, stackTrace) {
      print('=== ERROR in generateQuestions ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to generate questions from your document: $e');
    }
  }

  Future<List<Question>> _generateAllQuestionsAtOnce({
    required String content,
    required String subject,
    required int numberOfQuestions,
    required List<QuestionType> questionTypes,
    required DifficultyLevel difficulty,
  }) async {
    final prompt = _buildCombinedPrompt(
      content: content,
      subject: subject,
      numberOfQuestions: numberOfQuestions,
      questionTypes: questionTypes,
      difficulty: difficulty,
    );

    print('Making Gemini API request...');
    final response = await _makeGeminiRequest(prompt);
    return _parseAIResponse(response, subject, difficulty);
  }

  String _buildCombinedPrompt({
    required String content,
    required String subject,
    required int numberOfQuestions,
    required List<QuestionType> questionTypes,
    required DifficultyLevel difficulty,
  }) {
    // Build examples for each question type
    String examples = '';

    if (questionTypes.contains(QuestionType.multipleChoice)) {
      examples += '''
Multiple Choice Example:
{
  "type": "multipleChoice",
  "text": "According to the document, [specific question based on content]?",
  "options": ["Correct answer from content", "Wrong but plausible", "Another wrong option", "Fourth wrong option"],
  "correctAnswer": "Correct answer from content",
  "explanation": "This is correct because the document states: [quote from content]"
}

''';
    }

    if (questionTypes.contains(QuestionType.trueFalse)) {
      examples += '''
True/False Example:
{
  "type": "trueFalse", 
  "text": "The document states that [specific fact from content].",
  "options": ["True", "False"],
  "correctAnswer": "True",
  "explanation": "This is true because the content explicitly mentions: [quote]"
}

''';
    }

    if (questionTypes.contains(QuestionType.enumeration)) {
      examples += '''
Enumeration Example:
{
  "type": "enumeration",
  "text": "List the main [category from content] mentioned in the document:",
  "options": [],
  "correctAnswer": "",
  "correctAnswers": ["First item", "Second item", "Third item"],
  "explanation": "These items are specifically listed in the content."
}

''';
    }

    return '''
You are creating $numberOfQuestions quiz questions for a $subject document at $difficulty level.

CRITICAL INSTRUCTIONS:
- Read the provided content CAREFULLY
- Create questions based EXCLUSIVELY on specific information from this content
- Use actual facts, names, numbers, concepts, and details from the text
- Generate a mix of question types: ${questionTypes.map((t) => t.name).join(', ')}
- Every question must be answerable using ONLY the provided content
- Do NOT create generic questions

CONTENT TO ANALYZE:
"$content"

QUESTION TYPES TO CREATE:
$examples

Response format (valid JSON only):
{
  "questions": [
    // Generate exactly $numberOfQuestions questions mixing the types above
    // Use actual content from the document provided
  ]
}

Create exactly $numberOfQuestions questions now based on the specific content above.''';
  }

  Future<String> _makeGeminiRequest(String prompt) async {
    try {
      print('=== Making Gemini API request ===');

      // FIXED: Use the correct model name
      final response = await http.post(
        Uri.parse(
          '$_baseUrl/models/gemini-2.0-flash:generateContent?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 8192,
            'stopSequences': [],
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      print('Gemini API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if the response has candidates
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          print('No candidates in response: ${response.body}');
          throw Exception('Gemini returned no content candidates');
        }

        // Add usage tracking for Gemini
        if (data['usageMetadata'] != null) {
          final usage = data['usageMetadata'];
          print(
            'Token usage - Input: ${usage['promptTokenCount']}, Output: ${usage['candidatesTokenCount']}',
          );
          print('Total tokens: ${usage['totalTokenCount']}');
        }

        final content = data['candidates'][0]['content']['parts'][0]['text'];
        print('Gemini response received: ${content.length} characters');
        print(
          'Response preview: ${content.substring(0, min(200, content.length))}...',
        );
        return content;
      } else {
        print('Gemini API ERROR: ${response.statusCode}');
        print('Error response: ${response.body}');
        throw Exception(
          'Gemini API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Exception in Gemini API call: $e');
      rethrow;
    }
  }

  List<Question> _parseAIResponse(
    String response,
    String subject,
    DifficultyLevel difficulty,
  ) {
    try {
      print('Parsing Gemini response...');

      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      cleanResponse = cleanResponse.trim();

      print(
        'Cleaned response: ${cleanResponse.substring(0, min(300, cleanResponse.length))}...',
      );

      final data = jsonDecode(cleanResponse);

      // Check if questions exist
      if (data['questions'] == null) {
        print('No questions found in response');
        throw Exception('No questions found in AI response');
      }

      final questions = data['questions'] as List;

      print('Parsed ${questions.length} questions from response');

      return questions.map((q) {
        QuestionType type;
        switch (q['type']) {
          case 'multipleChoice':
            type = QuestionType.multipleChoice;
            break;
          case 'trueFalse':
            type = QuestionType.trueFalse;
            break;
          case 'enumeration':
            type = QuestionType.enumeration;
            break;
          default:
            type = QuestionType.multipleChoice; // fallback
        }

        final question = Question(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              questions.indexOf(q).toString(),
          text: q['text'] ?? 'Question text missing',
          type: type,
          options: List<String>.from(q['options'] ?? []),
          correctAnswer: q['correctAnswer'] ?? '',
          correctAnswers: List<String>.from(q['correctAnswers'] ?? []),
          subject: subject,
          difficulty: difficulty,
          explanation: q['explanation'] ?? '',
          createdAt: DateTime.now(),
        );

        print('Created question: ${question.text}');
        return question;
      }).toList();
    } catch (e) {
      print('Error parsing Gemini response: $e');
      print('Raw response: $response');
      throw Exception('Failed to parse Gemini response: $e');
    }
  }

  String determineSubject(String content) {
    final subjects = {
      'Math': [
        'equation',
        'algebra',
        'geometry',
        'calculus',
        'mathematics',
        'formula',
        'theorem',
      ],
      'Science': [
        'hypothesis',
        'experiment',
        'molecule',
        'atom',
        'biology',
        'chemistry',
        'physics',
      ],
      'English': [
        'grammar',
        'literature',
        'writing',
        'reading',
        'poetry',
        'novel',
        'essay',
      ],
      'History': [
        'historical',
        'century',
        'war',
        'civilization',
        'ancient',
        'medieval',
        'revolution',
      ],
      'Geography': [
        'continent',
        'country',
        'mountain',
        'river',
        'climate',
        'population',
        'capital',
      ],
    };

    Map<String, int> subjectScores = {};

    for (final entry in subjects.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        score += RegExp(
          keyword,
          caseSensitive: false,
        ).allMatches(content).length;
      }
      subjectScores[entry.key] = score;
    }

    if (subjectScores.values.every((score) => score == 0)) {
      return 'General';
    }

    return subjectScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
