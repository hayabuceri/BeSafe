import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD4h_fcf6N5VOI7Y2dJUNJCHyN5AWn2kj4",
        appId: "1:1009109940622:android:084b511ee43ba0e6cc2036",
        messagingSenderId: "1009109940622",
        projectId: "besafe-116f5",
        storageBucket: "besafe-116f5.appspot.com",
      ),
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Failed to initialize Firebase: $e");
    // Continue execution even if Firebase fails
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeSafe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
