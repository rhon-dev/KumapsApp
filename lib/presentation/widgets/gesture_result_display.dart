import 'package:flutter/material.dart';

/// Model for gesture prediction result
class GestureResult {
  final String sign;
  final double confidence; // 0-1 or 0-100
  final Map<String, double> probabilities;
  final String? warning;
  final DateTime timestamp;

  GestureResult({
    required this.sign,
    required this.confidence,
    required this.probabilities,
    this.warning,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Confidence as percentage (0-100)
  double get confidencePercent =>
      confidence > 1.0 ? confidence : confidence * 100;

  /// Get confidence color
  Color getConfidenceColor() {
    final percent = confidencePercent;
    if (percent >= 70) {
      return const Color(0xFF4CAF50); // Green
    } else if (percent >= 40) {
      return const Color(0xFFFFC107); // Yellow
    } else {
      return const Color(0xFFF44336); // Red
    }
  }

  /// Check if confidence is high enough
  bool get isHighConfidence => confidencePercent >= 70;
}

/// Widget for displaying gesture recognition result
class GestureResultDisplay extends StatefulWidget {
  final GestureResult? result;
  final bool isProcessing;
  final String? errorMessage;
  final VoidCallback onDismiss;

  const GestureResultDisplay({
    Key? key,
    this.result,
    this.isProcessing = false,
    this.errorMessage,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<GestureResultDisplay> createState() => _GestureResultDisplayState();
}

class _GestureResultDisplayState extends State<GestureResultDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(GestureResultDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation when result changes
    if (oldWidget.result != widget.result && widget.result != null) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null) {
      return _buildErrorDisplay();
    }

    if (widget.isProcessing) {
      return _buildProcessingDisplay();
    }

    if (widget.result == null) {
      return _buildEmptyDisplay();
    }

    return _buildResultDisplay();
  }

  /// Display error message
  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade400, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onDismiss,
                color: Colors.red.shade700,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.errorMessage ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Display processing state
  Widget _buildProcessingDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recognizing gesture...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Display empty state
  Widget _buildEmptyDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waiting for gesture...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Position your hand in front of the camera and perform a gesture',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Display prediction result
  Widget _buildResultDisplay() {
    final result = widget.result!;
    final confidenceColor = result.getConfidenceColor();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: confidenceColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: confidenceColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with sign name and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recognized Sign',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Sign name (large)
              Text(
                result.sign,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Confidence bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Confidence',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${result.confidencePercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: confidenceColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: result.confidence / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(confidenceColor),
                    ),
                  ),
                ],
              ),

              // Warning if low confidence
              if (result.warning != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.warning!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Probability breakdown
              if (result.probabilities.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'All Probabilities',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildProbabilityBars(result.probabilities),
              ],

              // Timestamp
              const SizedBox(height: 12),
              Text(
                'Recognized at ${result.timestamp.hour.toString().padLeft(2, '0')}:${result.timestamp.minute.toString().padLeft(2, '0')}:${result.timestamp.second.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build probability bars for each sign
  List<Widget> _buildProbabilityBars(Map<String, double> probabilities) {
    return probabilities.entries.map((entry) {
      final sign = entry.key;
      final probability = entry.value;
      final percentStr = '${(probability * 100).toStringAsFixed(0)}%';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sign,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  percentStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: probability,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  Color.lerp(
                    Colors.red.shade400,
                    Colors.green.shade400,
                    probability,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
