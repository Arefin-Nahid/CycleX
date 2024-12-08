import 'package:flutter/material.dart';
import 'package:cyclex_go/Config/AllDimensions.dart';
import 'package:cyclex_go/Config/AllImages.dart';
import 'package:cyclex_go/Config/AllTitles.dart';
import 'package:cyclex_go/Config/Allcolors.dart';

class Errorscreen extends StatefulWidget {
  const Errorscreen({super.key});

  @override
  State<Errorscreen> createState() => _ErrorscreenState();
}

class _ErrorscreenState extends State<Errorscreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          body: Container(
            color: Allcolors.yellowColor,
            height: AllDimensions.infinity,
            width: AllDimensions.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[

                Positioned(
                    left: 50,
                    right: 50,
                    top:0,
                    bottom: 0,
                    child: Image.asset(AllImages.logoImage)
                ),

                Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(AllTitles.poweredTitle),
                    )
                )

              ],
            ),
          ),
        )
    );
  }
}
