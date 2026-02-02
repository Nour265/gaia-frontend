import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/app/theme.dart';

class GaiaApp extends StatelessWidget {
  const GaiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAIA – Intelligent Symptom Checker',
      debugShowCheckedModeBanner: false,
      theme: lightThemeData,
      initialRoute: Routes.landing,
      routes: Routes.map,
    );
  }
}
