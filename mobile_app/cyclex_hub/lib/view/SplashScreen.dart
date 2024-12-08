import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cyclex_hub/Config/AllDimensions.dart';
import 'package:cyclex_hub/Config/AllImages.dart';
import 'package:cyclex_hub/Config/AllTitles.dart';
import 'package:cyclex_hub/Config/Allcolors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacementNamed(context, '/homeScreen');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          color: Allcolors.whiteColor,
          height: AllDimensions.infinity,
          width: AllDimensions.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Image
                    SvgPicture.asset(
                      'assets/images/icon.svg',
                      height: 80, // Adjust the size as needed
                      width: 80,
                    ),// Space between logo and SVG

                    // SVG Icon
                    Image.asset(
                      AllImages.logoImage,
                      height: 120, // Adjust the size as needed
                      width: 120,
                    ),
                  ],
                ),
              ),

              // Bottom Section with Powered Title and KUET Logo
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min, // Compact layout
                      children: [
                        Image.asset(
                          'assets/images/kuet_logo.png', // KUET logo asset path
                          height: 24, // Adjust the logo height
                          width: 24, // Adjust the logo width
                        ),
                        const SizedBox(width: 8), // Space between logo and text
                        const Text(
                          AllTitles.poweredTitle, // "Powered by" text
                          style: TextStyle(
                            color: Colors.black, // Text color
                            fontSize: 16, // Font size
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
