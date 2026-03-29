import 'package:flutter/material.dart';

class MobileDashboard extends StatelessWidget {
  const MobileDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SingleChildScrollView fixes the "Bottom Overflow"
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              // Logo - Keep it centered to avoid layout shifts
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
                    const Text("Daily Goal: 10,000", style: TextStyle(color: Colors.purple)),
                    const SizedBox(height: 10),
                    const Text("6,432", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                    const Text("Steps Taken", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 50),
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9147ff), // Your GAIA Purple
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    // Navigate to your Step Tracker logic
                  },
                  child: const Text("Start Tracking", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}