import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'history_screen.dart';
class MobileDashboard extends StatefulWidget {
  const MobileDashboard({super.key});

  @override
  State<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<MobileDashboard> {
  late Stream<StepCount> _stepCountStream;
  String _steps = '?';
  
  // Variable to hold the giant initial hardware number
  int _startingLineSteps = 0; 

  @override
  void initState() {
    super.initState();
    checkPermissionsAndStart();
  }

  Future<void> checkPermissionsAndStart() async {
    // Request activity recognition permission
    PermissionStatus status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      initPedometer();
    } else {
      setState(() {
        _steps = 'Denied'; 
      });
    }
  }

  void initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(
      (StepCount event) {
        setState(() {
          // If this is the very first reading, set the starting line
          if (_startingLineSteps == 0) {
            _startingLineSteps = event.steps;
          }

          // Subtract the starting line from the hardware total
          int actualStepsTakenToday = event.steps - _startingLineSteps;
          
          // Update the UI with the clean number
          _steps = actualStepsTakenToday.toString();
        });
      },
    ).onError(
      (error) {
        setState(() {
          _steps = '0';
        });
        print("Pedometer Error: $error");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 🛑 Disables the system back swipe
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                // Logo
                Center(child: Image.asset('assets/images/logo.png', height: 60)),
                
                const SizedBox(height: 50),
                const Text(
                  "Your\nSteps.\nOur\nPriority.",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 40),
                // Step Counter Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5), // Light purple
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Daily Goal: 10,000", 
                        style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _steps, 
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)
                      ),
                      const Text(
                        "Steps Taken", 
                        style: TextStyle(color: Colors.grey)
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9147ff), // GAIA Purple
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryScreen()),
                      );
                    },
                    child: const Text(
                      "View History", 
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Extra bottom padding for scroll space
              ],
            ),
          ),
        ),
      ),
    );
  }
}