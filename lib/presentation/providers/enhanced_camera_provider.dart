import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kumpas/services/gesture_service.dart';
import 'package:kumpas/services/landmark_extractor.dart';
import 'package:kumpas/presentation/widgets/gesture_result_display.dart';
import 'package:kumpas/presentation/widgets/hand_joint_painter.dart';

/// Enhanced camera provider with gesture recognition
class EnhancedCameraProvider extends ChangeNotifier {
  // Camera components
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isRecognizing = false;

  // Gesture recognition components
  final GestureService gestureService;
  final LandmarkExtractor landmarkExtractor;

  // Recognition state
  GestureResult? _currentResult;
  String? _errorMessage;
  bool _isProcessing = false;
  double _fps = 0.0;
  int _frameCount = 0;
  DateTime? _lastFpsUpdate;

  // Hand visualization
  HandSkeleton? _handSkeleton;

  // Timing
  static const int frameProcessInterval = 100; // ms between frame processing
  DateTime? _lastFrameProcessed;

  // Getters
  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isRecognizing => _isRecognizing;
  GestureResult? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;
  double get fps => _fps;
  HandSkeleton? get handSkeleton => _handSkeleton;

  EnhancedCameraProvider({GestureService? service})
      : gestureService =
            service ?? GestureService(apiUrl: 'http://localhost:5001'),
        landmarkExtractor = LandmarkExtractor();

  /// Initialize camera with description
  Future<void> initializeCamera(CameraDescription cameraDescription) async {
    try {
      _cameraController = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      _errorMessage = null;
      notifyListeners();

      // Verify Flask connection
      await _verifyFlaskConnection();
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      _isInitialized = false;
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  /// Verify Flask API is reachable
  Future<void> _verifyFlaskConnection() async {
    try {
      final isHealthy = await gestureService.isHealthy();
      if (!isHealthy) {
        _errorMessage = 'Flask API not responding on localhost:5001';
      }
    } catch (e) {
      _errorMessage = 'Cannot connect to Flask: $e';
    }
    notifyListeners();
  }

  /// Start gesture recognition
  Future<void> startRecognition() async {
    if (!_isInitialized || _cameraController == null) {
      _errorMessage = 'Camera not initialized';
      notifyListeners();
      return;
    }

    try {
      _isRecognizing = true;
      _errorMessage = null;
      landmarkExtractor.reset();
      _currentResult = null;
      _frameCount = 0;
      _lastFpsUpdate = DateTime.now();

      await _cameraController!.startImageStream(_processFrame);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start recognition: $e';
      _isRecognizing = false;
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  /// Stop gesture recognition
  Future<void> stopRecognition() async {
    if (_cameraController != null && _isRecognizing) {
      try {
        await _cameraController!.stopImageStream();
        _isRecognizing = false;
        landmarkExtractor.reset();
        _handSkeleton = null;
        _fps = 0.0;
        _frameCount = 0;
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Failed to stop recognition: $e';
        debugPrint(_errorMessage);
        notifyListeners();
      }
    }
  }

  /// Process each camera frame
  Future<void> _processFrame(CameraImage image) async {
    if (!_isRecognizing) return;

    try {
      // Throttle frame processing
      final now = DateTime.now();
      if (_lastFrameProcessed != null &&
          now.difference(_lastFrameProcessed!).inMilliseconds <
              frameProcessInterval) {
        return;
      }
      _lastFrameProcessed = now;

      // Update FPS
      _frameCount++;
      if (_lastFpsUpdate != null) {
        final elapsed = now.difference(_lastFpsUpdate!).inMilliseconds;
        if (elapsed >= 1000) {
          _fps = _frameCount / (elapsed / 1000);
          _frameCount = 0;
          _lastFpsUpdate = now;
          notifyListeners();
        }
      }

      // Extract landmarks from frame
      _handSkeleton = await landmarkExtractor.processFrame(image);
      notifyListeners();

      // Get buffered landmarks
      if (landmarkExtractor.isBufferFull) {
        await _sendLandmarksToFlask();
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    }
  }

  /// Send buffered landmarks to Flask API
  Future<void> _sendLandmarksToFlask() async {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final landmarks = landmarkExtractor.getBufferedLandmarks();

      final result = await gestureService.predict(landmarks);

      _currentResult = GestureResult(
        sign: result.sign,
        confidence: (result.confidence * 100).toDouble(),
        probabilities: result.probabilities.map(
          (k, v) => MapEntry(k, v),
        ),
        warning: result.warning,
      );

      // Clear buffer after successful prediction
      landmarkExtractor.clearBuffer();

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to predict gesture: $e';
      _isProcessing = false;
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  /// Manual gesture capture (for single-frame recognition)
  Future<void> captureGesture() async {
    if (!_isRecognizing) {
      _errorMessage = 'Recognition not started';
      notifyListeners();
      return;
    }

    await _sendLandmarksToFlask();
  }

  /// Clear current result
  void clearResult() {
    _currentResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Dispose resources
  @override
  Future<void> dispose() async {
    if (_isRecognizing) {
      await stopRecognition();
    }
    await _cameraController?.dispose();
    super.dispose();
  }
}
