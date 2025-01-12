import 'package:flutter/material.dart';
import 'package:CycleX/Config/AllDimensions.dart';
import 'package:CycleX/Config/AllImages.dart';
import 'package:CycleX/Config/AllTitles.dart';
import 'package:CycleX/Config/Allcolors.dart';

class Errorscreen extends StatefulWidget {
  final String? errorMessage;
  final Function()? onRetry;
  final bool showHomeButton;

  const Errorscreen({
    super.key, 
    this.errorMessage,
    this.onRetry,
    this.showHomeButton = true,
  });

  @override
  State<Errorscreen> createState() => _ErrorscreenState();
}

class _ErrorscreenState extends State<Errorscreen> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade50,
                Colors.white,
              ],
            ),
          ),
          height: AllDimensions.infinity,
          width: AllDimensions.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Animated Error Icon
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height * 0.15,
                child: AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Oops!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          widget.errorMessage ?? 'Something went wrong!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Retry Button
                      if (widget.onRetry != null)
                        ElevatedButton.icon(
                          onPressed: widget.onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Home Button
                      if (widget.showHomeButton)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/homeScreen');
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('Go to Home'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Bottom Logo and Powered By
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Column(
                  children: [
                    Image.asset(
                      AllImages.logoImage,
                      height: 60,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        AllTitles.poweredTitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
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
