// lib/design/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:planty_flutter_starter/design/layout.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({required this.onComplete, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkgreen,
      body: Center(
        child: Lottie.asset(
          'assets/leaf_animation.json',
          repeat: true,
          width: MediaQuery.of(context).size.width * 0.78,
  height: MediaQuery.of(context).size.height * 0.78,
  fit: BoxFit.contain,
  onLoaded: (composition) {
    Future.delayed(composition.duration, widget.onComplete);
  },
),
      ),
    );
  }
}
