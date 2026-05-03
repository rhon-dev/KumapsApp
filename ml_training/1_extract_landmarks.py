"""
Extract hand features from FSL-105 dataset videos using OpenCV.

FIX: Previous version extracted 6 real features but padded to 63 zeros per
frame (57 zeros = 90% noise). Now extracts 15 meaningful features per frame:
  - 6 shape/position features (area, aspect ratio, centroid, bounding box)
  - 1 convex hull fill ratio (how open the hand is)
  - 1 convexity defect count (rough finger count estimator)
  - 7 Hu moments (rotation/scale invariant shape descriptors)
"""

import cv2
import numpy as np
import os
import json

SELECTED_SIGNS = [3, 4, 15, 20, 29]
SELECTED_SIGN_NAMES = ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"]

# Use paths relative to this script file so it works on any machine
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_PATH = os.path.join(
    os.path.expanduser("~"), "Downloads",
    "FSL-105 A dataset for recognizing 105 Filipino sign language videos"
)
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "extracted_landmarks")
NUM_FEATURES = 15  # features per frame

# Minimum hand region size to filter out small noise
MIN_HAND_AREA_RATIO = 0.005  # at least 0.5% of the frame

os.makedirs(OUTPUT_DIR, exist_ok=True)


def extract_hand_features(frame):
    """
    Extract 15 hand features from one video frame.
    Returns a list of 15 floats, or None if no hand is detected.
    """
    h, w = frame.shape[:2]
    frame_area = h * w

    # Skin color mask in HSV space
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    lower_skin = np.array([0, 20, 70], dtype=np.uint8)
    upper_skin = np.array([20, 255, 255], dtype=np.uint8)
    mask = cv2.inRange(hsv, lower_skin, upper_skin)

    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)

    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None

    hand = max(contours, key=cv2.contourArea)
    area = cv2.contourArea(hand)

    # Reject tiny noise blobs
    if area / frame_area < MIN_HAND_AREA_RATIO:
        return None

    # Basic shape features
    x, y, bw, bh = cv2.boundingRect(hand)
    aspect_ratio = float(bw) / bh if bh > 0 else 0.0

    M = cv2.moments(hand)
    if M['m00'] != 0:
        cx = M['m10'] / M['m00']
        cy = M['m01'] / M['m00']
    else:
        cx, cy = x + bw / 2.0, y + bh / 2.0

    # Convex hull fill ratio: close to 1.0 means fist, lower means open hand
    hull_pts = cv2.convexHull(hand)
    hull_area = cv2.contourArea(hull_pts)
    hull_ratio = area / hull_area if hull_area > 0 else 1.0

    # Convexity defects = gaps between fingers (rough finger count)
    defect_count = 0
    hull_idx = cv2.convexHull(hand, returnPoints=False)
    if hull_idx is not None and len(hull_idx) > 3 and len(hand) > 3:
        defects = cv2.convexityDefects(hand, hull_idx)
        if defects is not None:
            for d in defects:
                _, _, _, depth = d[0]
                if depth / 256.0 > 10:  # only count deep gaps (real finger spaces)
                    defect_count += 1

    # Hu moments: 7 values that describe hand shape independently of
    # rotation, scale, and translation. Log-scaled to normalize wide range.
    hu = cv2.HuMoments(M).flatten()
    hu_log = -np.sign(hu) * np.log10(np.abs(hu) + 1e-10)
    hu_norm = np.clip(hu_log / 10.0, -1.0, 1.0)

    features = [
        min(area / frame_area, 1.0),        # 1.  Normalized area
        min(aspect_ratio / 2.0, 1.0),       # 2.  Aspect ratio (capped at 2:1)
        cx / w,                              # 3.  Centroid X (0-1)
        cy / h,                              # 4.  Centroid Y (0-1)
        min(bw / w, 1.0),                   # 5.  Bounding box width ratio
        min(bh / h, 1.0),                   # 6.  Bounding box height ratio
        float(np.clip(hull_ratio, 0.0, 1.0)), # 7. Hull fill ratio
        min(defect_count / 5.0, 1.0),       # 8.  Defect count (0-5 fingers mapped 0-1)
    ] + list(hu_norm)                        # 9-15. Hu moments (7 values)

    assert len(features) == NUM_FEATURES
    return features


def extract_features_from_video(video_path):
    """Extract features from every frame of a video."""
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        return None

    sequence = []
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        frame = cv2.resize(frame, (320, 240))
        feat = extract_hand_features(frame)
        if feat is not None:
            sequence.append(feat)

    cap.release()

    if len(sequence) < 5:  # need at least a few good frames
        return None
    return sequence


def process_sign_videos(sign_id, sign_name):
    sign_path = os.path.join(DATASET_PATH, "clips", str(sign_id))
    if not os.path.exists(sign_path):
        print(f"  Path not found: {sign_path}")
        return []

    video_files = sorted(
        f for f in os.listdir(sign_path)
        if f.upper().endswith('.MOV') or f.endswith('.mp4')
    )
    print(f"\n{sign_name} (ID {sign_id}): {len(video_files)} videos")

    results = []
    for i, vf in enumerate(video_files, 1):
        path = os.path.join(sign_path, vf)
        print(f"  [{i:2d}/{len(video_files)}] {vf}...", end=" ", flush=True)
        features = extract_features_from_video(path)
        if features:
            results.append({
                'sign_id': sign_id,
                'sign_name': sign_name,
                'video_file': vf,
                'num_frames': len(features),
                'landmarks': features,
            })
            print(f"OK  ({len(features)} frames, {NUM_FEATURES} features/frame)")
        else:
            print("SKIP  (no hand detected)")
    return results


if __name__ == "__main__":
    print("=" * 60)
    print("FSL-105 Hand Feature Extraction")
    print(f"Features per frame : {NUM_FEATURES}  (was 6 real + 57 zeros)")
    print(f"Dataset            : {DATASET_PATH}")
    print(f"Output             : {OUTPUT_DIR}")
    print("=" * 60)

    all_data = []
    for sid, sname in zip(SELECTED_SIGNS, SELECTED_SIGN_NAMES):
        all_data.extend(process_sign_videos(sid, sname))

    output_file = os.path.join(OUTPUT_DIR, "landmarks_data.json")
    with open(output_file, 'w') as f:
        json.dump(all_data, f)

    print(f"\nSaved {len(all_data)} videos -> {output_file}")
    print("\nPer-class count:")
    for sid, sname in zip(SELECTED_SIGNS, SELECTED_SIGN_NAMES):
        count = sum(1 for d in all_data if d['sign_id'] == sid)
        print(f"  {sname}: {count} videos")
    print("\nNext step: python3 2_train_model.py")
