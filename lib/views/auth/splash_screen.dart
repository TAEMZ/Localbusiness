import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:localbusiness/views/auth/welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 9), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 242, 242, 243),
              Color.fromARGB(255, 0, 0, 0)
            ], // Gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Lottie Animation (Full Screen, Slightly to the Left)
            Positioned.fill(
              child: Align(
                alignment:
                    const Alignment(-1.8, 0), // Adjust alignment to move left
                child: Lottie.asset(
                  'assets/animations/splash_animation.json', // Your Lottie JSON file
                  fit: BoxFit.cover,
                  width: 50,
                  height: 760, // Fill the entire screen
                ),
              ),
            ),

            // Dotted Progress Indicator (Centered at the bottom)
            const Positioned(
              bottom: 50, // Adjust the position from the bottom
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedDottedProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Animated Dotted Progress Indicator
class AnimatedDottedProgressIndicator extends StatefulWidget {
  const AnimatedDottedProgressIndicator({super.key});

  @override
  State<AnimatedDottedProgressIndicator> createState() =>
      _AnimatedDottedProgressIndicatorState();
}

class _AnimatedDottedProgressIndicatorState
    extends State<AnimatedDottedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5, // Number of dots
          (index) => AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Animate the opacity of each dot
              final double opacity = (index + 1) * 0.2 * _controller.value;
              return Opacity(
                opacity: opacity,
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 254, 171, 255),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
