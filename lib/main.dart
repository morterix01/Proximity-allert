import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final StorageService storage = StorageService();
  await storage.init();

  if (!kIsWeb) {
    await AppBackgroundService.initializeService();
  }

  runApp(const ProximityApp());
}

class ProximityApp extends StatelessWidget {
  const ProximityApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp(
      title: 'Proximity Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        fontFamily: 'Inter', // Custom font non incluso ma fallback a sys font
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FF),
          secondary: Color(0xFFFF4D4D),
        ),
      ),
      home: const SplashScreen(),
    );

    if (kIsWeb) {
      return Container(
        color: const Color(0xFF12121A), // Web browser dark background
        child: Center(
          child: Container(
            width: 390,
            height: 844,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFF333333), width: 8), // iPhone bezel
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: app,
            ),
          ),
        ),
      );
    }

    return app;
  }
}
