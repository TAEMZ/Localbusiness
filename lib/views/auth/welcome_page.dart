import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'auth_modal.dart';
import '../user/user_home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // Loop the animation infinitely
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateWithoutStoppingAnimation(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        maintainState: true, // This keeps the previous route alive
        fullscreenDialog: true, // Optional: makes the modal appear from bottom
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Lottie Animation Background
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/mapanimation.json',
              fit: BoxFit.cover,
              alignment:
                  const Alignment(-0.2, 0), // Adjusted alignment to move left
              controller: _animationController, // Attach the controller
              onLoaded: (composition) {
                // Play the animation when loaded
                _animationController
                  ..duration = composition.duration
                  ..forward();
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading Lottie animation: $error');
                return const Center(
                  child: Text(
                    'Failed to load animation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                );
              },
            ),
          ),

          // Rest of the content
          SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 200),
                            const Text(
                              '"Get connected discover yourselves"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 241, 241),
                                fontFamily: 'Roboto',
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Color.fromARGB(255, 92, 86, 86),
                                    offset: Offset(2.0, 2.0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 55),

                            // Continue as Business Owner
                            _buildButton(
                              context,
                              icon: Icons.business,
                              label: 'Manage your Business',
                              onPressed: () {
                                _navigateWithoutStoppingAnimation(
                                  context,
                                  const AuthModal(role: 'owner'),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Continue as Regular User
                            _buildButton(
                              context,
                              icon: Icons.search,
                              label: 'Discover Businesses',
                              onPressed: () {
                                _navigateWithoutStoppingAnimation(
                                  context,
                                  const AuthModal(role: 'user'),
                                );
                              },
                            ),
                            const SizedBox(height: 40),

                            // Continue as Guest
                            TextButton(
                              onPressed: () {
                                _navigateWithoutStoppingAnimation(
                                  context,
                                  const UserHomePage(
                                    isGuest: true,
                                    businessId: '',
                                  ),
                                );
                              },
                              child: const Text(
                                'Continue as Guest',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 171, 148, 192),
                                  fontFamily: 'Pacifico',
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Color.fromARGB(255, 88, 92, 93),
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for buttons
  Widget _buildButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color.fromARGB(255, 178, 224, 255).withOpacity(0.3),
          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(
                color: Color.fromARGB(255, 224, 226, 255), width: 2),
          ),
          elevation: 30,
          shadowColor:
              const Color.fromARGB(255, 229, 248, 255).withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pacifico',
                shadows: [
                  Shadow(
                    blurRadius: 5.0,
                    color: Color.fromARGB(255, 255, 241, 241),
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
