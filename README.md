# Kumpas - Filipino Sign Language Learning App

## Overview

**Kumpas** is a cutting-edge Flutter application designed to enhance Filipino Sign Language (FSL) proficiency through interactive learning, practice, and real-time AI feedback. The app leverages computer vision (MediaPipe) and machine learning to provide accessible, high-performance educational experiences for mid-range Android devices.

### Key Features

- **🎓 Interactive Learning**: Structured lessons from beginner to advanced levels
- **📹 Real-time Practice Mode**: Full-screen camera integration with responsive UI
- **🎯 AI-Powered Feedback**: Placeholder system for MediaPipe pose detection and corrective feedback
- **🔄 Live Translation**: Bidirectional translation (Sign ↔ Text)
- **📚 Comprehensive Dictionary**: Browse and search Filipino signs
- **📊 Progress Tracking**: Statistics, streaks, and XP systems
- **♿ Accessibility-First Design**: High-contrast UI, clear typography, FSL-community-appropriate colors

---

## Architecture

### Project Structure

```
kumpas/
├── lib/
│   ├── main.dart                           # App entry point
│   ├── theme/
│   │   └── app_theme.dart                  # Theme, colors, typography (accessibility)
│   ├── models/
│   │   └── learning_models.dart            # Data models (LearningContent, UserProgress, AIFeedback, PoseLandmark)
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── app_state_provider.dart     # Global app state (navigation, camera mode)
│   │   │   └── camera_provider.dart        # Camera state & AI feedback management
│   │   ├── screens/
│   │   │   ├── main_app_shell.dart         # Bottom navigation shell
│   │   │   ├── home_screen.dart            # Dashboard with stats
│   │   │   ├── learn_screen.dart           # Instruction + Practice modes
│   │   │   ├── translate_screen.dart       # Sign↔Text translation
│   │   │   ├── dictionary_screen.dart      # FSL dictionary
│   │   │   └── profile_screen.dart         # User profile & settings
│   │   └── widgets/
│   │       └── camera_feedback_overlay.dart # AI feedback visualization + landmarks
│   └── services/
│       └── (ML integration point for MediaPipe)
├── android/
│   └── app/
│       ├── build.gradle                    # Android build config
│       └── src/main/
│           └── AndroidManifest.xml         # Android permissions & app config
├── pubspec.yaml                            # Dependencies
└── README.md
```

### State Management

**Provider Pattern** is used for clean, scalable state management:

1. **AppStateProvider**: Manages global state
   - Tab navigation
   - Camera mode (instruction vs. practice)
   - Practice mode (freeform, guided, dictation)
   - Learning content & user progress

2. **CameraProvider**: Manages camera lifecycle
   - Camera initialization and preview
   - Frame processing (placeholder for MediaPipe)
   - Landmark updates
   - AI feedback generation

### UI Responsiveness

- **Responsive Sizing Utilities** in `app_theme.dart`
  - Mobile: < 600dp
  - Tablet: 600-900dp
  - Desktop: ≥ 900dp
- High DPI support for text and UI elements
- Safe area considerations for notched devices

---

## Setup Instructions

### Prerequisites

- Flutter >= 3.10.0
- Dart >= 3.0.0
- Android SDK 21+ (for camera support)
- XCode 14+ (optional, for iOS)

### Installation

1. **Clone and Navigate**
   ```bash
   cd /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Local Properties**
   ```bash
   flutter config --android-sdk /path/to/android/sdk
   ```

4. **Build for Android**
   ```bash
   flutter build apk --release
   ```
   Or for debug:
   ```bash
   flutter run
   ```

5. **Camera Permissions**
   - Android automatically handles camera permissions at runtime
   - First-time users will see permission dialog

---

## Technology Stack

### Flutter & Dart
- **Framework**: Flutter 3.10+
- **State Management**: Provider 6.1.0
- **Navigation**: Bottom Tab Navigation

### Camera & Media
- **camera**: 0.10.5 (native camera access)
- **image**: 4.0.0 (image processing)

### UI & Theming
- **flutter_svg**: 2.0.0 (vector graphics)
- **google_fonts**: 6.1.0 (typography)

### Data & Storage
- **shared_preferences**: 2.2.0 (local settings)
- **hive**: 2.2.3 (local database, prepared for future use)

### Future Integrations
- **MediaPipe**: Pose detection & landmark extraction
- **TensorFlow Lite**: On-device ML model inference
- **Firebase**: Cloud sync & authentication

---

## Key Features Deep Dive

### 1. Learn Screen (Practice Mode)

The Learn screen operates in two modes:

#### Instruction Mode
- Display reference video of the sign
- Show description, keywords, difficulty level
- Button to transition to practice

#### Practice Mode
- Full-screen camera preview (optimized for mid-range devices)
- **MediaPipe Overlay** (placeholder):
  - Draws pose landmarks as circles with visibility indicators
  - Connects joints with skeleton lines
  - Color-coded confidence visualization
- **AI Feedback System** (placeholder):
  - Real-time corrective feedback banners
  - Confidence scoring
  - Auto-dismissal after 3 seconds
- **Bottom Controls**:
  - Redo button
  - Pause button
  - Done button (completion dialog)
- **Frame Rate Optimization**:
  - Camera streams at native device refreshrate (typically 30fps)
  - Landmarks processed asynchronously
  - No UI blocking

### 2. Translate Screen

Bidirectional translation with real-time camera:

- **Mode Selection**:
  - Sign to Text: Camera analyzes user's signs and converts to text
  - Text to Sign: User types text, app shows corresponding sign video
- **Live Translation Overlay**:
  - Detected text displayed in bottom panel
  - Real-time MediaPipe overlay
  - Confidence metrics
- **Quick Phrases**: Common expressions for fast translation

### 3. Camera Feedback Overlay

Custom CustomPaint widget for visualization:

```dart
// Landmark Drawing
- Circle at each joint (joint.visibility * opacity)
- White border for contrast (high accessibility)
- Skeleton connections between related joints

