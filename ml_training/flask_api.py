"""
Flask API for gesture recognition inference
Serves predictions from the trained gesture_model.pkl

Usage:
    python3 flask_api.py
    
Then from Flutter or curl:
    curl -X POST http://localhost:5000/predict \
      -H "Content-Type: application/json" \
      -d '{"landmarks": [...]}'
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import json
import numpy as np
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configuration
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'models', 'gesture_model.pkl')
MAPPING_PATH = os.path.join(os.path.dirname(__file__), 'models', 'sign_mapping.json')

print("Loading gesture recognition model...")

# Load model
try:
    with open(MODEL_PATH, 'rb') as f:
        model_data = pickle.load(f)
    
    model = model_data['model']
    scaler = model_data['scaler']
    sign_to_label = model_data['sign_to_label']
    reverse_mapping = {v: k for k, v in sign_to_label.items()}
    
    print(f"✅ Model loaded: {MODEL_PATH}")
    print(f"✅ Signs: {list(reverse_mapping.values())}")
except Exception as e:
    print(f"❌ Error loading model: {e}")
    raise

# Load sign mapping JSON
try:
    with open(MAPPING_PATH, 'r') as f:
        label_mapping = json.load(f)
    print(f"✅ Mapping loaded: {MAPPING_PATH}")
except Exception as e:
    print(f"❌ Error loading mapping: {e}")
    raise


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'model': 'gesture_recognition',
        'signs': list(reverse_mapping.values()),
        'timestamp': datetime.now().isoformat()
    })


@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict sign from hand landmark sequence
    
    Expected JSON:
    {
        "landmarks": [float, float, ...],  # 30*63=1890 values
        "confidence_threshold": 0.7         # Optional, default 0.7
    }
    
    Returns:
    {
        "sign": "HELLO",
        "label": 0,
        "confidence": 0.92,
        "probabilities": {
            "HELLO": 0.92,
            "HOW ARE YOU": 0.05,
            ...
        }
    }
    """
    try:
        data = request.json
        
        if not data or 'landmarks' not in data:
            return jsonify({'error': 'Missing landmarks field'}), 400
        
        landmarks = data['landmarks']
        confidence_threshold = data.get('confidence_threshold', 0.7)
        
        # Validate input
        if len(landmarks) != 1890:  # 30 frames × 63 features
            return jsonify({
                'error': f'Expected 1890 landmark values, got {len(landmarks)}'
            }), 400
        
        # Prepare features
        landmarks_array = np.array(landmarks).reshape(1, -1)
        
        # Normalize using the same scaler from training
        landmarks_normalized = scaler.transform(landmarks_array)
        
        # Get prediction
        prediction_label = model.predict(landmarks_normalized)[0]
        probabilities = model.predict_proba(landmarks_normalized)[0]
        
        # Get sign name
        sign_name = reverse_mapping[prediction_label]
        confidence = float(probabilities[prediction_label])
        
        # Build response
        response = {
            'sign': sign_name,
            'label': int(prediction_label),
            'confidence': round(confidence, 4),
            'probabilities': {}
        }
        
        # Add all sign probabilities
        for label_idx, prob in enumerate(probabilities):
            sign = reverse_mapping[label_idx]
            response['probabilities'][sign] = round(float(prob), 4)
        
        # Check threshold
        if confidence < confidence_threshold:
            response['warning'] = f'Low confidence: {confidence:.2%} < {confidence_threshold:.0%}'
        
        return jsonify(response)
    
    except ValueError as e:
        return jsonify({'error': f'Invalid input: {str(e)}'}), 400
    except Exception as e:
        return jsonify({'error': f'Prediction error: {str(e)}'}), 500


@app.route('/info', methods=['GET'])
def info():
    """Get model information"""
    return jsonify({
        'model_type': 'Random Forest',
        'model_path': MODEL_PATH,
        'signs': list(reverse_mapping.values()),
        'num_signs': len(reverse_mapping),
        'sequence_length': 30,
        'features_per_frame': 63,
        'total_features': 1890,
        'framework': 'scikit-learn'
    })


@app.route('/version', methods=['GET'])
def version():
    """Get API version"""
    return jsonify({
        'api_version': '1.0',
        'model_version': '1.0',
        'created': '2026-04-18'
    })


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Endpoint not found',
        'available_endpoints': [
            'GET /health',
            'GET /info',
            'GET /version',
            'POST /predict'
        ]
    }), 404


@app.errorhandler(500)
def server_error(error):
    """Handle 500 errors"""
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    print("\n" + "="*60)
    print("🚀 Gesture Recognition Flask API")
    print("="*60)
    print(f"Model: {MODEL_PATH}")
    print(f"Signs: {', '.join(reverse_mapping.values())}")
    print("\nEndpoints:")
    print("  GET  /health     - Health check")
    print("  GET  /info       - Model information")
    print("  GET  /version    - API version")
    print("  POST /predict    - Make prediction")
    print("\nStarting server...")
    print("="*60 + "\n")
    
    # Run with threaded=True for concurrent requests
    app.run(
        host='0.0.0.0',
        port=5001,
        debug=False,
        threaded=True
    )
