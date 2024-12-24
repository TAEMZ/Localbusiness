import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Localization
import 'views/auth/welcome_page.dart';
import 'views/auth/signup_user_page.dart';
import 'views/auth/signup_owner_page.dart';
import 'views/auth/login_page.dart';
import 'views/user/user_home_page.dart';
import 'views/owner/owner_dashboard.dart';
import 'firebase_options.dart';
import 'package:localbusiness/widgets/theme_provider.dart'; // Import ThemeProvider
import 'package:localbusiness/widgets/locale_provider.dart'; // Import LocaleProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local Business Discovery',
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
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const AuthWrapper(),
      routes: {
        '/signup_user': (context) => SignupUserPage(),
        '/signup_owner': (context) => SignupOwnerPage(),
        '/login_user': (context) => LoginPage(userRole: 'user'),
        '/login_owner': (context) => LoginPage(userRole: 'owner'),
        '/user_home': (context) => UserHomePage(),
        '/owner_dashboard': (context) => const OwnerDashboard(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> determineStartPage() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const WelcomePage();
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = userDoc['role'] ?? 'user';

      if (role == 'owner') {
        return const OwnerDashboard();
      } else {
        return UserHomePage();
      }
    } catch (e) {
      print('AuthWrapper Error: $e');
      return const WelcomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: determineStartPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
