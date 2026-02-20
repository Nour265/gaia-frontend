import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gaia/app/theme.dart' as app_theme;
import 'package:gaia/screens/landing/landing_page.dart';
import 'package:gaia/services/api_service.dart';
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
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const _ApiDebugBanner(),
          ],
        );
      },
      initialRoute: Routes.landing,
      routes: Routes.map,
      title: 'GAIA',
    );
  }
}

class _ApiDebugBanner extends StatelessWidget {
  const _ApiDebugBanner();

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      bottom: 12,
      child: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              'API: ${ApiService.baseUrl}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
