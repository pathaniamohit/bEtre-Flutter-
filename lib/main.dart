import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('Firebase Initialized Successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bEtre',
      theme: ThemeData(
        fontFamily: 'RobotoSerif',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'RobotoSerif', fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontFamily: 'RobotoSerif', fontWeight: FontWeight.w400),
          displayLarge: TextStyle(fontFamily: 'RobotoSerif', fontWeight: FontWeight.w400),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
