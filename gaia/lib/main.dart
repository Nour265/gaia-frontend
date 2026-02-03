import 'package:flutter/material.dart';
import 'package:gaia/app/theme.dart' as app_theme;
import 'package:gaia/screens/landing/landing_page.dart';
import 'app/routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: app_theme.lightThemeData,
      initialRoute: Routes.landing,
      routes: Routes.map,
      title: 'GAIA',
    );
  }
}