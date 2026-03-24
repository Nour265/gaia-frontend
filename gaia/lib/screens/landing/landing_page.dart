import 'package:flutter/material.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/widgets/sections/cta.dart';
import 'package:gaia/widgets/sections/features.dart';
import 'package:gaia/widgets/sections/footer.dart';
import 'package:gaia/widgets/sections/heros.dart';
import 'package:gaia/widgets/sections/stats.dart';
import 'package:gaia/widgets/sections/testimonials.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const GaiaNavBarAppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Heros(),
            const Features(),
            const Testimonials(),
            const Stats(),
            const Cta(),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
