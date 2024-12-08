import 'package:flutter/material.dart';
import 'package:cyclex_hub/Config/AllDimensions.dart';
import 'package:cyclex_hub/Config/AllImages.dart';
import 'package:cyclex_hub/Config/AllTitles.dart';
import 'package:cyclex_hub/Config/Allcolors.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: const Text(
          'Welcome to the Home Page!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
