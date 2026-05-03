import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:kumpas/presentation/providers/enhanced_camera_provider.dart';
import 'package:kumpas/presentation/widgets/hand_joint_painter.dart';
import 'package:kumpas/presentation/widgets/gesture_result_display.dart';
import 'package:kumpas/theme/app_theme.dart';

class GestureRecognitionScreen extends StatefulWidget {
  const GestureRecognitionScreen({super.key});

  @override
  State<GestureRecognitionScreen> createState() =>
      _GestureRecognitionScreenState();
}

class _GestureRecognitionScreenState extends State<GestureRecognitionScreen>
    with WidgetsBindingObserver {
  bool get _isCameraSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isCameraSupported) {
      _initializeCamera();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Live gesture recognition requires a mobile device.'),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<EnhancedCameraProvider>().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<EnhancedCameraProvider>();
    switch (state) {
      case AppLifecycleState.resumed:
        if (provider.isInitialized && !provider.isRecognizing) {
          provider.startRecognition();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (provider.isRecognizing) provider.stopRecognition();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) _showCameraError('No camera found on this device.');
        return;
      }
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      if (mounted) {
        final provider = context.read<EnhancedCameraProvider>();
        await provider.initializeCamera(frontCamera);
        await provider.startRecognition();
      }
    } catch (_) {
      if (mounted) {
        _showCameraError('Unable to access camera. Please check permissions.');
      }
    }
  }

  void _showCameraError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Gesture Recognition'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<EnhancedCameraProvider>(
        builder: (context, provider, _) {
          if (!provider.isInitialized) {
            return _buildLoadingState(provider);
          }
          if (provider.cameraController == null) {
            return _buildUnavailableState();
          }
          return _buildCameraView(provider);
        },
      ),
    );
  }

  Widget _buildLoadingState(EnhancedCameraProvider provider) {
    if (!_isCameraSupported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam_off_rounded,
                    size: 40, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera not available',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gesture recognition requires a physical mobile device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          const Text(
            'Starting camera…',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unable to access camera. Check permissions.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnavailableState() {
    return const Center(
      child: Text(
        'Camera unavailable',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCameraView(EnhancedCameraProvider provider) {
    return Column(
      children: [
        // Camera section — flexible, fills most of screen
        Expanded(
          flex: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(provider.cameraController!),
              HandJointOverlay(
                skeleton: provider.handSkeleton,
                jointColor: AppColors.primary,
                lineColor: Colors.white,
                jointRadius: 5.0,
              ),
              // AI status pill — top left
              Positioned(
                top: 12,
                left: 12,
                child: _AiStatusPill(isActive: provider.isRecognizing),
              ),
              // Hand framing guide — subtle corner brackets
              const Positioned.fill(child: _FramingGuide()),
            ],
          ),
        ),

        // Results panel
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: GestureResultDisplay(
                      result: provider.currentResult,
                      isProcessing: provider.isProcessing,
                      errorMessage: provider.errorMessage,
                      onDismiss: provider.clearResult,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildControls(provider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(EnhancedCameraProvider provider) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: provider.isRecognizing
                ? provider.stopRecognition
                : provider.startRecognition,
            icon: Icon(
              provider.isRecognizing
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(provider.isRecognizing ? 'Stop' : 'Start'),
            style: FilledButton.styleFrom(
              backgroundColor:
                  provider.isRecognizing ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                provider.isRecognizing ? provider.captureGesture : null,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Capture'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Top-left status indicator pill
class _AiStatusPill extends StatelessWidget {
  final bool isActive;
  const _AiStatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.confidenceHigh.withValues(alpha: 0.6)
              : AppColors.textHint.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive ? AppColors.confidenceHigh : AppColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'AI Active' : 'AI Paused',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle corner brackets to guide hand placement
class _FramingGuide extends StatelessWidget {
  const _FramingGuide();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornerBracketPainter());
  }
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 40.0;
    const len = 24.0;

    // Top-left
    canvas.drawLine(const Offset(margin, margin + len), const Offset(margin, margin), paint);
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + len, margin), paint);
    // Top-right
    canvas.drawLine(
        Offset(size.width - margin, margin + len),
        Offset(size.width - margin, margin),
        paint);
    canvas.drawLine(
        Offset(size.width - margin, margin),
        Offset(size.width - margin - len, margin),
        paint);
    // Bottom-left
    canvas.drawLine(
        Offset(margin, size.height - margin - len),
        Offset(margin, size.height - margin),
        paint);
    canvas.drawLine(
        Offset(margin, size.height - margin),
        Offset(margin + len, size.height - margin),
        paint);
    // Bottom-right
    canvas.drawLine(
        Offset(size.width - margin, size.height - margin - len),
        Offset(size.width - margin, size.height - margin),
        paint);
    canvas.drawLine(
        Offset(size.width - margin, size.height - margin),
        Offset(size.width - margin - len, size.height - margin),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
