import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cyclex_go/themeprovider/themeprovider.dart';
import 'package:cyclex_go/Config/AllTitles.dart';
import 'package:cyclex_go/Config/routes/OneGenerateRoute.dart';
import 'package:cyclex_go/view/SplashScreen.dart';
import 'package:cyclex_go/view/HomeScreen.dart';
import 'package:cyclex_go/view/register_screen.dart';
import 'package:cyclex_go/view/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AllTitles.appTitle,
      themeMode: ThemeMode.system,
      theme: Mytheme.lightTheme,
      darkTheme: Mytheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/homeScreen': (context) => const Homescreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
      onGenerateRoute: OneGeneralRoute.routes,
    );
  }
}
