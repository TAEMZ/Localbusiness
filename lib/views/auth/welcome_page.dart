import 'package:flutter/material.dart';
import 'auth_modal.dart';
import '../user/user_home_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg', // Path to your background image
              fit: BoxFit.cover, // Cover the entire screen
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
                            const SizedBox(height: 150),
                            const Text(
                              '"Get connected discover yourselves"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 236, 230, 230),
                                fontFamily: 'Roboto',
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Color.fromARGB(255, 255, 223, 223),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AuthModal(role: 'owner'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 30),

                            // Continue as Regular User
                            _buildButton(
                              context,
                              icon: Icons.search,
                              label: 'Discover Businesses',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AuthModal(role: 'user'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 40),

                            // Continue as Guest
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UserHomePage(isGuest: true),
                                  ),
                                );
                              },
                              child: const Text(
                                'Continue as Guest',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 230, 218, 218),
                                  fontFamily: 'Pacifico',
                                  shadows: [
                                    Shadow(
                                      blurRadius: 5.0,
                                      color: Color.fromARGB(255, 193, 190, 255),
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
          backgroundColor: const Color.fromARGB(255, 3, 3, 3).withOpacity(0.3),
          foregroundColor: const Color.fromARGB(255, 224, 212, 212),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(
                color: Color.fromARGB(255, 201, 193, 193), width: 2),
          ),
          elevation: 10,
          shadowColor:
              const Color.fromARGB(255, 229, 244, 255).withOpacity(0.5),
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
                    color: Color.fromARGB(255, 33, 32, 32),
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
