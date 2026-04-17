# Build Configuration & Development Guide

## Environment Setup

### Required Environment Variables

```bash
# Android SDK
export ANDROID_SDK_ROOT=/path/to/android-sdk
export ANDROID_HOME=$ANDROID_SDK_ROOT
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools

# Flutter (if not in system PATH)
export FLUTTER_ROOT=/path/to/flutter
export PATH=$PATH:$FLUTTER_ROOT/bin
```

### Gradle Configuration

**File**: `android/gradle.properties`

```properties
# Project-wide Gradle settings
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true

# Camera plugin optimization
camerax_version=1.2.3

# Kotlin
kotlin.code.style=official
```

### Local.properties for Android

**File**: `android/local.properties`

```properties
sdk.dir=/path/to/android-sdk
flutter.sdk=/path/to/flutter
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
```

---

## Development Commands

### Install & Run

```bash
# Get dependencies
flutter pub get

# Clean build (if issues)
flutter clean

# Run on connected device
flutter run

# Run with debugging
flutter run -v

# Run in release mode
flutter run --release

# Run on specific device
flutter devices                          # List devices
flutter run -d <device-id>
```

### Build Outputs

```bash
# Build APK (debug)
flutter build apk

# Build APK (release, optimized)
flutter build apk --release

# Build AAB (Android App Bundle for Play Store)
flutter build appbundle --release

# Build unsigned APK
flutter build apk --release --no-shrink

# Output locations
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

---

## Code Quality

### Dart Analysis

```bash
# Check code quality
flutter analyze

# Fix issues automatically
dart fix --apply

# Format code
dart format lib/

# Get covered with tests
flutter test --coverage
```

### Performance Profiling

```bash
# Open DevTools
flutter pub global activate devtools
devtools

# Run app and profile
flutter run --profile

# In DevTools:
# - CPU Profiler (find slow code)
# - Memory Profiler (detect leaks)
# - Network tab (API calls)
# - Frame rendering (jank detection)
```

---

## Debugging

### Debug Mode Features

```bash
# Run with verbose output
flutter run -v

# Enable all debug prints
flutter run --verbose

# Hot reload (experimental changes)
flutter run          # Then press 'r' in console

# Full restart
# Press 'R' in console during flutter run

# Detach
# Press 'q' in console
```

### Common Issues & Solutions

#### Issue: "camera not initializing"
```bash
# Check device has camera
flutter devices

# Review manifest permissions
cat android/app/src/main/AndroidManifest.xml | grep camera

# Grant permissions manually
adb shell pm grant com.kumaps.app android.permission.CAMERA
```

#### Issue: "Gradle build fails"
```bash
# Clean and retry
flutter clean
flutter pub get
./gradlew clean  # In android/

# Check Java version (should be 11+)
java -version

# Update Gradle wrapper
cd android/
wrapper/gradle/gradle-wrapper.properties
```

#### Issue: "Frame drops in preview"
```bash
# Profile real device
flutter run --profile

# Check frame rendering in DevTools
# ProfileCompleted messages > 16ms indicates jank

# Solutions:
# 1. Reduce landmark drawing complexity
# 2. Increase image stream frame skip
# 3. Use larger resolution preset
```

---

## Continuous Integration

### GitHub Actions (Recommended Template)

**File**: `.github/workflows/build.yml`

```yaml
name: Build & Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Analyze
        run: flutter analyze lib/
      
      - name: Run tests
        run: flutter test
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: app-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

## Version Management

### Update Version Numbers

**In `pubspec.yaml`**:
```yaml
version: 1.0.0+1
# Format: major.minor.patch+build
```

**In `android/app/build.gradle`**:
```gradle
versionCode 1        # Incremented for every release
versionName "1.0.0"  # Visible to users
```

### Semantic Versioning

- **Major**: Breaking changes (1.0 → 2.0)
- **Minor**: New features (1.0 → 1.1)
- **Patch**: Bug fixes (1.0 → 1.0.1)

### Release Checklist

- [ ] Update version numbers
- [ ] Update CHANGELOG.md
- [ ] Test on real device
- [ ] Build release APK/AAB
- [ ] Tag commit with version (`git tag v1.0.0`)
- [ ] Push to GitHub

---

## Performance Optimization Tips

### Camera Preview

```dart
// Recommended Settings
PresetResolution = ResolutionPreset.high  // ~1080p
ImageFormat = ImageFormatGroup.nv21       // Efficient
EnableAudio = false                       // No music needed
Max frame rate = 30fps                    // Balance quality/performance
```

### UI Rendering

```dart
// Use RepaintBoundary for expensive paints
RepaintBoundary(
  child: CustomPaint(
    painter: LandmarksPainter(...),
  ),
)

// Use const constructors
const SizedBox(height: 16)

// Avoid rebuilding expensive widgets
Consumer<CameraProvider>(
  builder: (context, provider, child) {
    return Stack(
      children: [
        child,      // Doesn't rebuild
        CustomPaint(...), // Only this rebuilds
      ],
    );
  },
  child: CameraPreview(controller),  // Passed as child
)
```

### Memory Management

```dart
// Dispose resources
@override
void dispose() {
  _cameraController?.dispose();
  _lifecycleListener?.cancel();
  super.dispose();
}

// Use weak references for callbacks
WeakReference<MyState>(this)
```

---

## Documentation

### Code Comments

```dart
/// Single line description
/// 
/// Longer description if needed.
/// 
/// Example:
/// ```dart
/// final feedback = AIFeedback(...)
/// ```
class AIFeedback {
  /// Creates feedback instance
  /// 
  /// [type] must be one of: correction, encouragement, tip
  const AIFeedback({
    required this.type,
    // ...
  });
}
```

### Commit Messages

```
<type>(<scope>): <subject>

<body>

Fixes #<issue-number>

Type: feat, fix, docs, style, refactor, test, chore
Scope: camera, ui, state-management, etc.
Subject: Imperative, present tense, lowercase
```

---

## Troubleshooting Checklist

| Problem | Solution |
|---------|----------|
| Build fails | Run `flutter clean && flutter pub get` |
| Camera not working | Check AndroidManifest.xml permissions |
| UI lag | Profile with DevTools, reduce landmark draw calls |
| Memory leak | Use DevTools Memory tab, check dispose() |
| Tests failing | Run `flutter test -v` for details |
| Crashes at startup | Check Flutter version compatibility |

---

## Resources & Documentation

- [Flutter Official Docs](https://flutter.dev/docs) - Complete API reference
- [Camera Plugin Guide](https://pub.dev/packages/camera) - Camera integration
- [Provider State Management](https://pub.dev/packages/provider) - State management
- [MediaPipe](https://mediapipe.dev/) - ML pose detection
- [Android Camera API](https://developer.android.com/reference/android/hardware/camera) - Lower level details

---

**Last Updated**: 2024
