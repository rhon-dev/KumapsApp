"""
Extract hand landmarks from FSL-105 dataset videos using OpenCV
Simple fallback method without MediaPipe dependencies
"""

import cv2
import numpy as np
import os
from pathlib import Path
import json

print("Initializing hand landmark extraction (OpenCV-based)...")

# For this demo, we'll use a simplified feature extraction based on hand contours
# In production, you'd use MediaPipe, but this works offline

# Choose your 5 signs here (by ID)
SELECTED_SIGNS = [3, 4, 15, 20, 29]  # HELLO, HOW ARE YOU, YES, ONE, TEN
SELECTED_SIGN_NAMES = ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"]

# Dataset path
DATASET_PATH = "/Users/ahronjanl.rafaelahron.0804icloudcom/Downloads/FSL-105 A dataset for recognizing 105 Filipino sign language videos"
OUTPUT_DIR = "/Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp/ml_training/extracted_landmarks"

os.makedirs(OUTPUT_DIR, exist_ok=True)

def extract_hand_features_from_video(video_path):
    """
    Extract hand features from video using color-based hand detection
    Returns: List of feature vectors (one per frame)
    """
    cap = cv2.VideoCapture(video_path)
    features_sequence = []
    
    if not cap.isOpened():
        return None
    
    # HSV range for skin color detection
    lower_skin = np.array([0, 20, 70], dtype=np.uint8)
    upper_skin = np.array([20, 255, 255], dtype=np.uint8)
    
    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_count += 1
        
        # Only process every 3rd frame to speed up (can process all if needed)
        if frame_count % 3 != 0:
            continue
        
        try:
            # Resize for faster processing
            frame = cv2.resize(frame, (320, 240))
            
            # Convert to HSV
            hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
            
            # Create skin mask
            mask = cv2.inRange(hsv, lower_skin, upper_skin)
            
            # Apply morphological operations
            kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
            mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
            mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
            
            # Find contours
            contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            if contours:
                # Get largest contour (hand)
                hand_contour = max(contours, key=cv2.contourArea)
                
                # Extract features from contour
                area = cv2.contourArea(hand_contour)
                
                # Get bounding rectangle
                x, y, w, h = cv2.boundingRect(hand_contour)
                aspect_ratio = float(w) / h if h > 0 else 0
                
                # Get contour moments
                M = cv2.moments(hand_contour)
                cx = int(M['m10'] / M['m00']) if M['m00'] != 0 else 0
                cy = int(M['m01'] / M['m00']) if M['m00'] != 0 else 0
                
                # Normalize features to 0-1 range
                normalized_features = [
                    min(area / (320 * 240), 1.0),  # Area ratio
                    min(aspect_ratio, 1.0),  # Aspect ratio
                    cx / 320,  # Centroid X
                    cy / 240,  # Centroid Y
                    min(w / 320, 1.0),  # Width ratio
                    min(h / 240, 1.0),  # Height ratio
                ]
                
                # Pad to 63 features (like MediaPipe landmarks)
                padded_features = normalized_features + [0.0] * (63 - len(normalized_features))
                features_sequence.append(padded_features[:63])
        
        except Exception as e:
            pass
    
    cap.release()
    
    if len(features_sequence) < 5:  # Need at least a few frames
        return None
    
    return features_sequence

def process_sign_videos(sign_id, sign_name):
    """Process all videos for a specific sign"""
    sign_path = os.path.join(DATASET_PATH, "clips", str(sign_id))
    
    if not os.path.exists(sign_path):
        print(f"Sign path not found: {sign_path}")
        return []
    
    all_landmarks = []
    
    # Get all .MOV files for this sign
    video_files = sorted([f for f in os.listdir(sign_path) if f.endswith('.MOV')])
    
    print(f"\nProcessing {sign_name} (ID: {sign_id}) - {len(video_files)} videos")
    
    for i, video_file in enumerate(video_files, 1):
        video_path = os.path.join(sign_path, video_file)
        print(f"  [{i:2d}/{len(video_files)}] {video_file}...", end=" ", flush=True)
        
        features = extract_hand_features_from_video(video_path)
        
        if features and len(features) > 0:
            all_landmarks.append({
                'sign_id': sign_id,
                'sign_name': sign_name,
                'video_file': video_file,
                'num_frames': len(features),
                'landmarks': features
            })
            print(f"✓ ({len(features)} frames)")
        else:
            print("✗ (no hand detected)")
    
    return all_landmarks

def save_landmarks_for_training():
    """Extract landmarks for all selected signs and save for training"""
    
    all_data = []
    
    for sign_id, sign_name in zip(SELECTED_SIGNS, SELECTED_SIGN_NAMES):
        sign_data = process_sign_videos(sign_id, sign_name)
        all_data.extend(sign_data)
    
    # Save as JSON for easy loading
    output_file = os.path.join(OUTPUT_DIR, "landmarks_data.json")
    with open(output_file, 'w') as f:
        json.dump(all_data, f, indent=2)
    
    print(f"\n✅ Features extracted and saved to: {output_file}")
    print(f"Total videos processed: {len(all_data)}")
    
    return all_data

