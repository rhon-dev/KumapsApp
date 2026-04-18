# Hand Gesture Recognition Setup Guide

## 🎯 Overview

This guide walks you through adding hand gesture recognition to your Kumpas app using the FSL-105 dataset. We'll:

1. **Extract hand landmarks** from video clips using MediaPipe
2. **Train an LSTM model** on 5 selected signs
3. **Convert to TFLite** for mobile deployment
4. **Integrate into Flutter app**

---

## 📋 Prerequisites

- Python 3.9+
- macOS (your current OS)
- ~5-10 minutes for initial setup
- ~15-20 minutes for training (first time)

---

## 🚀 Quick Start

### Step 1: Install Python Dependencies

```bash
cd /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp/ml_training

# Create virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

**Note:** This will install:
- **mediapipe**: Hand landmark detection
- **tensorflow**: Deep learning framework
- **opencv-python**: Video processing
- **numpy, pandas**: Data manipulation

---

### Step 2: Extract Hand Landmarks from Videos

```bash
python3 1_extract_landmarks.py
```

**What it does:**
- Reads your 5 selected signs from the FSL-105 dataset
- Extracts hand landmarks (21 points per hand) from each video frame
- Saves normalized coordinates (x, y, z) for each landmark
- Outputs: `extracted_landmarks/landmarks_data.json`

**Expected output:**
```
Selected signs: [(3, 'HELLO'), (4, 'HOW ARE YOU'), (15, 'YES'), (20, 'ONE'), (29, 'TEN')]

Processing HELLO (ID: 3) - 20 videos
  Processing 0.MOV... ✓ (45 frames)
  Processing 1.MOV... ✓ (52 frames)
  ...

✅ Landmarks extracted and saved to: extracted_landmarks/landmarks_data.json
Total videos processed: 100
```

---

### Step 3: Train the Model

```bash
python3 2_train_model.py
```

**What it does:**
- Loads extracted landmarks
- Normalizes sequences to fixed length (30 frames)
- Applies data augmentation (3× dataset)
- Trains an LSTM neural network
- Converts to TensorFlow Lite format
- Outputs:
  - `models/gesture_model.tflite` (main model for Flutter)
  - `models/gesture_model.h5` (backup Keras model)
  - `models/sign_mapping.json` (label mappings)

**Expected output:**
```
FSL-105 Gesture Recognition Model Training
============================================================

1. Loading landmarks data...
   Loaded 100 videos

2. Preparing sequences...
   X shape: (100, 30, 63)
   Classes: {'HELLO': 0, 'HOW ARE YOU': 1, 'YES': 2, 'ONE': 3, 'TEN': 4}

3. Applying data augmentation...
   After augmentation: (300, 30, 63)

4. Building model...
Model: "sequential"
...

5. Training...
Epoch 1/50
19/19 [==============================] - 2s 85ms/step - loss: 1.5234 - accuracy: 0.2500
...

6. Evaluating...
   Validation Accuracy: 85.00%
   Validation Loss: 0.4567

✅ Training complete!
```

---

## 🔧 Customize Your Signs

Edit `1_extract_landmarks.py` to choose different signs:

```python
# Line 20-21: Change these IDs and names
SELECTED_SIGNS = [3, 4, 15, 20, 29]  # IDs from labels.csv
SELECTED_SIGN_NAMES = ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"]
```

**Available FSL-105 signs:**
- **GREETING**: GOOD MORNING, GOOD AFTERNOON, HELLO, HOW ARE YOU, etc.
- **SURVIVAL**: UNDERSTAND, KNOW, YES, NO, CORRECT, WRONG, SLOW, FAST
- **NUMBERS**: ONE, TWO, THREE, ..., TEN
- **CALENDAR**: JANUARY - DECEMBER, MONDAY - SUNDAY
- **COLOR, FOOD, DRINK, ANIMALS, RELATIONSHIPS**: 50+ more signs

---

## 📁 Project Structure After Training

```
ml_training/
├── 1_extract_landmarks.py      # Step 1: Extract landmarks
├── 2_train_model.py            # Step 2: Train model
├── requirements.txt            # Python dependencies
├── extracted_landmarks/
│   └── landmarks_data.json     # Extracted hand coordinates
└── models/
    ├── gesture_model.tflite    # ← Use this in Flutter!
    ├── gesture_model.h5
    └── sign_mapping.json
```

---

## 📱 Integrate into Flutter

### Step 1: Add Dependencies to `pubspec.yaml`

```yaml
dependencies:
  tflite_flutter: ^0.10.0
  google_mlkit_hand_pose_detection: ^0.4.0
```

Run:
```bash
cd /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp
flutter pub get
```

### Step 2: Copy Model to Assets

```bash
# Create assets directory
mkdir -p assets/models

# Copy trained model
cp /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp/ml_training/models/gesture_model.tflite \
   /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp/assets/models/

# Copy sign mapping
cp /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp/ml_training/models/sign_mapping.json \
   /Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp/assets/models/
```

Update `pubspec.yaml`:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/models/gesture_model.tflite
    - assets/models/sign_mapping.json
```

### Step 3: Update `camera_provider.dart`

See the provided `camera_provider_updated.dart` file for the complete implementation.

---

## 🎓 Understanding the Model

### Model Architecture (LSTM)
```
Input: Sequence of hand landmarks
  ↓
LSTM Layer 1 (64 units) → Dropout(0.2)
  ↓
LSTM Layer 2 (32 units) → Dropout(0.2)
  ↓
Dense Layer (64 units) → Dropout(0.2)
  ↓
Output Layer (5 units, softmax) → Prediction probabilities
```

### Data Format
- **Input**: 30 frames × 63 features (21 landmarks × 3 coordinates)
- **Output**: 5 probabilities (one per sign)
- **Example**: [0.02, 0.95, 0.01, 0.01, 0.01] → Sign 1 (HOW ARE YOU) with 95% confidence

---

## ⚡ Performance Optimization

### Model Size
- **Before TFLite**: ~2.5 MB
- **After TFLite**: ~500 KB
- **With Quantization**: ~150 KB

### Inference Speed
- **Typical**: 50-100ms per frame on mobile
- **With 30fps camera**: Real-time recognition

---

## 🐛 Troubleshooting

### "No landmarks detected"
- Ensure good lighting
- Hand must be fully visible
- Increase `min_detection_confidence` in MediaPipe

### Low accuracy
- Collect more videos (try 15-20 per sign)
- Ensure consistent video quality
- Try different signs with clearer distinctions

### Python errors
```bash
# Update pip
pip install --upgrade pip

# Reinstall TensorFlow
pip install --force-reinstall tensorflow==2.14.0
```

---

## 📚 Next Steps

1. ✅ Extract landmarks: `python3 1_extract_landmarks.py`
2. ✅ Train model: `python3 2_train_model.py`
3. ✅ Copy to Flutter assets
4. ✅ Update camera_provider.dart
5. ✅ Test in your app!

---

## 📞 Support

For issues:
- Check MediaPipe docs: https://mediapipe.dev
- TensorFlow Lite: https://www.tensorflow.org/lite
- tflite_flutter: https://pub.dev/packages/tflite_flutter

Good luck! 🚀
