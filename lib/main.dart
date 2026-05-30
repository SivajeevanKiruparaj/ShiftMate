import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_check_screen.dart';
//import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //await NotificationService.init();

  runApp(const ShiftMateApp());
}

class ShiftMateApp extends StatelessWidget {
  const ShiftMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FBFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4DA6FF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4DA6FF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthCheckScreen(),
    );
  }
}