import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:CycleX/themeprovider/themeprovider.dart';
import 'package:CycleX/Config/AllTitles.dart';
import 'package:CycleX/Config/routes/OneGenerateRoute.dart';
import 'package:CycleX/Config/routes/PageConstants.dart';
import 'package:CycleX/services/api_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize ApiService
  ApiService.initialize('https://cycle-x-backend.vercel.app/api');
  
  // Create userService instance
  final userService = UserService(ApiService.instance);
  
  runApp(MyApp(userService: userService));
}

class MyApp extends StatelessWidget {
  final UserService userService;
  
  const MyApp({super.key, required this.userService});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AllTitles.appTitle,
      themeMode: ThemeMode.system,
      theme: Mytheme.lightTheme,
      darkTheme: Mytheme.darkTheme,
      initialRoute: PageConstants.splashScreen,
      onGenerateRoute: OneGeneralRoute.routes,
    );
  }
}
