import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Lottie.asset(
            'assets/animations/loading.json',
            fit: BoxFit.contain,
             errorBuilder: (context, error, stackTrace) {
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}
