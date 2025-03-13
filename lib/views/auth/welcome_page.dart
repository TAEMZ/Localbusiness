import 'package:flutter/material.dart';
import 'auth_modal.dart';
import '../user/user_home_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], // Gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context)
                .size
                .height, // ✅ Ensures it fills the full screen
            child: Column(
              children: [
                Expanded(
                  // ✅ This makes sure the content fills the available space
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo and App Name
                          Image.asset(
                            'assets/images/logo2.png',
                            width: MediaQuery.of(context).size.width *
                                0.5, // ✅ Responsive
                            height: MediaQuery.of(context).size.height *
                                0.3, // ✅ Responsive
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Welcome to Local Business',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Continue as Business Owner
                          _buildButton(
                            context,
                            icon: Icons.business,
                            label: 'Manage My Business',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    const AuthModal(role: 'owner'),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // Continue as Regular User
                          _buildButton(
                            context,
                            icon: Icons.search,
                            label: 'Discover Local Businesses',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    const AuthModal(role: 'user'),
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
                                color: Colors.white,
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
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
