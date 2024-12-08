import 'package:flutter/material.dart';
import 'package:cyclex_hub/Config/AllTitles.dart';
import 'package:cyclex_hub/Config/routes/OneGenerateRoute.dart';
import 'package:cyclex_hub/view/SplashScreen.dart';
import 'package:cyclex_hub/view/HomeScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AllTitles.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/', // Default to SplashScreen
      routes: {
        '/': (context) => const SplashScreen(), // SplashScreen route
        '/homeScreen': (context) => const Homescreen(), // HomeScreen route
      },
      onGenerateRoute: OneGeneralRoute.routes, // Handle dynamic routes
    );
  }
}
