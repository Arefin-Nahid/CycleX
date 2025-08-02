import 'package:flutter/material.dart';
import 'package:CycleX/Config/routes/PageConstants.dart';
import 'package:CycleX/view/ErrorScreen.dart';
import 'package:CycleX/view/HomeScreen.dart';
import 'package:CycleX/view/SplashScreen.dart';
import 'package:CycleX/authentication/login_screen.dart';
import 'package:CycleX/authentication/register_screen.dart';
import 'package:CycleX/authentication/user_details_screen.dart';
import 'package:CycleX/view/RoleSelectionScreen.dart';
import 'package:CycleX/view/OwnerDashboard.dart';
import 'package:CycleX/view/RenterDashboard.dart';
import 'package:CycleX/view/MapView.dart';
import 'package:CycleX/view/ProfileScreen.dart';
import 'package:CycleX/view/EditProfileScreen.dart';
import 'package:CycleX/view/NotificationsScreen.dart';
import 'package:CycleX/view/SecurityScreen.dart';
import 'package:CycleX/view/HelpSupportScreen.dart';
import 'package:CycleX/view/history_screen.dart';
import 'package:CycleX/view/QRScannerScreen.dart';

class OneGeneralRoute {
  static Route<dynamic> routes(RouteSettings settings) {
    // Extract arguments if they exist
    final args = settings.arguments;

    switch (settings.name) {
      case PageConstants.splashScreen:
        return materialPageRoute(widget: const SplashScreen());
        
      case PageConstants.loginScreen:
        return materialPageRoute(widget: const LoginScreen());
        
      case PageConstants.registerScreen:
        return materialPageRoute(widget: const RegisterScreen());
        
      case PageConstants.homeScreen:
        return materialPageRoute(widget: const Homescreen());
        
      case PageConstants.userDetailsScreen:
        if (args is Map<String, dynamic>) {
          return materialPageRoute(
            widget: UserDetailsScreen(
              uid: args['uid'] as String,
              email: args['email'] as String,
              name: args['name'] as String,
            ),
          );
        }
        return _errorRoute();
        
      case PageConstants.ownerDashboardScreen:
        return materialPageRoute(widget: const OwnerDashboard());
        
      case PageConstants.renterDashboardScreen:
        return materialPageRoute(widget: const RenterDashboard());
        
      case PageConstants.mapViewScreen:
        return materialPageRoute(widget: const MapView());
        
      case PageConstants.profileScreen:
        return materialPageRoute(widget: const ProfileScreen());
        
      case PageConstants.editProfileScreen:
        return materialPageRoute(widget: const EditProfileScreen());
        
      case PageConstants.notificationsScreen:
        return materialPageRoute(widget: const NotificationsScreen());
        
      case PageConstants.securityScreen:
        return materialPageRoute(widget: const SecurityScreen());
        
      case PageConstants.helpSupportScreen:
        return materialPageRoute(widget: const HelpSupportScreen());
        
      case PageConstants.historyScreen:
        return materialPageRoute(widget: const HistoryScreen());
        
      case PageConstants.qrScannerScreen:
        return materialPageRoute(widget: const QRScannerScreen());
        
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Page not found'),
        ),
      );
    });
  }
}

MaterialPageRoute materialPageRoute({required Widget widget}) {
  return MaterialPageRoute(builder: (_) => widget);
}