import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:localbusiness/widgets/custom_text_field.dart';

class AuthModal extends StatefulWidget {
  final String role; // 'user' or 'owner'

  const AuthModal({super.key, required this.role});

  @override
  _AuthModalState createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;

  void _toggleObscurity() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate(bool isLogin) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();
    final user = isLogin
        ? await authService.login(email, password)
        : await authService.signUp(email, password, widget.role);

    setState(() => _isLoading = false);

    if (user != null) {
      // Check if user is an admin
      if (user.role == 'admin') {
        Navigator.pop(context); // Close modal
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        // Default behavior (User or Owner)
        Navigator.pop(context);
        Navigator.pushReplacementNamed(
          context,
          widget.role == 'user' ? '/user_home' : '/owner_dashboard',
        );
      }
    } else {
      _showSnackBar('Authentication failed');
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Enter your email to reset password');
      return;
    }

    try {
      await AuthService().resetPassword(email);
      _showSnackBar('Password reset email sent');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await AuthService().signInWithGoogle();
      // _navigateAfterSignIn();
    } catch (e) {
      _showSnackBar('Google Sign-In failed: $e');
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      await AuthService().signInWithFacebook();
      // _navigateAfterSignIn();
    } catch (e) {
      _showSnackBar('Facebook Sign-In failed: $e');
    }
  }

  void _navigateAfterSignIn() {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/user_home');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 490,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabBar(),
              const SizedBox(height: 20),
              _buildTabView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return SizedBox(
      height: 450,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAuthForm(isLogin: true), // Login Tab
          _buildAuthForm(isLogin: false), // Sign Up Tab
        ],
      ),
    );
  }

  Widget _buildAuthForm({required bool isLogin}) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
          ),
          const SizedBox(height: 15),
          // _buildTextField(
          //   controller: _passwordController,
          //   label: 'Password',
          //   icon: Icons.lock,
          //   isPassword: true,
          // ),
          CustomTextField(
            hintText: "Password",
            controller: _passwordController,
            isObscureText: _isObscured,
            suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility_sharp,
                  color: Colors.grey,
                ),
                onPressed: _toggleObscurity),
          ),
          if (isLogin) _buildForgotPasswordButton(),
          const SizedBox(height: 10),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : _buildAuthButton(isLogin),
          const SizedBox(height: 15),
          _buildSocialButtons(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        prefixIcon: Icon(icon, color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _resetPassword,
        child: const Text(
          'Forgot Password?',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAuthButton(bool isLogin) {
    return ElevatedButton(
      onPressed: () => _authenticate(isLogin),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        isLogin ? 'Login' : 'Sign Up',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        const Text(
          'Or continue with',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: 'assets/images/google.png',
                onPressed: _signInWithGoogle,
              ),
              const SizedBox(width: 10),
              _buildSocialButton(
                icon: 'assets/images/facebook.png',
                onPressed: _signInWithFacebook,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildSocialButton({
  //   required String icon,
  //   required VoidCallback onPressed,
  // }) {
  //   return ClipOval(
  //     child: IconButton(
  //       icon: Image.asset(icon),
  //       onPressed: onPressed,
  //       iconSize: 24,
  //     ),
  //   );
  // }
  Widget _buildSocialButton({
    required String icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white, // Adjust color as needed
      ),
      child: IconButton(
        icon: Image.asset(icon),
        onPressed: onPressed,
        iconSize: 24,
      ),
    );
  }
}
