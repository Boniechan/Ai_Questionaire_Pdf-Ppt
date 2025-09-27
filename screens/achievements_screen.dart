import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/models.dart';
import '../providers/achievement_provider.dart';
import '../services/database_service_firebase.dart';
import '../services/firebase_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements'), centerTitle: true),
      body: Consumer<AchievementProvider>(
        builder: (context, achievementProvider, child) {
          if (achievementProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (achievementProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading achievements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievementProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Fix: Get current user ID properly
                      final user = await FirebaseService.getCurrentUser();
                      if (user != null) {
                        await achievementProvider.loadAchievements(user.uid);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Stats Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        context,
                        'Badges',
                        achievementProvider.getUnlockedCount(
                          AchievementType.badge,
                        ),
                        achievementProvider.getTotalCount(
                          AchievementType.badge,
                        ),
                        Colors.blue,
                      ),
                      _buildStatItem(
                        context,
                        'Medals',
                        achievementProvider.getUnlockedCount(
                          AchievementType.medal,
                        ),
                        achievementProvider.getTotalCount(
                          AchievementType.medal,
                        ),
                        Colors.amber,
                      ),
                      _buildStatItem(
                        context,
                        'Ribbons',
                        achievementProvider.getUnlockedCount(
                          AchievementType.ribbon,
                        ),
                        achievementProvider.getTotalCount(
                          AchievementType.ribbon,
                        ),
                        Colors.purple,
                      ),
                    ],
                  ),
                ),

                const TabBar(
                  tabs: [
                    Tab(text: 'Badges', icon: FaIcon(FontAwesomeIcons.award)),
                    Tab(text: 'Medals', icon: FaIcon(FontAwesomeIcons.medal)),
                    Tab(text: 'Ribbons', icon: FaIcon(FontAwesomeIcons.ribbon)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AchievementGrid(
                        achievements: achievementProvider.badges,
                        achievementProvider: achievementProvider,
                      ),
                      _AchievementGrid(
                        achievements: achievementProvider.medals,
                        achievementProvider: achievementProvider,
                      ),
                      _AchievementGrid(
                        achievements: achievementProvider.ribbons,
                        achievementProvider: achievementProvider,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int unlocked,
    int total,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          '$unlocked/$total',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// Rest of the classes stay exactly the same...
class _AchievementGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final AchievementProvider achievementProvider;

  const _AchievementGrid({
    required this.achievements,
    required this.achievementProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No achievements yet'),
            SizedBox(height: 8),
            Text(
              'Keep taking quizzes to unlock achievements!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _AchievementCard(
          achievement: achievement,
          progress: achievementProvider.getProgressForAchievement(
            achievement.id,
          ),
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final double progress;

  const _AchievementCard({required this.achievement, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: achievement.isUnlocked ? 8 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Achievement Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? _getAchievementColor(achievement.type).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAchievementIcon(achievement.type),
                size: 40,
                color: achievement.isUnlocked
                    ? _getAchievementColor(achievement.type)
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            // Achievement Name
            Text(
              achievement.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: achievement.isUnlocked ? null : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Achievement Description
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: achievement.isUnlocked ? Colors.grey[600] : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Progress or Unlock Status
            if (achievement.isUnlocked) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getAchievementColor(achievement.type),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Unlocked',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Progress Bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getAchievementColor(achievement.type),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getAchievementColor(achievement.type),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.badge:
        return FontAwesomeIcons.award;
      case AchievementType.medal:
        return FontAwesomeIcons.medal;
      case AchievementType.ribbon:
        return FontAwesomeIcons.ribbon;
    }
  }

  Color _getAchievementColor(AchievementType type) {
    switch (type) {
      case AchievementType.badge:
        return Colors.blue;
      case AchievementType.medal:
        return Colors.amber;
      case AchievementType.ribbon:
        return Colors.purple;
    }
  }
}
