import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:localbusiness/views/auth/welcome_page.dart';
import 'package:localbusiness/widgets/locale_provider.dart';
import 'package:localbusiness/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localbusiness/views/shared/terms_of_service.dart';

class SharedDrawer extends StatefulWidget {
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
  _SharedDrawerState createState() => _SharedDrawerState();
}

class _SharedDrawerState extends State<SharedDrawer> {
  bool isNotificationEnabled = false;
  bool isLocationEnabled = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadToggleStates();
    initializeNotifications();
  }

  Future<void> _loadToggleStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? false;
      isLocationEnabled = prefs.getBool('isLocationEnabled') ?? false;
    });
  }

  Future<void> _saveToggleState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

// Replace your current notification toggle methods with these:

  Future<void> toggleNotificationServices(bool enable) async {
    if (enable) {
      // Request permission if enabling
      await requestNotificationPermissions();
    } else {
      // Can't revoke programmatically, just save preference
      // Optionally show message about manual revocation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Go to system settings to fully disable notifications'),
          action: SnackBarAction(
            label: 'SETTINGS',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }

    setState(() {
      isNotificationEnabled = enable;
    });
    await _saveToggleState('isNotificationEnabled', enable);
  }

  Future<void> requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      setState(() => isNotificationEnabled = true);
    } else {
      setState(() => isNotificationEnabled = false);
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }

// In your SharedDrawer class
  Future<void> toggleLocationServices(bool enable) async {
    if (enable) {
      // Request permission if enabling
      await requestLocationPermissions();
    } else {
      // Revoke permission if disabling
      await Geolocator.openAppSettings(); // Takes user to app settings
      // Note: You can't programmatically revoke permissions on Android/iOS
      // User must manually revoke in settings
    }
    setState(() {
      isLocationEnabled = enable;
    });
    await _saveToggleState('isLocationEnabled', enable);
  }

  Future<void> requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => isLocationEnabled = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => isLocationEnabled = false);
      await Geolocator.openAppSettings();
      return;
    }

    setState(() => isLocationEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: themeProvider.isDarkTheme
                ? [Colors.grey[900]!, Colors.black]
                : [
                    const Color.fromARGB(255, 218, 238, 252)!,
                    const Color.fromARGB(255, 252, 238, 255)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeProvider.isDarkTheme
                      ? [
                          const Color.fromARGB(255, 152, 83, 255)!,
                          Colors.blue[400]!
                        ]
                      : [
                          Colors.blue[400]!,
                          const Color.fromARGB(255, 246, 195, 255)!
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                widget.role.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                widget.email,
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.account_circle, size: 40, color: Colors.blue),
              ),
            ),

            // Theme Toggle
            _buildSettingTile(
              icon: themeProvider.isDarkTheme
                  ? Icons.dark_mode
                  : Icons.light_mode,
              title: localization.drawer_toggle_theme,
              trailing: Switch(
                value: themeProvider.isDarkTheme,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),

            // Language Switch
            _buildSettingTile(
              icon: Icons.language,
              title: localization.drawer_language,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) =>
                      LanguagePicker(localeProvider: localeProvider),
                );
              },
            ),

            const Divider(),

            // Settings Section
            _buildSettingTile(
              icon: Icons.settings,
              title: 'Settings',
              isSectionHeader: true,
            ),

            // Enable Location
            _buildSettingTile(
              icon: Icons.location_on,
              title: localization.enable_location,
              trailing: Switch(
                value: isLocationEnabled,
                onChanged: (value) async {
                  await toggleLocationServices(value);
                  setState(() {
                    isLocationEnabled = value;
                  });
                  await _saveToggleState('isLocationEnabled', value);
                },
              ),
            ),

            _buildSettingTile(
              icon: Icons.notifications,
              title: localization.enable_notification,
              trailing: Switch(
                value: isNotificationEnabled,
                onChanged: (value) async {
                  if (value) {
                    // When enabling notifications
                    final status = await Permission.notification.request();
                    if (status.isGranted) {
                      setState(() => isNotificationEnabled = true);
                      await _saveToggleState('isNotificationEnabled', true);

                      // Initialize notifications if needed
                      await initializeNotifications();
                    } else {
                      // Permission denied
                      if (status.isPermanentlyDenied) {
                        // Show dialog explaining they need to enable in settings
                        bool openSettings = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Notification Permission'),
                            content: const Text(
                                'Notifications are permanently denied. Please enable them in app settings.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Open Settings'),
                              ),
                            ],
                          ),
                        );

                        if (openSettings) {
                          await openAppSettings();
                        }
                      }
                      // Keep switch off if permission not granted
                      setState(() => isNotificationEnabled = false);
                      await _saveToggleState('isNotificationEnabled', false);
                    }
                  } else {
                    // When disabling notifications
                    setState(() => isNotificationEnabled = false);
                    await _saveToggleState('isNotificationEnabled', false);

                    // Show explanation that they need to disable in settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'To fully disable notifications, please turn them off in system settings'),
                        action: SnackBarAction(
                          label: 'Settings',
                          onPressed: () => openAppSettings(),
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
            ),

            // Terms of Service
            _buildSettingTile(
              icon: Icons.description,
              title: localization.terms_of_service,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServicePage(),
                  ),
                );
              },
            ),

            _buildSettingTile(
              icon: Icons.info,
              title: localization.about,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('About the App')),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Business Discovery App',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Version 1.0.0',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'How to Use This App:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildBulletPoint(
                                'Discover local businesses near you'),
                            _buildBulletPoint(
                                'View business details and contact information'),
                            _buildBulletPoint('Save your favorite businesses'),
                            _buildBulletPoint(
                                'Get directions to business locations'),
                            _buildBulletPoint(
                                'Review,Share,Email,Flag or Call business owners for any questions you may have'),
                            _buildBulletPoint(
                                'Ask help ai in top corner about your needs or let it recommend for you'),
                            _buildBulletPoint(
                                'Favorite and Bookmark businesses that caught your eye'),
                            _buildBulletPoint(
                                'Create businesses in owners section'),
                            _buildBulletPoint(
                                'Mange the reviews you have been given '),
                            _buildBulletPoint(
                                'Get analytics on how your business is doing'),
                            const SizedBox(height: 24),
                            const Text(
                              'Developed for local communities',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const Text(
                              'Contact Us +251-91-11-11-11\n'
                              'Email bazinga.gmail.com',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

// Helper widget for bullet points

            // Credits Section
            _buildSettingTile(
              icon: Icons.people,
              title: localization.credits,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Development Team')),
                      body: ListView(
                        padding: const EdgeInsets.all(16),
                        children: const [
                          ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Abiy kibru'),
                            subtitle: Text('Flutter Developer'),
                          ),
                          ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Mufti Abdulbaki'),
                            subtitle: Text('UI/UX Designer'),
                          ),
                          ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Selamu Meshesha'),
                            subtitle: Text('Database designer'),
                          ),
                          ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Tsion Negash'),
                            subtitle: Text('Bckend developer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const Divider(),

            // Logout
            _buildSettingTile(
              icon: Icons.logout,
              title: localization.logout,
              color: Colors.red,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                  (route) => false,
                );
                widget.onLogout(); // Trigger additional cleanup if needed
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool isSectionHeader = false,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blue),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSectionHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildCreditItem(String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            title: const Text('ትግርኛ'),
            onTap: () {
              localeProvider.setLocale(const Locale('fr'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('ወላይትኛ'),
            onTap: () {
              localeProvider.setLocale(const Locale('es'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('ኦሮምኛ'),
            onTap: () {
              localeProvider.setLocale(const Locale('nl'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
