import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/camera_provider.dart';
import 'presentation/providers/enhanced_camera_provider.dart';
import 'presentation/screens/main_app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedCameraProvider()),
      ],
      child: MaterialApp(
        title: 'Kumpas - Filipino Sign Language Learning',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainAppShell(),
      ),
    );
  }
}
