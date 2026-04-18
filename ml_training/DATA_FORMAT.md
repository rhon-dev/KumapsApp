# Data Format Reference

## 📊 Extracted Landmarks JSON Format

After running `1_extract_landmarks.py`, the file `extracted_landmarks/landmarks_data.json` contains:

```json
[
  {
    "sign_id": 3,
    "sign_name": "HELLO",
    "video_file": "0.MOV",
    "num_frames": 45,
    "landmarks": [
      [0.5, 0.3, 0.1, 0.48, 0.32, 0.12, ...],  // Frame 1: 63 values (21 landmarks × 3)
      [0.51, 0.31, 0.11, 0.49, 0.33, 0.13, ...], // Frame 2
      ...
      [0.52, 0.29, 0.09, 0.50, 0.31, 0.11, ...]  // Frame 45
    ]
  },
  {
    "sign_id": 3,
    "sign_name": "HELLO",
    "video_file": "1.MOV",
    "num_frames": 52,
    "landmarks": [ ... ]
  },
  ...
]
```

## 🎯 Key Metrics

### Landmark Coordinates
Each coordinate is **normalized to 0-1 range**:
- `x`: Horizontal position (0 = left edge, 1 = right edge)
- `y`: Vertical position (0 = top edge, 1 = bottom edge)
- `z`: Depth (0 = closest, 1 = farthest from camera)

### Frame Count
- Typical range: 30-80 frames per video
- At 30fps: 1-3 seconds per sign
- Model uses fixed 30 frames (padded or truncated)

### Hand Landmark Points

| Index | Name | Description |
|-------|------|-------------|
| 0 | WRIST | Base of hand |
| 1-4 | THUMB | Thumb: MCP, PIP, DIP, TIP |
| 5-8 | INDEX | Index finger: MCP, PIP, DIP, TIP |
| 9-12 | MIDDLE | Middle finger: MCP, PIP, DIP, TIP |
| 13-16 | RING | Ring finger: MCP, PIP, DIP, TIP |
| 17-20 | PINKY | Pinky finger: MCP, PIP, DIP, TIP |

**Total: 21 landmarks × 3 coordinates = 63 values per frame**

## 📈 Training Data Format

After `2_train_model.py` prepares data:

```
Feature Shape: (num_samples, 30, 63)
├─ num_samples: ~300 (100 videos × 3 augmentation)
├─ 30: Fixed sequence length (padded with zeros if needed)
└─ 63: 21 landmarks × 3 coordinates

Label Shape: (num_samples,)
├─ 0 = HELLO
├─ 1 = HOW ARE YOU
├─ 2 = YES
├─ 3 = ONE
└─ 4 = TEN
```

## 🔄 Data Augmentation

To improve model robustness with limited data:

```
Original videos: 100
After augmentation:
  ├─ Original: 100 samples
  ├─ With noise (±0.02): 100 samples
  └─ With noise (±0.02): 100 samples
Total: 300 training samples
```

## 📝 Sign Mapping JSON Format

File: `models/sign_mapping.json`

```json
{
  "label_to_sign": {
    "0": "HELLO",
    "1": "HOW ARE YOU",
    "2": "YES",
    "3": "ONE",
    "4": "TEN"
  }
}
```

Used to convert model predictions (0-4) back to sign names.

## 🎯 Model Input/Output

### Input
```
Shape: (batch_size=1, sequence_length=30, features=63)
Example: One frame sequence of 30 frames, each with 21 hand landmarks
```

### Output
```
Shape: (batch_size=1, num_signs=5)
Example: [0.02, 0.95, 0.01, 0.01, 0.01]

Interpretation:
- Sign 0 (HELLO): 2% probability
- Sign 1 (HOW ARE YOU): 95% probability ← Maximum
- Sign 2 (YES): 1% probability
- Sign 3 (ONE): 1% probability
- Sign 4 (TEN): 1% probability

Result: "HOW ARE YOU" with 95% confidence
```

## 🔍 Custom Modifications

### Change Sequence Length

In `2_train_model.py`:
```python
SEQUENCE_LENGTH = 30  # Change to 50 for more temporal context
```

Longer sequences = more temporal patterns captured (but slower)

### Change Number of Signs

In both scripts:
```python
# 1_extract_landmarks.py
SELECTED_SIGNS = [3, 4, 15, 20, 29, 30]  # Add more IDs

# 2_train_model.py (automatic detection)
# Will use number of signs from extracted data
```

### Change Model Architecture

In `2_train_model.py`:
```python
def build_model(num_classes=5):
    model = keras.Sequential([
        layers.LSTM(128, activation='relu', return_sequences=True,  # Increase units
                   input_shape=(SEQUENCE_LENGTH, 63)),
        layers.Dropout(0.3),  # Increase dropout
        layers.LSTM(64, activation='relu'),
        layers.Dropout(0.3),
        layers.Dense(128, activation='relu'),  # More dense layers
        layers.Dropout(0.2),
        layers.Dense(num_classes, activation='softmax')
    ])
```

## 📊 Data Quality Checks

### Good Training Data
- ✅ Clear hand visibility in frame
- ✅ Consistent lighting across videos
- ✅ Similar camera distance/angle
- ✅ Diverse poses for same sign
- ✅ 20-40 frames per video

### Problematic Data
- ❌ Hand partially out of frame
- ❌ Poor lighting (too dark/bright)
- ❌ Extreme angles or distances
- ❌ Too short videos (<10 frames)
- ❌ Too long videos (>200 frames)

## 🔗 Data Flow in Flutter

```
Camera Frame (1920×1080)
    ↓
MediaPipe Hand Detector
    ↓
Hand Landmarks (21 points)
    ↓
Normalize coordinates
    ↓
Add to sequence (append to list)
    ↓
When 30 frames collected:
    ├─ Create input tensor (1, 30, 63)
    ├─ Run TFLite inference
    ├─ Get output (1, 5)
    └─ Find max probability → Sign name
```

## 💾 File Sizes

| File | Size | Note |
|------|------|------|
| landmarks_data.json | 2-3 MB | All extracted landmarks |
| gesture_model.h5 | 2-3 MB | Full Keras model (backup) |
| gesture_model.tflite | ~500 KB | Optimized for mobile ★ |
| sign_mapping.json | <1 KB | Label mapping |

---

## 🧮 Math Behind the Scenes

### Normalization
```
Raw coordinate value: 123 pixels
Image size: 640 pixels
Normalized: 123 / 640 = 0.192 (0-1 range)
```

### Padding Sequences
```
Video has 20 frames, model expects 30:
[frame1, frame2, ..., frame20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
                                 ↑ Padded zeros (10 frames)
```

### Softmax Probability
```
Model output: [1.2, 3.1, 0.8, 0.5, 0.4]
After softmax: [0.02, 0.95, 0.01, 0.01, 0.01]
              └─ Probabilities sum to 1.0
```

---

## 📚 References

- [MediaPipe Hand Documentation](https://mediapipe.dev/solutions/hands)
- [TensorFlow LSTM](https://www.tensorflow.org/api_docs/python/tf/keras/layers/LSTM)
- [TFLite Interpreter](https://www.tensorflow.org/lite/guide/inference)

