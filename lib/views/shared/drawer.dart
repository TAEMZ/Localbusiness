import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/views/auth/welcome_page.dart';
import 'package:localbusiness/widgets/locale_provider.dart';
import 'package:localbusiness/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
// Import LocaleProvider and ThemeProvider

class SharedDrawer extends StatelessWidget {
  final String email;
  final String role;
  final VoidCallback onLogout;

  const SharedDrawer({
    super.key,
    required this.email,
    required this.role,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(role.toUpperCase()),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.account_circle, size: 40),
            ),
          ),

          // Theme Toggle
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDarkTheme ? Icons.dark_mode : Icons.light_mode,
            ),
            title: Text(localization.drawer_toggle_theme),
            value: themeProvider.isDarkTheme,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),

          // Language Switch
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localization.drawer_language),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => LanguagePicker(localeProvider: localeProvider),
              );
            },
          ),

          const Divider(),

          // Logout
          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(localization.logout),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomePage()),
                (route) => false,
              );
              onLogout(); // Trigger additional cleanup if needed
            },
          ),
        ],
      ),
    );
  }
}

class LanguagePicker extends StatelessWidget {
  final LocaleProvider localeProvider;

  const LanguagePicker({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('English'),
          onTap: () {
            localeProvider.setLocale(const Locale('en'));
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('አማርኛ'),
          onTap: () {
            localeProvider.setLocale(const Locale('am'));
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('ስልጢኛ'),
          onTap: () {
            localeProvider.setLocale(const Locale('fr'));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
