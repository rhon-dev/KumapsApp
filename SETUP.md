# Project Kumpas - Setup & Architecture Guide

## Quick Start

### 1. Prerequisites Check
```bash
flutter --version              # Should be >= 3.10.0
dart --version                 # Should be >= 3.0.0
java -version                  # Should be installed for Android
android --version              # Android SDK >= 21
```

### 2. Project Setup
```bash
# Navigate to project
cd /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp

# Install dependencies
flutter pub get

# Configure for Android
flutter config --android-sdk /path/to/android/sdk

# Run development build
flutter run

# Run release build
flutter build apk --release
```

### 3. First Run Experience
1. App launches with Home screen
2. Bottom navigation shows 5 tabs: Home, Translate, Dictionary, Learn, Profile
3. Tap "Practice" to initialize camera (permission dialog may appear)
4. Camera preview shows with placeholder landmarks

---

## Architecture Overview

### High-Level Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    KUMPAS APP SHELL                         │
│         (MainAppShell with Bottom Navigation)               │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
    ┌────────┐   ┌────────┐   ┌────────┐
    │ HOME   │   │TRANSLATE│   │ LEARN  │ (Camera-Enabled Screens)
    └────────┘   └────────┘   └────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
         ┌────────────▼────────────┐
         │  STATE MANAGEMENT       │
         │  (Provider Pattern)     │
         │                         │
         │ - AppStateProvider      │
         │ - CameraProvider        │
         └────────────┬────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
    ┌────────┐   ┌────────┐   ┌────────────┐
    │ Models │   │Widgets │   │ Platform   │
    │        │   │        │   │  (Camera)  │
    └────────┘   └────────┘   └────────────┘
```

### State Management Tree

```
Provider Multi-Provider Setup:
├── AppStateProvider
│   ├── currentTabIndex (int)
│   ├── cameraMode (instruction | practice)
│   ├── practiceMode (freeform | guided | dictation)
│   ├── userProgress (UserProgress model)
│   └── currentLessons (List<LearningContent>)
│
└── CameraProvider
    ├── cameraController (CameraController?)
    ├── isInitialized (bool)
    ├── isCameraRunning (bool)
    ├── currentLandmarks (List<PoseLandmark>)
    └── activeFeedbacks (List<AIFeedback>)
```

### Screen Navigation Structure

```
MainAppShell (Scaffold with BottomNavigationBar)
│
├── [0] HomeScreen
│   ├── Greeting Card
│   ├── Stats Section (Lessons, Streak, XP)
│   ├── Quick Actions (Practice, Translate)
│   ├── Category Progress
│   └── Continue Learning Card
│
├── [1] TranslateScreen
│   ├── Selection Mode
│   │   ├── Sign→Text Mode Card
│   │   └── Text→Sign Mode Card
│   └── Translate Mode
│       ├── Camera Preview with Feedback Overlay
│       └── Translation Result Display
│
├── [2] DictionaryScreen
│   ├── Search Bar
│   ├── Category Filter
│   └── Dictionary Items List
│
├── [3] LearnScreen
│   ├── Instruction Mode
│   │   ├── Video Placeholder
│   │   ├── Lesson Details
│   │   └── Start Practice Button
│   └── Practice Mode
│       ├── Camera Preview
│       ├── AI Feedback Overlay (CustomPaint + Feedback Banners)
│       └── Bottom Controls (Redo, Pause, Done)
│
└── [4] ProfileScreen
    ├── Profile Header
    ├── Statistics Cards
    ├── Settings Section
    │   ├── Language Selection
    │   ├── Notifications Toggle
    │   └── Dark Mode Toggle
    └── Danger Zone (Clear Data, Sign Out)
