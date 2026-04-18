# Flutter Integration Guide

After training your model, follow these steps to integrate hand gesture recognition into your Kumpas app.

## 📋 Step-by-Step Integration

### Step 1: Update `pubspec.yaml`

Add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies...
  provider: ^6.1.0
  camera: ^0.10.5
  google_fonts: ^6.1.0
  equatable: ^2.0.5
  
  # NEW: Hand gesture recognition
  tflite_flutter: ^0.10.0
  google_mlkit_hand_pose_detection: ^0.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

Update assets section:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/models/gesture_model.tflite
    - assets/models/sign_mapping.json
```

### Step 2: Copy Model Files to Assets

```bash
# From your Kumpas project root
mkdir -p assets/models

# Copy trained model and mapping
cp ml_training/models/gesture_model.tflite assets/models/
cp ml_training/models/sign_mapping.json assets/models/
```

### Step 3: Update `camera_provider.dart`

Replace your existing `lib/presentation/providers/camera_provider.dart` with the code from `camera_provider_updated.dart`.

Key changes:
- Added `HandPoseDetector` for hand landmark detection
- Added `Interpreter` for TFLite model loading
- Added `_processFrame()` that runs gesture recognition
- Added `_recognizedSign` and `_recognitionConfidence` properties
- Processes 30-frame sequences for robust recognition

### Step 4: Update Your Screens to Display Results

In `lib/presentation/screens/translate_screen.dart` (or relevant screen):

```dart
@override
Widget build(BuildContext context) {
  return Consumer<CameraProvider>(
    builder: (context, cameraProvider, _) {
      return Stack(
        children: [
          // Camera preview
          if (cameraProvider.isInitialized)
            CameraPreview(cameraProvider.cameraController!),
          
          // Display recognized sign
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recognized: ${cameraProvider.recognizedSign}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Confidence: ${(cameraProvider.recognitionConfidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Landmarks visualization
          CustomPaint(
            painter: LandmarksPainter(
              landmarks: cameraProvider.currentLandmarks,
              imageSize: Size(
                cameraProvider.cameraController!.value.previewSize!.width,
                cameraProvider.cameraController!.value.previewSize!.height,
              ),
            ),
            size: Size.infinite,
          ),
        ],
      );
    },
  );
}
```

### Step 5: Test Your Implementation

```bash
cd /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

## 🎨 UI Components

### Display Recognition Status

```dart
// Show recognition indicator
Container(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: _isRecognized ? Colors.green : Colors.grey,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign: ${recognizedSign.isEmpty ? 'None' : recognizedSign}'),
          Text('Confidence: ${(recognitionConfidence * 100).toStringAsFixed(1)}%'),
        ],
      ),
      Icon(
        _isRecognized ? Icons.check_circle : Icons.hourglass_empty,
        color: Colors.white,
      ),
    ],
  ),
)
```

### Real-time Feedback

```dart
// Show real-time feedback in FeedbackBanner
Positioned(
  bottom: 20,
  left: 20,
  right: 20,
  child: AnimatedOpacity(
    opacity: cameraProvider.activeFeedbacks.isNotEmpty ? 1.0 : 0.0,
    duration: Duration(milliseconds: 300),
    child: Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        cameraProvider.activeFeedbacks.isNotEmpty 
          ? cameraProvider.activeFeedbacks.first.message
          : '',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
)
```

## 🔧 Troubleshooting

### TFLite Model Not Found
```
Error: Asset not found: models/gesture_model.tflite
```
**Solution**: 
- Ensure files are in `assets/models/`
- Check `pubspec.yaml` assets section
- Run `flutter clean && flutter pub get`

### Hand Not Detected
**Causes**:
- Poor lighting
- Hand partially out of frame
- Camera permission not granted

**Solution**:
- Ensure good lighting from front
- Show full hand in camera view
- Check camera permissions in Android/iOS settings

### Low Recognition Accuracy
**Solutions**:
1. Record videos in similar lighting as app usage
2. Include more training videos (try 15-20 per sign)
3. Choose signs with distinct hand shapes
4. Increase `SEQUENCE_LENGTH` to 50-100 frames

### TFLite Version Conflicts
```bash
# Update to latest
flutter pub upgrade tflite_flutter

# Or pin version in pubspec.yaml
tflite_flutter: ^0.10.0
```

## 📊 Performance Tips

### Reduce Latency
- Decrease frame processing interval
- Use lighter model (reduce LSTM units)
- Process every 2nd frame instead of every frame

### Reduce Memory Usage
- Use `ResolutionPreset.medium` instead of `high`
- Dispose of unused resources properly
- Clear landmark history periodically

### Improve Accuracy
- Increase model complexity (more LSTM units)
- Use larger `SEQUENCE_LENGTH` (50-100 frames)
- Train on more diverse video backgrounds

## 🚀 Advanced Features

### Add More Signs
1. Edit `1_extract_landmarks.py`:
   ```python
   SELECTED_SIGNS = [3, 4, 15, 20, 29, 31]  # Add more IDs
   SELECTED_SIGN_NAMES = [..., "JANUARY"]
   ```

2. Re-run: `python3 1_extract_landmarks.py && python3 2_train_model.py`

3. Copy new model to assets

### Save Predictions
```dart
// Save recognized sign to database
void _savePrediction(String sign, double confidence) {
  // Your database logic here
}
```

### Add Confidence Threshold
```dart
// Only report high-confidence predictions
const double CONFIDENCE_THRESHOLD = 0.75;

if (confidence > CONFIDENCE_THRESHOLD) {
  _recognizedSign = sign;
}
```

## 📚 References

- [MediaPipe Hand Detection](https://mediapipe.dev/solutions/hands)
- [TensorFlow Lite Flutter](https://pub.dev/packages/tflite_flutter)
- [Google ML Kit Hand Pose](https://pub.dev/packages/google_mlkit_hand_pose_detection)
- [LSTM for Sequences](https://keras.io/api/layers/recurrent_layers/lstm/)

Good luck with your integration! 🎉
