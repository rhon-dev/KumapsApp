import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:kumpas/presentation/providers/camera_provider.dart';
import 'package:kumpas/presentation/widgets/camera_feedback_overlay.dart';
import 'package:kumpas/presentation/screens/gesture_recognition_screen.dart';
import 'package:kumpas/theme/app_theme.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({Key? key}) : super(key: key);

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with WidgetsBindingObserver {
  bool _isTranslating = false;
  String _translatedText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    final cameraProvider = context.read<CameraProvider>();

    switch (state) {
      case AppLifecycleState.resumed:
        if (_isTranslating && cameraProvider.isInitialized) {
          cameraProvider.startCameraPreview();
        }
        break;
      case AppLifecycleState.paused:
        if (_isTranslating) {
          cameraProvider.stopCameraPreview();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, _) {
        if (!_isTranslating) {
          return _buildSelectionMode(context, cameraProvider);
        }

        if (!cameraProvider.isInitialized ||
            cameraProvider.cameraController == null) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return _buildTranslateMode(context, cameraProvider);
      },
    );
  }

  Widget _buildSelectionMode(
    BuildContext context,
    CameraProvider cameraProvider,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Translate'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Translate Filipino Sign Language',
                style: AppTypography.headlineMedium(context),
              ),
              const SizedBox(height: 8),
              Text(
                'Convert sign language to text or text to sign in real-time',
                style: AppTypography.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Mode Selection Cards
              _buildTranslationModeCard(
                context: context,
                title: 'Sign to Text',
                description:
                    'Let the camera understand your signs and translate to text',
                icon: Icons.videocam_outlined,
                color: AppColors.primary,
                onTap: () async {
                  await _initializeAndStartTranslate(cameraProvider);
                },
              ),
              const SizedBox(height: 16),
              _buildTranslationModeCard(
                context: context,
                title: 'Gesture Recognition',
                description:
                    'Real-time hand gesture recognition with AI feedback',
                icon: Icons.pan_tool_outlined,
                color: const Color(0xFF9C27B0),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GestureRecognitionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTranslationModeCard(
                context: context,
                title: 'Text to Sign',
                description: 'Type text and see how to sign it',
                icon: Icons.keyboard_outlined,
                color: AppColors.secondary,
                onTap: () {
                  _showTextInputDialog(context);
                },
              ),
              const SizedBox(height: 32),

              // Quick Phrases
              Text(
                'Quick Phrases',
                style: AppTypography.titleMedium(context),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Hello',
                  'Thank you',
                  'Good morning',
                  'How are you?',
                  'Goodbye',
                  'Help',
                ]
                    .map(
                      (phrase) => ActionChip(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Showing: $phrase')),
                          );
                        },
                        label: Text(phrase),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: AppTypography.labelMedium(context).copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeAndStartTranslate(
      CameraProvider cameraProvider) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        if (mounted) {
          await cameraProvider.initializeCamera(frontCamera);
          setState(() {
            _isTranslating = true;
            _translatedText = '';
          });
          await cameraProvider.startCameraPreview();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Widget _buildTranslateMode(
    BuildContext context,
    CameraProvider cameraProvider,
  ) {
    final controller = cameraProvider.cameraController!;
    final screenSize = MediaQuery.of(context).size;
    final cameraAspectRatio = controller.value.aspectRatio;

    return Stack(
      children: [
        // Camera preview
        Container(
          color: Colors.black,
          child: Center(
            child: Transform.scale(
              scale: screenSize.width / (screenSize.height * cameraAspectRatio),
              child: CameraPreview(controller),
            ),
          ),
        ),

        // AI Overlay
        IgnorePointer(
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: CameraFeedbackOverlay(
              frameSize: Size(screenSize.width, screenSize.height),
              showLandmarks: true,
              showFeedback: true,
            ),
          ),
        ),

        // Top Bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        await cameraProvider.stopCameraPreview();
                        if (mounted) {
                          setState(() => _isTranslating = false);
                        }
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LIVE TRANSLATION',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
        ),

        // Translation Result Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Sign',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _translatedText.isEmpty
                          ? 'Waiting for sign...'
                          : _translatedText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTextInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text to Sign'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter text to translate...',
          ),
          onChanged: (value) {
            setState(() => _translatedText = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Showing sign for: $_translatedText'),
                ),
              );
            },
            child: const Text('Show Sign'),
          ),
        ],
      ),
    );
  }
}
