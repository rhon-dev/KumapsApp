# Flask API to Flutter Integration Guide

## Overview
Your hand gesture recognition system is now complete with:
- ✅ **Model**: Random Forest classifier trained on 101 FSL-105 videos
- ✅ **Backend**: Flask REST API running on port 5001
- ✅ **5 Trained Gestures**: HELLO, HOW ARE YOU, YES, ONE, TEN

## Current Status

### Flask Server
- **URL**: `http://localhost:5001`
- **Port**: 5001 (not 5000, due to macOS AirPlay)
- **Status**: ✅ Running and responding to requests

### API Endpoints

#### 1. Health Check
```bash
curl http://localhost:5001/health
```
**Response**:
```json
{
  "status": "ok",
  "model": "gesture_recognition",
  "signs": ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"],
  "timestamp": "2026-04-18T17:17:58.584746"
}
```

#### 2. Model Info
```bash
curl http://localhost:5001/info
```
**Response**:
```json
{
  "model_type": "Random Forest",
  "framework": "scikit-learn",
  "num_signs": 5,
  "signs": ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"],
  "sequence_length": 30,
  "features_per_frame": 63,
  "total_features": 1890
}
```

#### 3. Make Prediction
```bash
curl -X POST http://localhost:5001/predict \
  -H "Content-Type: application/json" \
  -d '{"landmarks": [... 1890 float values ...]}'
```

**Request**: JSON with `landmarks` array (1,890 floats)
- 30 frames × 63 features per frame
- Each feature is a hand motion metric (distance, angle, contour info, etc.)

**Response**:
```json
{
  "sign": "HOW ARE YOU",
  "label": 1,
  "confidence": 0.39,
  "probabilities": {
    "HELLO": 0.1942,
    "HOW ARE YOU": 0.39,
    "YES": 0.1319,
    "ONE": 0.08,
    "TEN": 0.204
  },
  "warning": "Low confidence: 39.00% < 70%"
}
```

## Flutter Integration

### Step 1: Add HTTP Dependency
In `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
```

Run: `flutter pub get`

### Step 2: Use GestureService

The service file is already created at [lib/services/gesture_service.dart](../../lib/services/gesture_service.dart).

#### Check API Health
```dart
final service = GestureService(apiUrl: 'http://localhost:5001');
bool isReady = await service.isHealthy();
```

#### Get Model Info
```dart
final info = await service.getInfo();
print('Available signs: ${info['signs']}');
print('Confidence threshold: ${info['model_type']}');
```

#### Make Prediction
```dart
List<double> landmarks = [...]; // 1,890 features from camera
PredictionResult result = await service.predict(landmarks);

print('Predicted sign: ${result.sign}');
print('Confidence: ${result.confidence}');
print('Is confident: ${result.isHighConfidence}');
```

### Step 3: Update Camera Provider
Modify [lib/presentation/providers/camera_provider.dart](../../lib/presentation/providers/camera_provider.dart):

```dart
import 'package:kumpas/services/gesture_service.dart';

class CameraProvider extends StateNotifier<CameraState> {
  final GestureService gestureService;
  
  CameraProvider({GestureService? service})
      : gestureService = service ?? GestureService(apiUrl: 'http://localhost:5001'),
        super(CameraState.initial());

  Future<void> processFrame(List<double> landmarks) async {
    try {
      // Send landmarks to Flask API
      final result = await gestureService.predict(landmarks);
      
      // Update UI with prediction
      state = state.copyWith(
        recognizedSign: result.sign,
        confidence: result.confidence,
        allProbabilities: result.probabilities,
        isHighConfidence: result.isHighConfidence,
      );
    } catch (e) {
      print('Prediction error: $e');
      // Show error to user
    }
  }
}
```

### Step 4: Extract Landmarks in Camera
When capturing frames:

1. **Detect hand** using OpenCV or MediaPipe (already done in Python)
2. **Extract landmarks** (same logic from 1_extract_landmarks.py)
3. **Pad to 30 frames** with zeros if fewer frames
4. **Flatten to 1,890 values** (30 × 63)
5. **Send to Flask API**

