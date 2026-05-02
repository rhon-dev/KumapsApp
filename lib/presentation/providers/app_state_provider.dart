import 'package:flutter/material.dart';
import 'package:kumpas/models/learning_models.dart';

/// Main app state provider for navigation and global state
class AppStateProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  CameraMode _cameraMode = CameraMode.instruction;
  PracticeMode _practiceMode = PracticeMode.freeform;

  // Dummy data
  UserProgress? _userProgress;
  List<LearningContent> _currentLessons = [];

  // Getters
  int get currentTabIndex => _currentTabIndex;
  CameraMode get cameraMode => _cameraMode;
  PracticeMode get practiceMode => _practiceMode;
  UserProgress? get userProgress => _userProgress;
  List<LearningContent> get currentLessons => _currentLessons;

  // Navigation Methods
  void selectTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Camera Mode Methods
  void setCameraMode(CameraMode mode) {
    _cameraMode = mode;
    notifyListeners();
  }

  void setPracticeMode(PracticeMode mode) {
    _practiceMode = mode;
    notifyListeners();
  }

  // Initialize dummy data
  void initializeDummyData() {
    _userProgress = const UserProgress(
      userId: 'user_123',
      totalLessonsCompleted: 12,
      currentStreak: 5,
      totalXP: 2450,
      categoryProgress: {
        'Greetings': 85,
        'Numbers': 60,
        'Emotions': 45,
        'Daily Activities': 30,
      },
      completedLessonIds: ['1', '2', '3', '4', '5', '6'],
    );

    _currentLessons = [
      const LearningContent(
        id: '1',
        title: 'Basic Greetings',
        description: 'Learn common FSL greetings and introductions',
        category: 'Greetings',
        videoUrl: 'assets/videos/greetings.mp4',
        difficulty: 'beginner',
        keywords: ['hello', 'goodbye', 'welcome'],
        durationSeconds: 180,
        isCompleted: true,
        progress: 100,
      ),
      const LearningContent(
        id: '2',
        title: 'Numbers 1-10',
        description: 'Master numbers from 1 to 10 in FSL',
        category: 'Numbers',
        videoUrl: 'assets/videos/numbers.mp4',
        difficulty: 'beginner',
        keywords: ['counting', 'numbers', 'digits'],
        durationSeconds: 220,
        isCompleted: false,
        progress: 60,
      ),
    ];

    notifyListeners();
  }
}
