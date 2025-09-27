import 'package:ai_questionaire/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/models.dart';
import '../providers/quiz_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/performance_provider.dart';
import '../services/database_service_firebase.dart';
import 'pdf_upload_screen.dart';
import 'quiz_list_screen.dart';
import 'achievements_screen.dart';
import 'performance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final DatabaseService _databaseService = DatabaseService();

  final List<Widget> _screens = [
    const DashboardTab(),
    const QuizListScreen(),
    const AchievementsScreen(),
    const PerformanceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() async {
      try {
        // Get current user ID
        final userId = _databaseService.currentUserId;

        // Load data with proper error handling
        await context.read<QuizProvider>().loadQuizzes();
        await context.read<AchievementProvider>().loadAchievements(userId);
        await context.read<PerformanceProvider>().loadPerformanceAnalytics(
          userId,
        );
      } catch (e) {
        debugPrint('Error loading home screen data: $e');
        // Show error snackbar if mounted
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load data: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  // Helper method to get user initial safely
  String _getUserInitial() {
    final displayName = AuthService.displayName;
    if (displayName.isEmpty) {
      return AuthService.isAnonymous ? 'G' : 'U'; // G for Guest, U for User
    }
    return displayName[0].toUpperCase();
  }

  // Helper method to get display name safely
  String _getDisplayName() {
    final displayName = AuthService.displayName;
    if (displayName.isEmpty) {
      return AuthService.isAnonymous ? 'Guest User' : 'User';
    }
    return displayName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Questionnaire'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  _showUserProfile();
                  break;
                case 'signout':
                  await _signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(_getDisplayName()),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  _getUserInitial(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quizzes'),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.trophy),
            label: 'Achievements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Performance',
          ),
        ],
      ),
    );
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_getDisplayName()}'),
            const SizedBox(height: 8),
            Text(
              'Email: ${AuthService.isAnonymous ? 'Guest User' : AuthService.userEmail}',
            ),
            const SizedBox(height: 8),
            Text(
              'Account Type: ${AuthService.isAnonymous ? 'Guest' : 'Registered'}',
            ),
            if (AuthService.isAnonymous) ...[
              const SizedBox(height: 16),
              const Text(
                'Create an account to save your progress permanently!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (AuthService.isAnonymous)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreateAccountDialog();
              },
              child: const Text('Create Account'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateAccountDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Convert your guest account to a permanent account:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await AuthService.linkAnonymousAccount(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    displayName: nameController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account created successfully!'),
                      ),
                    );
                    setState(() {}); // Refresh the UI to show updated user info
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await AuthService.signOut();
      // Navigation will be handled automatically by AuthWrapper
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to AI Questionnaire',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload PDFs and let AI generate personalized questions for you!',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DocumentUploadScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Document & Create Quiz'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Stats
          Text(
            'Quick Stats',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stats Cards with error handling
          Consumer3<QuizProvider, AchievementProvider, PerformanceProvider>(
            builder:
                (
                  context,
                  quizProvider,
                  achievementProvider,
                  performanceProvider,
                  child,
                ) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.quiz,
                              title: 'Total Quizzes',
                              value: '${quizProvider.quizzes.length}',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              icon: FontAwesomeIcons.trophy,
                              title: 'Achievements',
                              value:
                                  '${achievementProvider.achievements.where((a) => a.isUnlocked).length}',
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.trending_up,
                              title: 'Overall Score',
                              value:
                                  '${performanceProvider.overallPercentage.toInt()}%',
                              color: performanceProvider.getPerformanceColor(
                                performanceProvider.overallPercentage,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.schedule,
                              title: 'Total Quizzes',
                              value:
                                  '${performanceProvider.performanceAnalytics?.totalQuizzes ?? 0}',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
          ),

          const SizedBox(height: 24),

          // Recent Achievements
          Consumer<AchievementProvider>(
            builder: (context, achievementProvider, child) {
              if (achievementProvider.recentlyUnlocked.isEmpty) {
                return const SizedBox();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Achievements',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...achievementProvider.recentlyUnlocked
                      .take(3)
                      .map(
                        (achievement) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Icon(
                                _getAchievementIcon(achievement.type),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(achievement.name),
                            subtitle: Text(achievement.description),
                            trailing: Text(
                              'Just now',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ],
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
