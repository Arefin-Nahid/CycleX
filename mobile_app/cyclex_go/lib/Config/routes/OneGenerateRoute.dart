import 'package:cyclex_go/view/login_screen.dart';
import 'package:cyclex_go/view/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:cyclex_go/Config/routes/PageConstants.dart';
import 'package:cyclex_go/view/ErrorScreen.dart';
import 'package:cyclex_go/view/HomeScreen.dart';
import 'package:cyclex_go/view/SplashScreen.dart';

class OneGeneralRoute {

  static Route<dynamic> routes(RouteSettings settings) {
    var args = settings.arguments;
    switch (settings.name) {
      case PageConstants.splashScreen:
        {
          return materialPageRoute(widget: SplashScreen());
        }
      case PageConstants.registerScreen:
        {
          return materialPageRoute(widget: RegisterScreen());
        }
      case PageConstants.loginScreen:
        {
          return materialPageRoute(widget: LoginScreen());
        }
      case PageConstants.homeScreen:
        {
          return materialPageRoute(widget: Homescreen());
        }
      default:
        {
          return materialPageRoute(widget: Errorscreen());
        }
    }
  }
}

MaterialPageRoute materialPageRoute({required Widget widget}) {
  return MaterialPageRoute(builder: (_) => widget);
}