Example pseudocode:
```dart
// In camera frame processing
List<double> landmarks = extractHandLandmarks(cameraFrame);
if (landmarks.length >= 1890) {
  await processFrame(landmarks);
}
```

## Network Configuration

### For Local Development (on same machine)
Use: `http://localhost:5001`

### For Device Testing (Flutter app on another device)
Replace `localhost` with your machine's IP:
```dart
GestureService(apiUrl: 'http://192.168.1.100:5001')
```

Find your IP:
```bash
# macOS
ifconfig | grep inet
```

## Debugging

### Test Flask Locally
```bash
# Keep Flask running
cd ml_training && source venv/bin/activate && python3 flask_api.py
```

### Test from Another Terminal
```bash
# Health check
curl http://localhost:5001/health

# Get info
curl http://localhost:5001/info

# Test prediction with Python
python3 << 'EOF'
import json
import numpy as np
import urllib.request

test_data = np.random.randn(1890).tolist()
payload = json.dumps({'landmarks': test_data})

req = urllib.request.Request(
    'http://localhost:5001/predict',
    data=payload.encode('utf-8'),
    headers={'Content-Type': 'application/json'}
)

with urllib.request.urlopen(req) as response:
    result = json.loads(response.read().decode())
    print(json.dumps(result, indent=2))
EOF
```

### Common Issues

**Issue**: "Connection refused" or "localhost refused to connect"
- **Solution**: Ensure Flask server is running (`python3 flask_api.py`)
- **Check**: `curl http://localhost:5001/health`

**Issue**: Low prediction confidence
- **Why**: Random data doesn't match training distribution
- **Solution**: Use real hand landmark data from camera

**Issue**: Port 5000 already in use
- **Why**: macOS AirPlay Receiver uses port 5000
- **Solution**: Already fixed - using port 5001

## Next Steps

1. **Integrate with camera provider** - Add HTTP calls in camera frame processing
2. **Extract real landmarks** - Use OpenCV (already in Python pipeline) to extract features from camera frames
3. **Display results** - Show predicted sign and confidence in UI
4. **Performance testing** - Measure latency and optimize
5. **Production deployment** - Deploy Flask to cloud or edge device

## File Structure
```
KumapsApp/
├── ml_training/
│   ├── venv/                        # Python virtual environment
│   ├── flask_api.py                 # Flask server (RUNNING)
│   ├── models/
│   │   ├── gesture_model.pkl        # Trained model
│   │   └── sign_mapping.json        # Sign labels
│   ├── requirements.txt             # Python dependencies
│   └── ...
├── lib/
│   ├── services/
│   │   └── gesture_service.dart     # Flutter service (NEW)
│   ├── presentation/
│   │   └── providers/
│   │       └── camera_provider.dart # To be updated
│   └── ...
└── pubspec.yaml                     # Add 'http' dependency
```

## Testing Checklist

- [ ] Flask server running on port 5001
- [ ] `/health` endpoint returns 200 OK
- [ ] `/info` endpoint shows 5 signs
- [ ] `/predict` endpoint accepts 1,890 features and returns prediction
- [ ] Add `http` package to pubspec.yaml
- [ ] GestureService imports correctly in Flutter
- [ ] Test health check from Flutter
- [ ] Integrate predict calls in camera provider
- [ ] Display results in UI
- [ ] Test with real camera frames

## API Response Reference

### Success (200 OK)
```json
{
  "sign": "HELLO",
  "label": 0,
  "confidence": 0.95,
  "probabilities": {
    "HELLO": 0.95,
    "HOW ARE YOU": 0.02,
    "YES": 0.01,
    "ONE": 0.01,
    "TEN": 0.01
  }
}
```

### Low Confidence
```json
{
  "sign": "YES",
  "label": 2,
  "confidence": 0.45,
  "probabilities": {...},
  "warning": "Low confidence: 45.00% < 70%"
}
```

### Error (400 Bad Request)
```json
{
  "error": "Invalid landmarks length. Expected 1890, got 100"
}
```

---

**Status**: ✅ Complete and ready for Flutter integration!
