import 'package:flutter/material.dart';

// We import the file that contains all the route names and their corresponding screens.
// This is how the app knows which screen to show for each route.
import 'routes.dart';

// We import the theme file where all colors, fonts, and UI styling are defined.
// This keeps design separated from logic.
import 'theme.dart';

// GaiaApp is the root widget of the entire application.
// Everything you see in the app is built under this widget.
class GaiaApp extends StatelessWidget {
  // The constructor is marked as const because this widget never changes its state.
  // Using const improves performance and shows that the widget is immutable.
  const GaiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp is the core widget that defines:
    // - App title
    // - Theme
    // - Navigation system (routes)
    // - Initial screen
    return MaterialApp(
      // The title is used by the operating system (task switcher, browser tab, etc.)
      title: 'GAIA – Intelligent Symptom Checker',

      // We hide the debug banner that appears in the top right corner.
      debugShowCheckedModeBanner: false,

      // We apply our custom theme defined in theme.dart.
      // This controls colors, fonts, and general styling everywhere in the app.
      theme: AppTheme.light(),

      // This is the first screen that opens when the app starts.
      // It uses a constant defined in routes.dart.
      initialRoute: Routes.landing,

      // This map contains all navigation routes and their associated widgets.
      // It allows us to navigate by name instead of manually creating screens.
      routes: Routes.map,
    );
  }
}
