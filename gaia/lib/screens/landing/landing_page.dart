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
    final size = MediaQuery.of(context).size;

    return Scaffold(
       backgroundColor: AppColors.white,
        extendBodyBehindAppBar: false, // IMPORTANT
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72.0),
          child: Container(
            color: AppColors.white, // keeps it white and non-overlapping
            child: Center(
              child: SizedBox(
                width: size.width * 0.7,
                child: const NavBar(),
              ),
            ),
          ),
        ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Heros(),
            Features(),
            Testimonials(),
            Stats(),
            Cta(),
            Footer(),
          ],
        ),
      ),
    );
  }
}