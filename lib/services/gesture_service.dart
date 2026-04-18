import 'dart:convert';
import 'package:http/http.dart' as http;

class GestureService {
  final String apiUrl;

  // Default Flask server endpoint
  static const String defaultApiUrl = 'http://localhost:5001';

  GestureService({String? apiUrl}) : apiUrl = apiUrl ?? defaultApiUrl;

  /// Check if the API server is reachable
  Future<bool> isHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Get API information (signs, model details, etc.)
  Future<Map<String, dynamic>> getInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/info'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get API info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting API info: $e');
      rethrow;
    }
  }

  /// Predict gesture from hand landmarks
  ///
  /// Parameters:
  ///   - landmarks: List of 1,890 float values
  ///     (30 frames × 63 features per frame)
  ///
  /// Returns: Map with keys:
  ///   - sign: Recognized gesture name
  ///   - label: Numeric label (0-4)
  ///   - confidence: Float 0-1 (or 0-100%)
  ///   - probabilities: Map of all sign probabilities
  ///   - warning: Optional warning message
  Future<PredictionResult> predict(List<double> landmarks) async {
    if (landmarks.length != 1890) {
      throw ArgumentError('Expected 1890 landmarks, got ${landmarks.length}');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'landmarks': landmarks}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PredictionResult.fromJson(data);
      } else {
        throw Exception(
            'Prediction failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error predicting gesture: $e');
      rethrow;
    }
  }
}

/// Result of a gesture prediction
class PredictionResult {
  final String sign;
  final int label;
  final double confidence;
  final Map<String, double> probabilities;
  final String? warning;

  PredictionResult({
    required this.sign,
    required this.label,
    required this.confidence,
    required this.probabilities,
    this.warning,
  });

  /// Parse prediction result from API response
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      sign: json['sign'] as String,
      label: json['label'] as int,
      confidence: (json['confidence'] is int)
          ? (json['confidence'] as int).toDouble()
          : json['confidence'] as double,
      probabilities: Map<String, double>.from(
        (json['probabilities'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      warning: json['warning'] as String?,
    );
  }

  /// Check if confidence is acceptable (>70%)
  bool get isHighConfidence => confidence > 0.70;

  @override
  String toString() =>
      'PredictionResult(sign=$sign, confidence=$confidence, warning=$warning)';
}
