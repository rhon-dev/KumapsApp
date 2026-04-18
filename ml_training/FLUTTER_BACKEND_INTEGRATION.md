# Quick Integration: Flask Backend for Gesture Recognition

Since we trained using scikit-learn's Random Forest model (gesture_model.pkl), the easiest path for Flutter is to:

**Option 1 (Recommended): Use Flask backend for inference**
**Option 2: Convert model to JSON and re-implement in Dart**

## 🚀 Option 1: Flask Backend (Simplest)

### Step 1: Install Flask

```bash
cd ml_training
source venv/bin/activate
pip install Flask Flask-CORS
```

### Step 2: Create Flask API

Create `flask_api.py` in ml_training/:

```python
from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import json
import numpy as np
import os

app = Flask(__name__)
CORS(app)

# Load model
with open('models/gesture_model.pkl', 'rb') as f:
    model_data = pickle.load(f)

model = model_data['model']
scaler = model_data['scaler']
sign_mapping = model_data['sign_to_label']
reverse_mapping = {v: k for k, v in sign_mapping.items()}

# Load sign JSON mapping
with open('models/sign_mapping.json', 'r') as f:
    label_mapping = json.load(f)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

@app.route('/predict', methods=['POST'])
def predict():
    """Predict sign from hand landmark sequence"""
    try:
        data = request.json
        landmarks = np.array(data['landmarks']).reshape(1, -1)
        
        # Normalize using same scaler
        landmarks = scaler.transform(landmarks)
        
        # Get prediction
        prediction = model.predict(landmarks)[0]
        probabilities = model.predict_proba(landmarks)[0]
        
        sign_name = reverse_mapping[prediction]
        confidence = float(probabilities[prediction])
        
        return jsonify({
            'sign': sign_name,
            'label': int(prediction),
            'confidence': confidence,
            'probabilities': {
                label_mapping['label_to_sign'][str(i)]: float(prob)
                for i, prob in enumerate(probabilities)
            }
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
```

### Step 3: Start Flask Server

```bash
python3 flask_api.py
```

You'll see:
```
 * Running on http://0.0.0.0:5000
```

### Step 4: Update Flutter to Use Backend

In `camera_provider.dart`:

```dart
import 'package:http/http.dart' as http;

class CameraProvider extends ChangeNotifier {
  static const String API_URL = 'http://192.168.x.x:5000';  // Your machine IP
  
  List<List<double>> _landmarkSequence = [];
  String _recognizedSign = '';
  double _recognitionConfidence = 0.0;
  
  /// Process frame and send landmarks to backend
  Future<void> _processFrameAndInference(List<double> frameLandmarks) async {
    // Add to sequence
    _landmarkSequence.add(frameLandmarks);
    
    if (_landmarkSequence.length > 30) {
      _landmarkSequence.removeAt(0);
    }
    
    // Send to backend when we have 30 frames
    if (_landmarkSequence.length == 30) {
      await _sendToBackendForPrediction();
    }
    
    notifyListeners();
  }
  
  /// Send landmark sequence to Flask backend
  Future<void> _sendToBackendForPrediction() async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'landmarks': _landmarkSequence.expand((x) => x).toList()
        }),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _recognizedSign = data['sign'];
        _recognitionConfidence = (data['confidence'] as num).toDouble();
        
        debugPrint('Recognized: $_recognizedSign (${_recognitionConfidence.toStringAsFixed(2)})');
      }
    } catch (e) {
      debugPrint('Backend error: $e');
    }
  }
}
```

### Step 5: Update `pubspec.yaml`

```yaml
dependencies:
  http: ^1.1.0
  camera: ^0.10.5
```

---

## ⚙️ Option 2: Desktop/Web Only (Using Python)

If you're only targeting web or desktop, use Python's Flask to serve your entire app:

```bash
python3 flask_api.py
# Then access from web browser at http://localhost:5000
```

---

## 🔧 How to Find Your Machine IP

For connecting Flutter app to backend:

```bash
# macOS
ifconfig | grep "inet " | grep -v "127.0.0.1"

# Example output:
# inet 192.168.1.100 netmask 0xffffff00
```

Use that IP in Flutter (e.g., `http://192.168.1.100:5000`)

---

## 🚀 Testing

### 1. Start Flask server
```bash
cd ml_training && python3 flask_api.py
```

### 2. Test with curl
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "landmarks": [0.1, 0.2, 0.3, ..., 0.5]  # 30*63=1890 values
  }'
```

### 3. Response
```json
{
  "sign": "HELLO",
  "label": 0,
  "confidence": 0.92,
  "probabilities": {
    "HELLO": 0.92,
    "HOW ARE YOU": 0.05,
    "YES": 0.02,
    "ONE": 0.01,
    "TEN": 0.00
  }
}
```

---

## 📱 Production Considerations

For production, you might want to:

1. **Deploy Flask on a server** (AWS, Google Cloud, etc.)
2. **Use HTTPS** instead of HTTP
3. **Add authentication** to the API
4. **Optimize inference** with model quantization
5. **Cache predictions** for repeated gestures

---

## 🆘 Troubleshooting

### "Cannot reach backend from Flutter"
- Ensure Flask is running: `python3 flask_api.py`
- Check machine IP: `ifconfig`
- Make sure both devices are on same network
- Check firewall isn't blocking port 5000

### "Model loading failed"
- Ensure gesture_model.pkl exists
- Check file permissions: `ls -l models/`
- Verify pickle file not corrupted

### "Slow inference"
- Flask runs inference on your machine CPU
- For faster results, use GPU or optimize model
- Reduce landmark dimension or use simpler model