```

### Camera Integration Flow

```
┌─────────────────────────────────────────────┐
│  User Taps "Practice" on Home/Learn Screen  │
└────────────────┬────────────────────────────┘
                 │
                 ▼
    ┌────────────────────────┐
    │ AppStateProvider       │
    │ .setCameraMode(        │
    │   CameraMode.practice) │
    └────────────┬───────────┘
                 │
                 ▼
    ┌────────────────────────────────┐
    │ CameraProvider                 │
    │ .initializeCamera(             │
    │   frontCameraDescription)      │
    └────────────┬───────────────────┘
                 │
                 ▼
    ┌────────────────────────────────┐
    │ availableCameras() from camera │
    │ Create CameraController        │
    │ Initialize async               │
    └────────────┬───────────────────┘
                 │
                 ▼
    ┌────────────────────────────────┐
    │ CameraProvider                 │
    │ .startCameraPreview()          │
    └────────────┬───────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────────┐
    │ Image Stream Started                    │
    │ Each Frame → _processFrame()            │
    │  - Update Landmarks (currently random)  │
    │  - Generate Feedback (currently random) │
    │  - notifyListeners()                    │
    └────────────┬───────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────────┐
    │ Listen to CameraProvider in UI          │
    │ Consumer<CameraProvider> rebuilds       │
    │  - Renders LandmarksPainter             │
    │  - Displays FeedbackBanners             │
    └────────────────────────────────────────┘
```

### AI Integration Points

#### Current Placeholders
```dart
CameraProvider._processFrame() {
  // TODO: Integrate MediaPipe
  _updatePlaceholderLandmarks()   // Generate random landmarks
  _generatePlaceholderFeedback()  // Generate random feedback
}
```

#### Future MediaPipe Integration
```
CameraImage from stream
  ↓
MediaPipe Interpreter
  ├─ Input: RGB frame
  ├─ Process: Pose detection model
  └─ Output: 33 pose landmarks + confidence
  ↓
Feature Extraction
  ├─ Normalize landmarks
  ├─ Compute hand positions
  └─ Extract temporal sequences
  ↓
FSL Recognition Model
  ├─ TensorFlow Lite model
  ├─ Compare against trained signs
  └─ Output: Sign label + confidence
  ↓
Feedback Generation
  ├─ Compare user pose vs. reference
  ├─ Identify deviations
  └─ Generate corrective feedback
  ↓
UI Update
  ├─ updateLandmarks() with actual positions
  ├─ addFeedback() with ML-generated feedback
  └─ Refresh CustomPaint & Banners
