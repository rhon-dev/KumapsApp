import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:kumpas/presentation/widgets/hand_joint_painter.dart';

/// Service for extracting hand landmarks from camera frames
class LandmarkExtractor {
  static const int frameBufferSize = 30;
  static const int featuresPerFrame = 63;
  static const int totalFeatures = frameBufferSize * featuresPerFrame; // 1,890

  final List<List<double>> _frameBuffer = [];
  int _frameCount = 0;

  /// Add a frame and get hand skeleton if available
  Future<HandSkeleton?> processFrame(CameraImage cameraImage) async {
    // Simulate hand landmark extraction
    // In production, this would use MediaPipe or similar
    final landmarks = _extractLandmarks(cameraImage);

    if (landmarks.isNotEmpty) {
      _frameBuffer.add(landmarks);
      _frameCount++;

      // Keep buffer size at frameBufferSize
      if (_frameBuffer.length > frameBufferSize) {
        _frameBuffer.removeAt(0);
      }

      return _createHandSkeleton(landmarks);
    }

    return null;
  }

  /// Get buffered landmarks as 1,890-feature array
  /// Pads with zeros if buffer is not full
  List<double> getBufferedLandmarks() {
    final result = <double>[];

    // Add frames from buffer
    for (final frame in _frameBuffer) {
      result.addAll(frame);
    }

    // Pad with zeros if buffer not full
    final expectedSize = frameBufferSize * featuresPerFrame;
    while (result.length < expectedSize) {
      result.add(0.0);
    }

    return result.sublist(0, expectedSize);
  }

  /// Clear frame buffer (e.g., when starting new gesture)
  void clearBuffer() {
    _frameBuffer.clear();
    _frameCount = 0;
  }

  /// Get number of frames in buffer
  int get frameCount => _frameCount;

  /// Check if buffer is full
  bool get isBufferFull => _frameBuffer.length >= frameBufferSize;

  /// Extract hand landmarks from camera frame
  /// Returns list of 63 features per frame
  /// Features: 20 joints * 3 (x, y, confidence) + 3 (hand motion features)
  List<double> _extractLandmarks(CameraImage image) {
    try {
      // Convert camera image to RGB
      final rgbImage = _convertCameraImageToRGB(image);
      if (rgbImage == null) return [];

      // Detect hand regions using simple color-based thresholding
      final handPoints = _detectHandRegions(rgbImage);
      if (handPoints.isEmpty) return [];

      // Extract 20 hand joints (normalized coordinates)
      final joints =
          _extractHandJoints(handPoints, rgbImage.width, rgbImage.height);

      // Calculate motion features
      final motionFeatures = _calculateMotionFeatures(joints);

      // Combine: 20 joints * 3 (x, y, confidence) + 3 motion features = 63 features
      final features = <double>[];
      for (final joint in joints) {
        features.addAll([
          joint.position.dx, // normalized x (0-1)
          joint.position.dy, // normalized y (0-1)
          joint.confidence, // confidence (0-1)
        ]);
      }
      features.addAll(motionFeatures);

      return features;
    } catch (e) {
      debugPrint('Error extracting landmarks: $e');
      return [];
    }
  }

