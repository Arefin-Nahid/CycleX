import 'package:flutter/material.dart';
import 'package:cyclex_hub/Config/routes/PageConstants.dart';
import 'package:cyclex_hub/view/ErrorScreen.dart';
import 'package:cyclex_hub/view/HomeScreen.dart';
import 'package:cyclex_hub/view/SplashScreen.dart';

import 'PageConstants.dart';

class OneGeneralRoute {

  static Route<dynamic> routes(RouteSettings settings) {
    var args = settings.arguments;
    switch (settings.name) {
      case PageConstants.splashScreen:
        {
          return materialPageRoute(widget: SplashScreen());
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