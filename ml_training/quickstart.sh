#!/bin/bash

# Quick Start Script for Hand Gesture Recognition
# This script automates the entire setup process

set -e

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║    FSL-105 Hand Gesture Recognition - Quick Start Setup         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo ""
echo "📍 Working directory: $SCRIPT_DIR"
echo ""

# Step 1: Check Python
echo "Step 1️⃣  Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.9+"
    exit 1
fi
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo "✅ Python $PYTHON_VERSION found"

# Step 2: Create virtual environment
echo ""
echo "Step 2️⃣  Setting up virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate
echo "✅ Virtual environment activated"

# Step 3: Install dependencies
echo ""
echo "Step 3️⃣  Installing Python dependencies..."
echo "   (This may take 3-5 minutes on first run)"
pip install -q --upgrade pip
pip install -q -r requirements.txt
echo "✅ Dependencies installed"

# Step 4: Extract landmarks
echo ""
echo "Step 4️⃣  Extracting hand landmarks from videos..."
echo "   (This may take 5-10 minutes depending on your machine)"
python3 1_extract_landmarks.py

# Step 5: Train model
echo ""
echo "Step 5️⃣  Training gesture recognition model..."
echo "   (This may take 10-15 minutes)"
python3 2_train_model.py

# Step 6: Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ Setup Complete!                           ║"
echo "╚══════════════════════════════════════════════════════════════════╝"

echo ""
echo "📦 Generated Files:"
echo "   ✓ extracted_landmarks/landmarks_data.json"
echo "   ✓ models/gesture_model.tflite (for Flutter)"
echo "   ✓ models/gesture_model.h5"
echo "   ✓ models/sign_mapping.json"

echo ""
echo "📋 Next Steps:"
echo "   1. Copy models to Flutter:"
echo "      mkdir -p ../assets/models"
echo "      cp models/gesture_model.tflite ../assets/models/"
echo "      cp models/sign_mapping.json ../assets/models/"
echo ""
echo "   2. Update pubspec.yaml with new dependencies:"
echo "      - tflite_flutter: ^0.10.0"
echo "      - google_mlkit_hand_pose_detection: ^0.4.0"
echo ""
echo "   3. Update camera_provider.dart with the code from:"
echo "      camera_provider_updated.dart"
echo ""
echo "   4. Run Flutter:"
echo "      cd .."
echo "      flutter pub get"
echo "      flutter run"

echo ""
echo "💡 To customize signs, edit:"
echo "   1_extract_landmarks.py (lines 20-21)"

echo ""
echo "📚 For more details, see: README.md"

echo ""