// Feedback Display
- Color-coded messages (correction=warning, encouragement=success)
- Animated entrance (ScaleTransition)
- Confidence percentage
- Auto-dismiss after 3 seconds
```

### 4. Home Dashboard

Comprehensive progress overview:

- **Stats Card**: Lessons completed, current streak, total XP
- **Quick Actions**: Practice & Translate buttons
- **Category Progress**: Visual progress bars for each topic
- **Continue Learning**: Resume incomplete lessons

---

## AI Integration Points (Ready for MediaPipe)

### CameraProvider._processFrame()

```dart
void _processFrame(CameraImage image) {
  // TODO: Integrate MediaPipe here
  // 1. Run pose detection on frame
  // 2. Extract 33 pose landmarks (MediaPipe POSE model)
  // 3. Compare with reference sign
  // 4. Generate feedback based on comparison
  // 5. Call updateLandmarks() with detected landmarks
  // 6. Call addFeedback() with corrective feedback
}
```

### Future ML Pipeline

1. **Input**: Camera frame (CameraImage)
2. **Pose Detection**: MediaPipe extracts 33 pose landmarks
3. **Feature Extraction**: Convert landmarks to feature vector
4. **Sign Recognition**: Compare against trained FSL sign models
5. **Feedback Generation**: Identify deviations and suggest corrections
6. **Output**: Update UI with landmarks + feedback

---

## Styling & Accessibility

### Color Palette (Accessibility-Focused)

```dart
Primary: #1ABC9C      // Vibrant teal (growth, education)
Secondary: #E67E22    // Warm orange (encouragement)
Success: #2ECC71      // Clear green (validation)
Error: #E74C3C        // High-contrast red (alerts)
Warning: #F39C12      // Amber (caution)
Text Primary: #2C3E50 // High contrast dark text
```

### Typography

- **Display/Headline**: Inter Bold (headings)
- **Body**: Roboto Regular (readable content)
- **Labels**: Inter Medium (buttons, chips)
- **All text sized for readability**: Minimum 12sp, scalable

### UI Patterns

- **High Contrast**: Dark text on light backgrounds
- **Clear Spacing**: 8dp grid system for rhythm
- **Large Touch Targets**: Minimum 48x48dp tap areas
- **Visual Feedback**: Buttons have active/hover states
- **Loading States**: CircularProgressIndicator for async operations

---

## Performance Optimizations

### Camera Preview

1. **Resolution Management**:
   - Uses `ResolutionPreset.high` balanced with performance
   - Scale transformation optimizes aspect ratio fit
   - Prevents stretching/distortion

2. **Frame Rate**:
   - Native device refresh rate (~30fps for mid-range)
   - Image stream processed asynchronously (no UI blocking)
   - Optional frame skipping for low-end devices (future work)

3. **Memory Management**:
   - Camera controller disposed on screen leave
   - Lifecycle management prevents memory leaks
   - Image stream stopped during app pause

### UI Rendering

- **CustomPaint**: Efficient landmark drawing
- **IgnorePointer**: Overlay doesn't consume touch events
- **RepaintBoundary**: (future) Optimize CustomPaint redraws
- **ListView**: Used for large lists (dictionary, lessons)

---

## Testing & Validation

### Manual Testing Checklist

- [ ] Camera initializes on Learn/Translate screen
- [ ] Landmarks render correctly with skeleton
- [ ] Feedback messages appear and dismiss
- [ ] No UI lag during camera preview
- [ ] Orientation changes handled smoothly
- [ ] App pause/resume lifecycle respected
- [ ] All screens navigate correctly
- [ ] Settings persist

### Future Automated Tests

```bash
flutter test                           # Unit tests
flutter drive                          # Integration tests
flutter test integration_test/         # E2E tests
```

---

## Future Enhancements

### Phase 2: AI Integration
- [ ] Integrate MediaPipe for actual pose detection
- [ ] Train FSL recognition model (TensorFlow Lite)
- [ ] Real-time corrective feedback based on models
- [ ] Performance profiling on target devices

### Phase 3: Community & Gamification
- [ ] Leaderboards
- [ ] Social sharing of achievements
- [ ] Challenge friends
- [ ] Community-contributed signs

### Phase 4: Advanced Features
- [ ] Offline mode (cache lessons)
- [ ] Video recording & playback of user signs
- [ ] AI-generated practice scenarios
- [ ] Multi-user accounts on device
- [ ] Cloud sync with authentication

---

## Deployment

### Build Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Install on Device

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Play Store Preparation

1. Create app bundle:
   ```bash
   flutter build appbundle --release
   ```

2. Upload to Google Play Console
3. Configure store listing with FSL-focused description
4. Set target audience & content rating

---

## Troubleshooting

### Camera not initializing
- Ensure device has front-facing camera
- Check `AndroidManifest.xml` includes camera permissions
- Test on device with `flutter run --verbose`

### Frame drops/UI lag
- Close background apps
- Test on actual device (not emulator for better performance)
- Check CPU/memory profiling in Flutter DevTools

### Permissions denied
- App requests camera permission on first use
- User can revoke in Settings > Apps > Kumpas > Permissions

---

## License

Project Kumpas - Educational Technology for Filipino Sign Language
© 2024. All rights reserved.

---

## Contact & Support

For issues, feature requests, or feedback:
- Open GitHub issues on project repository
- Contact the development team

---

**Made with ❤️ for the FSL Community**
