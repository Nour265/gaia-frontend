import 'package:flutter/material.dart';
import 'package:gaia/app/theme.dart' as app_theme;
import 'app/routes.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/mobile/mobile_dashboard.dart';
import 'package:gaia/services/auth_session.dart'; // Ensure this is imported
import 'package:gaia/screens/auth/login_page.dart'; // Ensure this is imported

void main() async {
  // Required because we are calling native code (SharedPreferences) before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Check if a token exists in local storage
  bool loggedIn = AuthSession.user != null;

  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: app_theme.lightThemeData,
      title: 'GAIA',
      
      // LOGIC: 
      // 1. If Web -> Go to Landing Page (No force login)
      // 2. If Mobile + Logged In -> Go to Dashboard
      // 3. If Mobile + Not Logged In -> Force Login Page
      initialRoute: kIsWeb 
          ? Routes.landing 
          : (isLoggedIn ? '/mobile_dashboard' : Routes.login),
      
      routes: {
        ...Routes.map,
        '/mobile_dashboard': (_) => const MobileDashboard(),
      },
    );
  }
}