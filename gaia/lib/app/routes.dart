import 'package:flutter/material.dart';

// We import all the screens that our application can navigate to.
// Each screen is a Widget and represents a page in the app.
import '../screens/landing/landing_page.dart';
import '../screens/wizard/symptom_wizard.dart';
import '../screens/results/results_page.dart';
import '../screens/about/about_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/signup_page.dart';
import '../screens/auth/forgot_password_page.dart';
import '../screens/profile/profile_page.dart';

// This class centralizes all route names and their corresponding screens.
// It prevents having hard-coded strings spread everywhere in the app.
class Routes {
  // Route name for the landing page (home screen).
  // We use '/' because Flutter considers it the default root route.
  static const String landing = '/';

  // Route name for the symptom checking wizard.
  static const String wizard = '/wizard';

  // Route name for the results screen.
  static const String results = '/results';

  // Route name for the about/disclaimer page.
  static const String about = '/about';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';

  // This map connects route names (strings) to the Widgets (screens) they open.
  // Flutter uses this map to know which screen to build when a route is requested.
  static Map<String, WidgetBuilder> get map => {
        // When Flutter navigates to '/', it builds the HomePage widget.
        landing: (_) => const HomePage(),

        // When Flutter navigates to '/wizard', it builds the SymptomWizard widget.
        wizard: (_) => const SymptomWizard(),

        // When Flutter navigates to '/about', it builds the AboutPage widget.
        about: (_) => const AboutPage(),

        // When Flutter navigates to '/login', it builds the LoginPage widget.
        login: (_) => const LoginPage(),

        // When Flutter navigates to '/signup', it builds the SignupPage widget.
        signup: (_) => const SignupPage(),

        // When Flutter navigates to '/forgot-password', it builds the ForgotPasswordPage widget.
        forgotPassword: (_) => const ForgotPasswordPage(),

        // When Flutter navigates to '/profile', it builds the ProfilePage widget.
        profile: (_) => const ProfilePage(),
      };
}
