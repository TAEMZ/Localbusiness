import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:localbusiness/widgets/custom_text_field.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final GlobalKey _scaffoldKey = GlobalKey();

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
      _showTopSnackBar('Please fill in all fields');
      return;
    }
    if (!isLogin) {
      // Check all password requirements at once
      final hasMinLength = password.length >= 8;
      final hasUppercase = password.contains(RegExp(r'[A-Z]'));
      final hasNumber = password.contains(RegExp(r'[0-9]'));
      final hasSpecialChar =
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      if (!hasMinLength || !hasUppercase || !hasNumber || !hasSpecialChar) {
        _showTopSnackBar(
          'Password must contain:\n'
          '- 8+ characters\n'
          '- 1 uppercase letter\n'
          '- 1 number\n'
          '- 1 special character (!@#\$%^&*)',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = isLogin
          ? await authService.login(email, password)
          : await authService.signUp(email, password, widget.role);

      setState(() => _isLoading = false);

      if (user != null) {
        // Add role validation check
        if (user.role != widget.role && user.role != 'admin') {
          _showTopSnackBar('Access denied: Invalid role for this section');
          return;
        }

        if (user.role == 'admin') {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(
            context,
            user.role == 'user' ? '/user_home' : '/owner_dashboard',
          );
        }
      } else {
        _showTopSnackBar('Authentication failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showTopSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showTopSnackBar('Enter your email to reset password');
      return;
    }

    try {
      await AuthService().resetPassword(email);
      _showTopSnackBar('Password reset email sent');
    } catch (e) {
      _showTopSnackBar('Error: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      // First sign out from Google to clear any cached credentials
      await GoogleSignIn().signOut();

      // Then sign in with Google, forcing account selection
      final user = await AuthService().signInWithGoogle(widget.role);

      setState(() => _isLoading = false);

      if (user != null) {
        // Add strict role validation
        if (user.role != widget.role && user.role != 'admin') {
          _showTopSnackBar(
              '❌ Access restricted to ${widget.role == 'user' ? 'regular users' : 'business owners'}');
          // Force logout invalid user
          return;
        }

        if (user.role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          Navigator.pushReplacementNamed(
            context,
            user.role == 'user' ? '/user_home' : '/owner_dashboard',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showTopSnackBar('Google Sign-In failed: ${e.toString()}');
    }
  }

  void _navigateAfterSignIn() {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/user_home');
  }

  void _showTopSnackBar(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewInsets.top + 50,
        left: 20,
        right: 20,
        child: Material(
          color: const Color.fromARGB(0, 102, 100, 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 62, 62, 62),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry
    overlay.insert(overlayEntry);

    // Remove the overlay entry after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
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
          _buildAuthForm(isLogin: true),
          _buildAuthForm(isLogin: false),
        ],
      ),
    );
  }

  Widget _buildAuthForm({required bool isLogin}) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(hintText: 'Email', controller: _emailController),
          const SizedBox(height: 15),
          CustomTextField(
            hintText: "Password",
            controller: _passwordController,
            isObscureText: _isObscured,
            suffixIcon: IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility_off : Icons.visibility_sharp,
                color: Colors.grey,
              ),
              onPressed: _toggleObscurity,
            ),
          ),
          if (!isLogin)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password must contain:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  _buildPasswordRequirement(
                    "8+ characters",
                    _passwordController.text.length >= 8,
                  ),
                  _buildPasswordRequirement(
                    "1 uppercase letter",
                    _passwordController.text.contains(RegExp(r'[A-Z]')),
                  ),
                  _buildPasswordRequirement(
                    "1 number",
                    _passwordController.text.contains(RegExp(r'[0-9]')),
                  ),
                  _buildPasswordRequirement(
                    "1 special character (!@#\$%^&*)",
                    _passwordController.text
                        .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
                  ),
                ],
              ),
            ),
          if (isLogin) _buildForgotPasswordButton(),
          const SizedBox(height: 10),
          _isLoading
              ? SpinKitWave(
                  color: Color.fromARGB(255, 133, 128,
                      128), // Or use Theme.of(context).colorScheme.primary
                  size: 50.0,
                )
              : _buildAuthButton(isLogin),
          const SizedBox(height: 15),
          _buildSocialButtons(),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _resetPassword,
        child: const Text(
          'Forgot Password?',
          style: TextStyle(color: Colors.blue, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAuthButton(bool isLogin) {
    final localization = AppLocalizations.of(context)!;
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.black,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _authenticate(isLogin),
        splashColor: Colors.blue.withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          alignment: Alignment.center,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: SpinKitWave(
                    color: Colors
                        .black, // Or use Theme.of(context).colorScheme.primary
                    size: 50.0,
                  ),
                )
              : Text(
                  isLogin ? localization.login : localization.sign_up,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    final localization = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          localization.or_continue_with,
          style: TextStyle(color: Colors.black, fontSize: 14),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: IconButton(
        icon: Image.asset(icon),
        onPressed: onPressed,
        iconSize: 44,
      ),
    );
  }
}
