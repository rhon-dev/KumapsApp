import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:kumpas/presentation/providers/enhanced_camera_provider.dart';
import 'package:kumpas/presentation/widgets/hand_joint_painter.dart';
import 'package:kumpas/presentation/widgets/gesture_result_display.dart';

/// Main gesture recognition camera screen
class GestureRecognitionScreen extends StatefulWidget {
  const GestureRecognitionScreen({super.key});

  @override
  State<GestureRecognitionScreen> createState() =>
      _GestureRecognitionScreenState();
}

class _GestureRecognitionScreenState extends State<GestureRecognitionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final provider = context.read<EnhancedCameraProvider>();
    provider.dispose();
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
        if (provider.isRecognizing) {
          provider.stopRecognition();
        }
        break;
      default:
        break;
    }
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
        return;
      }

      // Use front camera for gesture recognition
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (mounted) {
        final provider = context.read<EnhancedCameraProvider>();
        await provider.initializeCamera(frontCamera);
        await provider.startRecognition();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture Recognition'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<EnhancedCameraProvider>(
        builder: (context, provider, _) {
          if (!provider.isInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Initializing camera...'),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          if (provider.cameraController == null) {
            return const Center(child: Text('Camera not available'));
          }

          return Stack(
            children: [
              // Camera preview (80% of screen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Container(
                  color: Colors.black,
                  child: CameraPreview(provider.cameraController!),
                ),
              ),

              // Hand joint overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.7,
                child: HandJointOverlay(
                  skeleton: provider.handSkeleton,
                  jointColor: Colors.blue,
                  lineColor: Colors.white,
                  jointRadius: 5.0,
                ),
              ),

              // FPS counter
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'FPS: ${provider.fps.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Recognition controls and results (20% of screen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.3,
                child: Container(
                  color: Colors.grey.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gesture result display
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
                      const SizedBox(height: 16),

                      // Control buttons
                      Row(
                        children: [
                          // Start/Stop button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: provider.isRecognizing
                                  ? () => provider.stopRecognition()
                                  : () => provider.startRecognition(),
                              icon: Icon(
                                provider.isRecognizing
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                provider.isRecognizing ? 'Stop' : 'Start',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: provider.isRecognizing
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Capture button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: provider.isRecognizing
                                  ? () => provider.captureGesture()
                                  : null,
                              icon: const Icon(Icons.camera),
                              label: const Text('Capture'),
                            ),
                          ),
                        ],
                      ),

                      // Status indicators
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Recognition status
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: provider.isRecognizing
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.isRecognizing
                                    ? 'Recognition: Active'
                                    : 'Recognition: Stopped',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),

                          // Flask connection status
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: provider.errorMessage == null
                                      ? Colors.green
                                      : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.errorMessage == null
                                    ? 'Flask: Connected'
                                    : 'Flask: Error',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
