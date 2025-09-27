enum AchievementType { badge, medal, ribbon }

enum AchievementCategory { progress, consistency, milestone, subject }

class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final AchievementCategory category;
  final String iconPath;
  final String subject; // For subject-specific achievements
  final Map<String, dynamic> criteria; // Flexible criteria for unlocking
  final DateTime? unlockedAt;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.iconPath,
    this.subject = '',
    this.criteria = const {},
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'category': category.index,
      'iconPath': iconPath,
      'subject': subject,
      'criteria': criteria,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
      'isUnlocked': isUnlocked,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: AchievementType.values[json['type']],
      category: AchievementCategory.values[json['category']],
      iconPath: json['iconPath'],
      subject: json['subject'] ?? '',
      criteria: Map<String, dynamic>.from(json['criteria'] ?? {}),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['unlockedAt'])
          : null,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    AchievementType? type,
    AchievementCategory? category,
    String? iconPath,
    String? subject,
    Map<String, dynamic>? criteria,
    bool? isUnlocked,
    DateTime? unlockedAt, // Changed from unlockedDate to unlockedAt
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category, // Added missing category
      iconPath: iconPath ?? this.iconPath,
      subject: subject ?? this.subject, // Added missing subject
      criteria: criteria ?? this.criteria, // Added missing criteria
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt, // Changed parameter name
    );
  }
}

class UserAchievement {
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final Map<String, dynamic> progress; // Track progress towards achievement

  UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.progress = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
      'progress': progress,
    };
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      userId: json['userId'],
      achievementId: json['achievementId'],
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(json['unlockedAt']),
      progress: Map<String, dynamic>.from(json['progress'] ?? {}),
    );
  }
}
