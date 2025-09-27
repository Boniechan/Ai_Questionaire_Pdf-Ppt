import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/performance_provider.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        centerTitle: true,
      ),
      body: Consumer<PerformanceProvider>(
        builder: (context, performanceProvider, child) {
          if (performanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (performanceProvider.performanceAnalytics == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No performance data yet'),
                  SizedBox(height: 8),
                  Text('Complete some quizzes to see your performance'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OverallPerformanceCard(provider: performanceProvider),
                const SizedBox(height: 24),
                _StrengthsWeaknessesSection(provider: performanceProvider),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverallPerformanceCard extends StatelessWidget {
  final PerformanceProvider provider;

  const _OverallPerformanceCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final analytics = provider.performanceAnalytics!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Performance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // First row
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Quizzes',
                      value: '${analytics.totalQuizzes}',
                      icon: Icons.quiz,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Questions Answered',
                      value: '${analytics.totalQuestions}',
                      icon: Icons.question_answer,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Second row
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Correct Answers',
                      value: '${analytics.totalCorrectAnswers}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Overall Score',
                      value: '${analytics.overallPercentage.toInt()}%',
                      icon: Icons.trending_up,
                      color: provider.getPerformanceColor(
                        analytics.overallPercentage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthsWeaknessesSection extends StatelessWidget {
  final PerformanceProvider provider;

  const _StrengthsWeaknessesSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Expert Subjects
        if (provider.expertSubjects.isNotEmpty) ...[
          _SubjectPerformanceCard(
            title: 'Expert Subjects',
            subjects: provider.expertSubjects,
            icon: Icons.star,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
        ],

        // Good and Needs Improvement in responsive layout
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;

            if (isWideScreen &&
                provider.goodSubjects.isNotEmpty &&
                provider.needsImprovementSubjects.isNotEmpty) {
              // Side by side layout for wide screens
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SubjectPerformanceCard(
                        title: 'Good Performance',
                        subjects: provider.goodSubjects,
                        icon: Icons.trending_up,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SubjectPerformanceCard(
                        title: 'Needs Improvement',
                        subjects: provider.needsImprovementSubjects,
                        icon: Icons.trending_down,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Vertical layout for narrow screens or when only one section exists
              return Column(
                children: [
                  if (provider.goodSubjects.isNotEmpty) ...[
                    _SubjectPerformanceCard(
                      title: 'Good Performance',
                      subjects: provider.goodSubjects,
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (provider.needsImprovementSubjects.isNotEmpty)
                    _SubjectPerformanceCard(
                      title: 'Needs Improvement',
                      subjects: provider.needsImprovementSubjects,
                      icon: Icons.trending_down,
                      color: Colors.red,
                    ),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

class _SubjectPerformanceCard extends StatelessWidget {
  final String title;
  final List<SubjectPerformance> subjects;
  final IconData icon;
  final Color color;

  const _SubjectPerformanceCard({
    required this.title,
    required this.subjects,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (subjects.isEmpty) ...[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'No data',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...subjects.map(
                (subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subject.subject,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${subject.percentage.toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: subject.percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