if __name__ == "__main__":
    print("=" * 60)
    print("FSL-105 Hand Features Extraction")
    print("=" * 60)
    print(f"Selected signs: {list(zip(SELECTED_SIGNS, SELECTED_SIGN_NAMES))}")
    print(f"Output directory: {OUTPUT_DIR}")
    print("Method: OpenCV-based hand detection")
    
    landmarks_data = save_landmarks_for_training()
    
    # Print summary
    print("\n" + "=" * 60)
    print("Summary:")
    print("=" * 60)
    for sign_id, sign_name in zip(SELECTED_SIGNS, SELECTED_SIGN_NAMES):
        count = sum(1 for item in landmarks_data if item['sign_id'] == sign_id)
        print(f"{sign_name}: {count} videos")
    
    print("\nNote: Using OpenCV-based features as fallback.")
    print("For production, integrate MediaPipe or TensorFlow hand detection.")

# Choose your 5 signs here (by ID)
SELECTED_SIGNS = [3, 4, 15, 20, 29]  # HELLO, HOW ARE YOU, YES, ONE, TEN
SELECTED_SIGN_NAMES = ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"]

# Dataset path
DATASET_PATH = "/Users/ahronjanl.rafaelahron.0804icloudcom/Downloads/FSL-105 A dataset for recognizing 105 Filipino sign language videos"
OUTPUT_DIR = "/Users/ahronjanl.rafaelahron.0804icloudcom/KumapsApp/ml_training/extracted_landmarks"

os.makedirs(OUTPUT_DIR, exist_ok=True)

def extract_landmarks_from_video(video_path):
    """
    Extract hand landmarks from a single video
    Returns: List of landmark frames (each frame has hand landmarks)
    """
    cap = cv2.VideoCapture(video_path)
    landmarks_sequence = []
    
    if not cap.isOpened():
        print(f"Failed to open video: {video_path}")
        return None
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        # Flip horizontally for selfie view
        frame = cv2.flip(frame, 1)
        
        # Convert BGR to RGB
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Get hand landmarks
        results = hands.process(image_rgb)
        
        if results.multi_hand_landmarks:
            # Extract landmarks for first hand (primary hand)
            hand_landmarks = results.multi_hand_landmarks[0]
            
            # Normalize landmarks to 0-1 range
            frame_landmarks = []
            for landmark in hand_landmarks.landmark:
                frame_landmarks.extend([landmark.x, landmark.y, landmark.z])
            
            landmarks_sequence.append(frame_landmarks)
    
    cap.release()
    
    if len(landmarks_sequence) == 0:
        print(f"No landmarks detected in {video_path}")
        return None
    
    return landmarks_sequence

def process_sign_videos(sign_id, sign_name):
    """Process all videos for a specific sign"""
    sign_path = os.path.join(DATASET_PATH, "clips", str(sign_id))
    
    if not os.path.exists(sign_path):
        print(f"Sign path not found: {sign_path}")
        return []
    
    all_landmarks = []
    
    # Get all .MOV files for this sign
    video_files = sorted([f for f in os.listdir(sign_path) if f.endswith('.MOV')])
    
    print(f"\nProcessing {sign_name} (ID: {sign_id}) - {len(video_files)} videos")
    
    for video_file in video_files:
        video_path = os.path.join(sign_path, video_file)
        print(f"  Processing {video_file}...", end=" ")
        
        landmarks = extract_landmarks_from_video(video_path)
        
        if landmarks:
            all_landmarks.append({
                'sign_id': sign_id,
                'sign_name': sign_name,
                'video_file': video_file,
                'num_frames': len(landmarks),
                'landmarks': landmarks  # List of frames, each with 63 values (21 landmarks × 3 coords)
            })
            print(f"✓ ({len(landmarks)} frames)")
        else:
            print("✗ (no landmarks)")
    
    return all_landmarks

def save_landmarks_for_training():
    """Extract landmarks for all selected signs and save for training"""
    
    all_data = []
    
    for sign_id, sign_name in zip(SELECTED_SIGNS, SELECTED_SIGN_NAMES):
        sign_data = process_sign_videos(sign_id, sign_name)
        all_data.extend(sign_data)
    
    # Save as JSON for easy loading
    output_file = os.path.join(OUTPUT_DIR, "landmarks_data.json")
    with open(output_file, 'w') as f:
        # Convert numpy arrays to lists for JSON serialization
        data_to_save = []
        for item in all_data:
            data_to_save.append({
                'sign_id': item['sign_id'],
                'sign_name': item['sign_name'],
                'video_file': item['video_file'],
                'num_frames': item['num_frames'],
                'landmarks': item['landmarks']
            })
        json.dump(data_to_save, f, indent=2)
    
    print(f"\n✅ Landmarks extracted and saved to: {output_file}")
    print(f"Total videos processed: {len(all_data)}")
    
    return all_data

if __name__ == "__main__":
    print("=" * 60)
    print("FSL-105 Hand Landmarks Extraction")
    print("=" * 60)
    print(f"Selected signs: {list(zip(SELECTED_SIGNS, SELECTED_SIGN_NAMES))}")
    print(f"Output directory: {OUTPUT_DIR}")
    
    landmarks_data = save_landmarks_for_training()
    
    # Print summary
    print("\n" + "=" * 60)
    print("Summary:")
    print("=" * 60)
    for sign_id, sign_name in zip(SELECTED_SIGNS, SELECTED_SIGN_NAMES):
        count = sum(1 for item in landmarks_data if item['sign_id'] == sign_id)
        print(f"{sign_name}: {count} videos")
