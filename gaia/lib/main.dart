import 'package:flutter/material.dart';

// We import our app root widget.
// This file (app.dart) will contain the main configuration of the app
// such as routes, theme, and initial screen.
import 'app/app.dart';

void main() {
  // main() is the entry point of any Dart application.
  // Flutter starts executing the program from here.
  //
  // runApp() takes a Widget and makes it the root of the widget tree.
  // Everything you see in the app will be a child of this widget.
  runApp(const GaiaApp());
}

