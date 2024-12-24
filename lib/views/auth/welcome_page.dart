import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sign-Up Button
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => RoleSelectionDialog(
                    title: 'Sign Up As',
                    onUserSelected: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.pushNamed(context, '/signup_user');
                    },
                    onOwnerSelected: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.pushNamed(context, '/signup_owner');
                    },
                  ),
                );
              },
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => RoleSelectionDialog(
                    title: 'Login As',
                    onUserSelected: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.pushNamed(context, '/login_user');
                    },
                    onOwnerSelected: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.pushNamed(context, '/login_owner');
                    },
                  ),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Role Selection Dialog
class RoleSelectionDialog extends StatelessWidget {
  final String title;
  final VoidCallback onUserSelected;
  final VoidCallback onOwnerSelected;

  const RoleSelectionDialog({
    super.key,
    required this.title,
    required this.onUserSelected,
    required this.onOwnerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              onUserSelected();
            },
            child: const Text('User'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              onOwnerSelected();
            },
            child: const Text('Owner'),
          ),
        ],
      ),
    );
  }
}
