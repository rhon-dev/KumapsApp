import 'package:equatable/equatable.dart';

/// Learning Content Model
class LearningContent extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String videoUrl;
  final String difficulty; // beginner, intermediate, advanced
  final List<String> keywords;
  final int durationSeconds;
  final bool isCompleted;
  final double? progress;

  const LearningContent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    required this.difficulty,
    required this.keywords,
    required this.durationSeconds,
    this.isCompleted = false,
    this.progress,
  });

  LearningContent copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? videoUrl,
    String? difficulty,
    List<String>? keywords,
    int? durationSeconds,
    bool? isCompleted,
    double? progress,
  }) {
    return LearningContent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      difficulty: difficulty ?? this.difficulty,
      keywords: keywords ?? this.keywords,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    videoUrl,
    difficulty,
    keywords,
    durationSeconds,
    isCompleted,
    progress,
  ];
}

/// User Progress Model
class UserProgress extends Equatable {
  final String userId;
  final int totalLessonsCompleted;
  final int currentStreak;
  final int totalXP;
  final Map<String, int> categoryProgress; // category -> completion %
  final List<String> completedLessonIds;

  const UserProgress({
    required this.userId,
    required this.totalLessonsCompleted,
    required this.currentStreak,
    required this.totalXP,
    required this.categoryProgress,
    required this.completedLessonIds,
  });

  @override
  List<Object?> get props => [
    userId,
    totalLessonsCompleted,
    currentStreak,
    totalXP,
    categoryProgress,
    completedLessonIds,
  ];
}

/// AI Feedback Model (for future real-time feedback)
class AIFeedback extends Equatable {
  final String feedbackId;
  final String type; // correction, encouragement, tip
  final String message;
  final double confidence; // 0.0 to 1.0
  final List<String>? affectedJointIds; // for MediaPipe landmarks
  final int? timestamp;

  const AIFeedback({
    required this.feedbackId,
    required this.type,
    required this.message,
    required this.confidence,
    this.affectedJointIds,
    this.timestamp,
  });

  @override
  List<Object?> get props => [
    feedbackId,
    type,
    message,
    confidence,
    affectedJointIds,
    timestamp,
  ];
}

/// Pose Landmark Model (for MediaPipe integration)
class PoseLandmark extends Equatable {
  final String name;
  final double x;
  final double y;
  final double? z;
  final double? visibility;

  const PoseLandmark({
    required this.name,
    required this.x,
    required this.y,
    this.z,
    this.visibility,
  });

  @override
  List<Object?> get props => [name, x, y, z, visibility];
}

/// Camera State Models
enum CameraMode {
  instruction, // viewing reference sign
  practice, // practicing with camera
}

enum PracticeMode {
  freeform,
  guided,
  dictation,
}
