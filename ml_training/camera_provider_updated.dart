import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_hand_pose_detection/google_mlkit_hand_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:kumpas/models/learning_models.dart';
import 'dart:convert';

/// Camera provider with hand gesture recognition using TFLite
class CameraProviderWithGestures extends ChangeNotifier {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isCameraRunning = false;
  List<PoseLandmark> _currentLandmarks = [];
  List<AIFeedback> _activeFeedbacks = [];

  // Gesture recognition
  late HandPoseDetector _handDetector;
  late Interpreter _modelInterpreter;
  late Map<String, dynamic> _signMapping;

  String _recognizedSign = '';
  double _recognitionConfidence = 0.0;
  List<List<double>> _landmarkSequence = [];

  static const int SEQUENCE_LENGTH = 30;
  static const int NUM_LANDMARKS = 21;
  static const int COORDS_PER_LANDMARK = 3;

  // Getters
  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isCameraRunning => _isCameraRunning;
  List<PoseLandmark> get currentLandmarks => _currentLandmarks;
  List<AIFeedback> get activeFeedbacks => _activeFeedbacks;
  String get recognizedSign => _recognizedSign;
  double get recognitionConfidence => _recognitionConfidence;

  /// Initialize camera and AI models
  Future<void> initializeCamera(CameraDescription cameraDescription) async {
    try {
      _cameraController = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      // Initialize hand gesture recognition
      await _initializeGestureRecognition();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  /// Initialize hand detection and TFLite model
  Future<void> _initializeGestureRecognition() async {
    try {
      // Initialize hand pose detector
      _handDetector = HandPoseDetector();

      // Load TFLite model
      _modelInterpreter = await Interpreter.fromAsset(
        'models/gesture_model.tflite',
      );

      // Load sign mapping
      final mappingJson = await DefaultAssetBundle.of(_context).loadString(
        'models/sign_mapping.json',
      );
      _signMapping = jsonDecode(mappingJson);

      debugPrint('✅ Gesture recognition initialized');
      debugPrint(
          'Available signs: ${_signMapping['label_to_sign'].values.toList()}');
    } catch (e) {
      debugPrint('Error initializing gesture recognition: $e');
      rethrow;
    }
  }

  /// Start camera preview for practice/translation
  Future<void> startCameraPreview() async {
    if (!_isInitialized || _cameraController == null) {
      return;
    }
    try {
      await _cameraController!.startImageStream(_processFrame);
      _isCameraRunning = true;
      _landmarkSequence = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting camera preview: $e');
    }
  }

  /// Stop camera preview
  Future<void> stopCameraPreview() async {
    if (_cameraController != null && _isCameraRunning) {
      try {
        await _cameraController!.stopImageStream();
        _isCameraRunning = false;
        _currentLandmarks.clear();
        _activeFeedbacks.clear();
        _landmarkSequence = [];
        _recognizedSign = '';
        _recognitionConfidence = 0.0;
        notifyListeners();
      } catch (e) {
        debugPrint('Error stopping camera preview: $e');
      }
    }
  }

  /// Process each frame from camera stream
  Future<void> _processFrame(CameraImage image) async {
    if (!_isCameraRunning) return;

    try {
      // Detect hand landmarks
      final handPoses = await _handDetector.processImage(image);

      if (handPoses.isNotEmpty) {
        final primaryHand = handPoses[0];

        // Convert hand landmarks to model input format
        final frameLandmarks = _extractLandmarkFeatures(primaryHand.landmarks);
        _landmarkSequence.add(frameLandmarks);

        // Keep only last SEQUENCE_LENGTH frames
        if (_landmarkSequence.length > SEQUENCE_LENGTH) {
          _landmarkSequence.removeAt(0);
        }

        // Update current landmarks for visualization
        _updatePoseLandmarks(primaryHand.landmarks);

        // Run gesture recognition if we have enough frames
        if (_landmarkSequence.length == SEQUENCE_LENGTH) {
          await _runGestureRecognition();
        }

        notifyListeners();
      } else {
        // No hands detected
        _currentLandmarks.clear();
        _landmarkSequence = [];
        _recognizedSign = '';
        _recognitionConfidence = 0.0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    }
  }

  /// Extract landmark features (x, y, z) in normalized format
  List<double> _extractLandmarkFeatures(List<HandLandmark> landmarks) {
    List<double> features = [];

    for (var landmark in landmarks) {
      features.add(landmark.x);
      features.add(landmark.y);
      features.add(landmark.z);
    }

    return features;
  }

  /// Convert hand landmarks to pose landmarks for visualization
  void _updatePoseLandmarks(List<HandLandmark> handLandmarks) {
    _currentLandmarks = [
      PoseLandmark(
        name: 'wrist',
        x: handLandmarks[0].x,
        y: handLandmarks[0].y,
        z: handLandmarks[0].z,
        visibility: 0.95,
      ),
      // Add more landmarks as needed for visualization
      ...handLandmarks
          .asMap()
          .entries
          .map((e) => PoseLandmark(
                name: 'hand_landmark_${e.key}',
                x: e.value.x,
                y: e.value.y,
                z: e.value.z,
                visibility: 0.9,
              ))
          .toList(),
    ];
  }

  /// Run TFLite inference on landmark sequence
  Future<void> _runGestureRecognition() async {
    try {
      // Prepare input: (1, SEQUENCE_LENGTH, 63)
      // 1 = batch size, SEQUENCE_LENGTH = frames, 63 = 21 landmarks × 3 coords
      final input = _landmarkSequence.reshape([1, SEQUENCE_LENGTH, 21 * 3]);

      // Prepare output: (1, 5) for 5 signs
      final output = List<double>(5).reshape([1, 5]);

      // Run inference
      _modelInterpreter.run(input, output);

      // Process results
      final predictions = output[0];
      _processGesturePredictions(predictions);
    } catch (e) {
      debugPrint('Error running gesture recognition: $e');
    }
  }

  /// Process gesture recognition predictions
  void _processGesturePredictions(List<dynamic> predictions) {
    // Convert to double list
    final probs = predictions.cast<double>().toList();

    // Find max probability and index
    double maxProb = 0;
    int maxIndex = 0;

    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIndex = i;
      }
    }

    // Only recognize if confidence is above threshold
    const double confidenceThreshold = 0.7;

    if (maxProb > confidenceThreshold) {
      final signLabel = _signMapping['label_to_sign'][maxIndex.toString()];

      // Only update if sign changed (to avoid constant updates)
      if (signLabel != _recognizedSign) {
        _recognizedSign = signLabel;
        _recognitionConfidence = maxProb;

        // Add feedback
        addFeedback(AIFeedback(
          feedbackId: 'gesture_${DateTime.now().millisecondsSinceEpoch}',
          type: 'recognition',
          message:
              'Recognized: $_recognizedSign (${(_recognitionConfidence * 100).toStringAsFixed(1)}%)',
          confidence: maxProb,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));

        debugPrint(
            '✅ Recognized: $_recognizedSign (${maxProb.toStringAsFixed(2)})');
      }
    } else {
      _recognizedSign = '';
      _recognitionConfidence = 0.0;
    }

    notifyListeners();
  }

  /// Add new feedback (from ML model)
  void addFeedback(AIFeedback feedback) {
    _activeFeedbacks.add(feedback);
    notifyListeners();

    // Auto-remove feedback after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_activeFeedbacks.contains(feedback)) {
        _activeFeedbacks.remove(feedback);
        notifyListeners();
      }
    });
  }

  /// Clear all feedbacks
  void clearFeedbacks() {
    _activeFeedbacks.clear();
    notifyListeners();
  }

  /// Placeholder for context (will be injected from Flutter)
  late BuildContext _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  /// Dispose camera controller and models
  @override
  void dispose() {
    _cameraController?.dispose();
    _handDetector.close();
    _modelInterpreter.close();
    super.dispose();
  }
}

/// Extension to reshape lists like numpy
extension ListReshape on List {
  List reshape(List<int> shape) {
    if (shape.length == 1) return this;

    final size = shape[0];
    final subShape = shape.sublist(1);
    final subSize = subShape.reduce((a, b) => a * b);

    List result = [];
    for (int i = 0; i < size; i++) {
      result.add(sublist(i * subSize, (i + 1) * subSize).reshape(subShape));
    }
    return result;
  }
}
