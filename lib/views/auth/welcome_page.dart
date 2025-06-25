import 'package:flutter/material.dart';
import 'package:localbusiness/widgets/locale_provider.dart';
import 'package:lottie/lottie.dart';
import 'auth_modal.dart';
import '../user/user_home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    );

    // We'll set the duration after the animation is loaded
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
        maintainState: true,
        fullscreenDialog: true,
      ),
    );
  }

  String _getCurrentLanguageName(String? languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'am':
        return 'አማርኛ';
      case 'fr':
        return 'ትግርኛ';
      case 'es':
        return 'ወላይትኛ';
      case 'nl':
        return 'ኦሮምኛ';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Lottie Animation Background
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Lottie.asset(
                'assets/animations/mapanimation.json',
                fit: BoxFit.cover,
                alignment: const Alignment(-3, 0),
                controller: _animationController,
                onLoaded: (composition) {
                  _animationController
                    ..duration = composition.duration
                    ..repeat();
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Failed to load animation',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                },
              ),
            ),
          ),

          // Main Content with SafeArea
          SafeArea(
            child: Stack(
              children: [
                // Center content
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 140),
                          Text(
                            '"Get connected discover yourselves"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.parisienne(
                              fontSize: 36,
                              color: const Color(0xFFF5E9D9),
                              shadows: [
                                const Shadow(
                                  blurRadius: 8.0,
                                  color: Color.fromARGB(150, 100, 80, 60),
                                  offset: Offset(3.0, 3.0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 55),
                          _buildButton(
                            context,
                            icon: Icons.business,
                            label: localization.manage_your_business,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _navigateWithoutStoppingAnimation(
                                context,
                                const AuthModal(role: 'owner'),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildButton(
                            context,
                            icon: Icons.search,
                            label: localization.discover_businesses,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _navigateWithoutStoppingAnimation(
                                context,
                                const AuthModal(role: 'user'),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
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
                            child: Text(
                              localization.continue_as_guest,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 190, 148, 190),
                                fontStyle: FontStyle.italic,
                                shadows: [
                                  const Shadow(
                                    blurRadius: 10.0,
                                    color: Color.fromARGB(255, 70, 72, 72),
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

                // Language dropdown at top right (moved to be last in Stack)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getCurrentLanguageName(
                                localeProvider.locale?.languageCode),
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildLanguageDropdown(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.3),
          ),
          child: const Icon(Icons.language, color: Colors.white, size: 24),
        ),
        tooltip: 'Change Language',
        position: PopupMenuPosition.under,
        onSelected: (String languageCode) {
          localeProvider.setLocale(Locale(languageCode));
        },
        itemBuilder: (BuildContext context) {
          return [
            const PopupMenuItem<String>(
              value: 'en',
              child: Text('English'),
            ),
            const PopupMenuItem<String>(
              value: 'am',
              child: Text('አማርኛ'),
            ),
            const PopupMenuItem<String>(
              value: 'fr',
              child: Text('ትግርኛ'),
            ),
            const PopupMenuItem<String>(
              value: 'es',
              child: Text('ወላይትኛ'),
            ),
            const PopupMenuItem<String>(
              value: 'nl',
              child: Text('ኦሮምኛ'),
            ),
          ];
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.15), // More subtle
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40), // More rounded
            side: BorderSide(
              color: Colors.white.withOpacity(0.5), // Lighter border
              width: 1.5,
            ),
          ),
          elevation: 8,
          shadowColor: Colors.purple[100]!.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20, // Slightly larger for better readability
                fontWeight: FontWeight
                    .w600, // Semi-bold (Playfair doesn't have bold italic)
                fontStyle: FontStyle
                    .italic, // This gives us the elegant italic variant
                color: const Color.fromARGB(
                    255, 54, 53, 53), // Maintain your original text color
                letterSpacing: 0.5, // Slight letter spacing for elegance
                shadows: const [
                  Shadow(
                    blurRadius: 4.0, // More subtle shadow
                    color: Color.fromARGB(
                        148, 153, 140, 140), // Softer shadow color
                    offset: Offset(1.5, 1.5),
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