  /// Convert camera image to RGB
  img.Image? _convertCameraImageToRGB(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;

      // Handle different image formats
      if (image.format.group == ImageFormatGroup.yuv420) {
        // Convert NV21 to RGB
        final uvRowStride = image.planes[1].bytesPerRow;
        final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

        final rgbImage = img.Image(width: width, height: height);

        for (int h = 0; h < height; h++) {
          for (int w = 0; w < width; w++) {
            final uvIndex = uvPixelStride * (w ~/ 2) + uvRowStride * (h ~/ 2);

            final y =
                image.planes[0].bytes[h * image.planes[0].bytesPerRow + w];
            final u = image.planes[1].bytes[uvIndex];
            final v = image.planes[2].bytes[uvIndex];

            // YUV to RGB conversion
            final r = (y + 1.402 * (v - 128)).clamp(0, 255).toInt();
            final g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
                .clamp(0, 255)
                .toInt();
            final b = (y + 1.772 * (u - 128)).clamp(0, 255).toInt();

            rgbImage.setPixelRgba(w, h, r, g, b, 255);
          }
        }

        return rgbImage;
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        // BGRA format
        final bgra = image.planes[0].bytes;
        final rgbImage = img.Image(width: width, height: height);

        for (int i = 0; i < bgra.length; i += 4) {
          final b = bgra[i];
          final g = bgra[i + 1];
          final r = bgra[i + 2];
          final a = bgra[i + 3];

          final pixelIndex = i ~/ 4;
          final x = pixelIndex % width;
          final y = pixelIndex ~/ width;

          rgbImage.setPixelRgba(x, y, r, g, b, a);
        }

        return rgbImage;
      }

      return null;
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Detect hand regions using HSV color-based thresholding
  /// Similar to the Python cv2 approach
  List<Offset> _detectHandRegions(img.Image image) {
    final points = <Offset>[];

    // Skin color detection using HSV thresholding
    // Approximate skin tone ranges in HSV
    const minHue = 0;
    const maxHue = 30; // ~0-30 degrees
    const minSat = 10;
    const maxSat = 150; // ~10-60% saturation
    const minVal = 60;
    const maxVal = 255; // ~60-100% brightness

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Convert RGB to HSV
        final (h, s, v) = _rgbToHsv(r, g, b);

        // Check if pixel is in skin color range
        if ((h >= minHue && h <= maxHue || h >= 330) &&
            s >= minSat &&
            s <= maxSat &&
            v >= minVal &&
            v <= maxVal) {
          points.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }

    return points;
  }

  /// Convert RGB to HSV
  (double, double, double) _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final cmax = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
    final cmin = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
    final delta = cmax - cmin;

    double h = 0;
    if (delta != 0) {
      if (cmax == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (cmax == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
    }

    if (h < 0) h += 360;

    final s = cmax == 0 ? 0.0 : (delta / cmax) * 255;
    final v = cmax * 255;

    return (h, s, v);
  }

  /// Extract 20 hand joints from detected hand points
  List<HandJoint> _extractHandJoints(
    List<Offset> handPoints,
    int imageWidth,
    int imageHeight,
  ) {
    if (handPoints.isEmpty) {
      return _generateDefaultJoints();
    }

    // Find bounding box of hand
    double minX = double.infinity, maxX = 0;
    double minY = double.infinity, maxY = 0;

    for (final point in handPoints) {
      minX = minX > point.dx ? point.dx : minX;
      maxX = maxX < point.dx ? point.dx : maxX;
      minY = minY > point.dy ? point.dy : minY;
      maxY = maxY < point.dy ? point.dy : maxY;
    }

    // Normalize to 0-1 range
    minX = minX / imageWidth;
    maxX = maxX / imageWidth;
    minY = minY / imageHeight;
    maxY = maxY / imageHeight;

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    // Generate 20 joints distributed around hand bounding box
    // This is a simplified approach; production would use actual MediaPipe
    final joints = <HandJoint>[];
    const confidence = 0.8;

    // Wrist (center)
    joints.add(HandJoint(
      position: Offset(centerX, centerY),
      name: 'wrist',
      confidence: confidence,
    ));

    // Generate joints for 4 fingers + thumb (4 joints each)
    const fingerNames = ['thumb', 'index', 'middle', 'ring', 'pinky'];
    const angleStep = 72.0; // 360 / 5 fingers

    final handSize = ((maxX - minX) + (maxY - minY)) / 2;

    for (int i = 0; i < fingerNames.length; i++) {
      final angle = angleStep * i * 3.14159 / 180;
      final fingerName = fingerNames[i];

      // 4 joints per finger
      for (int j = 1; j <= 4; j++) {
        final distance = handSize * 0.1 * j;
        final x = (centerX + distance * cos(angle)) * imageWidth;
        final y = (centerY + distance * sin(angle)) * imageHeight;

        final normX = (x / imageWidth).clamp(0.0, 1.0);
        final normY = (y / imageHeight).clamp(0.0, 1.0);

        joints.add(HandJoint(
          position: Offset(normX, normY),
          name: '$fingerName-$j',
          confidence: confidence *
              (1 - j * 0.1), // Decrease confidence for further joints
        ));
      }
    }

    return joints.length >= 20 ? joints.sublist(0, 20) : joints;
  }

  /// Generate default hand joints if hand not detected
  List<HandJoint> _generateDefaultJoints() {
    return List.generate(20, (i) {
      return HandJoint(
        position: Offset(0.5, 0.5),
        name: 'joint-$i',
        confidence: 0.0,
      );
    });
  }

  /// Calculate motion features from hand joints
  List<double> _calculateMotionFeatures(List<HandJoint> joints) {
    // Feature 1: Average joint confidence
    final avgConfidence = joints.isEmpty
        ? 0.0
        : joints.map((j) => j.confidence).reduce((a, b) => a + b) /
            joints.length;

    // Feature 2: Hand spread (distance between min/max x,y)
    double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    for (final joint in joints) {
      minX = minX < joint.position.dx ? minX : joint.position.dx;
      maxX = maxX > joint.position.dx ? maxX : joint.position.dx;
      minY = minY < joint.position.dy ? minY : joint.position.dy;
      maxY = maxY > joint.position.dy ? maxY : joint.position.dy;
    }
    final spread = ((maxX - minX) + (maxY - minY)) / 2;

    // Feature 3: Hand centroid (used for motion tracking)
    double centroidX = 0;
    for (final joint in joints) {
      centroidX += joint.position.dx;
    }
    if (joints.isNotEmpty) {
      centroidX /= joints.length;
    }

    return [avgConfidence, spread, centroidX];
  }

  /// Create hand skeleton from joints for visualization
  HandSkeleton _createHandSkeleton(List<double> landmarks) {
    final joints = <HandJoint>[];

    // Parse landmarks: 20 joints * 3 features (x, y, confidence) = 60 values
    for (int i = 0; i < 20 && i * 3 + 2 < landmarks.length; i++) {
      final x = landmarks[i * 3].clamp(0.0, 1.0);
      final y = landmarks[i * 3 + 1].clamp(0.0, 1.0);
      final confidence = landmarks[i * 3 + 2].clamp(0.0, 1.0);

      joints.add(HandJoint(
        position: Offset(x, y),
        name: 'joint-$i',
        confidence: confidence,
      ));
    }

    return HandSkeleton(joints: joints);
  }

  /// Reset extractor state
  void reset() {
    clearBuffer();
  }
}

/// Extension for CameraImage to simulate frame processing
extension CameraImageExtension on CameraImage {
  // This would be where actual camera frame processing happens
  // For now it's a placeholder
}
