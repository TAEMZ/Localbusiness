import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/auth/splash_screen.dart';
import 'views/auth/welcome_page.dart';
import 'views/user/user_home_page.dart';
import 'views/owner/owner_dashboard.dart';
import 'widgets/theme_provider.dart';
import 'widgets/locale_provider.dart';
import 'models/firebase_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:localbusiness/widgets/location_provider.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'consts.dart'; // ✅ Import Firebase Notifications

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize Firebase Notifications
  await FirebaseNotificationService.initialize();
  Gemini.init(apiKey: GEMINI_API_KEY);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final String businessId;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Business Discovery',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness:
            themeProvider.isDarkTheme ? Brightness.dark : Brightness.light,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
        Locale('fr'),
        Locale('es'),
        Locale('nl'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const AuthWrapper(),
      routes: {
        '/user_home': (context) => const UserHomePage(
              businessId: '',
            ),
        '/owner_dashboard': (context) => const OwnerDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/welcome_page': (context) => const WelcomePage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<Widget> determineStartPage() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SplashScreen();
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = userDoc['role'] ?? 'user';

      if (role == 'admin') {
        return const AdminDashboard();
      } else if (role == 'owner') {
        return const OwnerDashboard();
      } else {
        return const UserHomePage(
          businessId: '',
        );
      }
    } catch (e) {
      print('AuthWrapper Error: $e');
      return const WelcomePage();
    }
  }

  @override
  void initState() {
    super.initState();
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    locationProvider.getLocation();
    FirebaseNotificationService.subscribeToTopic(
        "business_updates"); // ✅ Auto-subscribe users
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: determineStartPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitWave(
              size: 50.0,
              color: Color.fromARGB(255, 133, 128, 128),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        return const WelcomePage();
      },
    );
  }
}