```

---

## Key Design Decisions

### 1. Provider for State Management
**Why**: Simple, scalable, and widely used in Flutter community
- No boilerplate (vs. BLoC)
- Easy to understand and test
- Built-in performance optimization (partial rebuilds)

### 2. CustomPaint for Landmarks
**Why**: Fine-grained control and high performance
- Direct canvas drawing (no GPU overhead)
- Can render many landmarks efficiently
- Allows complex shapes (skeleton lines, circles)

### 3. Real-Time Frame Processing
**Why**: Non-blocking, responsive UX
- Image streams processed asynchronously
- UI thread never blocked by ML inference
- Landmarks updated on each frame

### 4. Accessibility-First Colors
**Why**: Inclusive design from the start
- High WCAG contrast ratios
- Recognizable by color-blind users
- Meaningful for FSL community (educational green)

---

## Model Relationships

### LearningContent
Represents a single sign language lesson:
```dart
class LearningContent {
  final String title           // "Basic Greetings"
  final String description     // "Learn common greetings"
  final String category        // "Greetings"
  final String difficulty      // "beginner" | "intermediate" | "advanced"
  final List<String> keywords  // ["hello", "goodbye"]
  final bool isCompleted       // User progress tracking
  final double progress        // 0.0 to 1.0 (percentage)
}
```

### UserProgress
Aggregated user statistics:
```dart
class UserProgress {
  final int totalLessonsCompleted  // Gamification metric
  final int currentStreak          // Days of consecutive practice
  final int totalXP                // experience points
  final Map<String, int> categoryProgress  // Per-category %
}
```

### PoseLandmark
MediaPipe pose detection output:
```dart
class PoseLandmark {
  final String name        // "nose", "left_wrist", etc.
  final double x, y        // Normalized coordinates [0, 1]
  final double? z          // Depth (if available)
  final double? visibility // 0.0 to 1.0 confidence
}
```

### AIFeedback
Corrective feedback from ML:
```dart
class AIFeedback {
  final String type              // "correction" | "encouragement" | "tip"
  final String message           // "Raise your right shoulder"
  final double confidence        // 0.0 to 1.0
  final List<String>? affectedJointIds  // Which joints
}
```

---

## File Organization Strategy

```
lib/
├── main.dart                 # Entry point (minimal)
├── theme/
│   └── app_theme.dart        # Centralized styling
├── models/
│   └── learning_models.dart  # All data classes
├── presentation/
│   ├── providers/            # State management
│   ├── screens/              # Page-level widgets
│   └── widgets/              # Reusable components
└── services/                 # (Future) ML services, API calls
```

**Benefits**:
- Predictable file locations
- Easy to scale (add screens, widgets, providers)
- Clear separation of concerns
- Facilitates team collaboration

---

## Performance Targets

### Device Profile: Mid-Range Android (2023)
- RAM: 4-6 GB
- Processor: Mid-tier (Snapdragon 778G equivalent)
- Camera: 1080p @ 30fps

### Target Metrics
- App startup: < 2 seconds
- Camera preview: 30 fps (no jank)
- Landmark rendering: 16ms per frame (~60fps UI)
- Memory usage: < 150 MB during operation
- Storage: ~100 MB APK + ~50 MB assets

---

## Testing Strategy

### Unit Tests (future)
```bash
flutter test test/models/test_learning_models.dart
flutter test test/providers/test_app_state_provider.dart
```

### Widget Tests (future)
```bash
flutter test test/widgets/test_camera_overlay.dart
```

### Integration Tests (future)
```bash
flutter drive --target=test_driver/app.dart
```

### Manual QA Checklist
- [ ] Camera permissions flow
- [ ] Orientation changes smooth
- [ ] No crashes on rapid tab switching
- [ ] Landmarks render continuously
- [ ] Feedback banners auto-dismiss
- [ ] All screens responsive on various screen sizes

---

## Deployment Checklist

### Pre-Release
- [ ] Update version in `pubspec.yaml`
- [ ] Update `versionCode` and `versionName` in `build.gradle`
- [ ] Remove debug prints and verbose logging
- [ ] Test on 3+ real Android devices
- [ ] Verify camera works on each device
- [ ] Check battery usage (no excessive wakelock)

### Build & Release
- [ ] `flutter build appbundle --release`
- [ ] Upload to Google Play Console
- [ ] Configure store listing (keywords, description)
- [ ] Set content rating (educational, no violent content)
- [ ] Configure device targeting (Android 5.1+, mid-range preferred)

### Post-Release Monitoring
- [ ] Monitor crash reports in Play Console
- [ ] Track user feedback
- [ ] Monitor battery drain reports
- [ ] Prepare hotfix if needed

---

## Roadmap

### v1.0 (Current)
✅ Core UI & navigation
✅ Camera integration
✅ AI placeholder system
✅ Gamification basics (XP, streak)

### v1.1 (Next)
- [ ] MediaPipe pose detection
- [ ] TensorFlow Lite FSL recognition
- [ ] Real ML-based feedback
- [ ] Offline mode

### v2.0 (Future)
- [ ] Social features (share achievements)
- [ ] Video recording/playback
- [ ] Community sign uploads
- [ ] Advanced gamification

---

## Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Provider Docs](https://pub.dev/packages/provider)
- [Camera Plugin Docs](https://pub.dev/packages/camera)
- [MediaPipe Docs](https://mediapipe.dev/)
- [FSL Community Resources](https://www.fslcenter.org/)

---

**Project Kumpas - Bridging Communication Through Technology**
