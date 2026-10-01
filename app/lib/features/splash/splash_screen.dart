import 'package:flutter/material.dart';

/// Neutral holding screen shown while teh saved session is beigh restored
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
