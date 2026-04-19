import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:gaia/services/api_service.dart';

class AndroidStepTracker extends StatefulWidget {
  final String authToken; // Pass the JWT token from your login state

  const AndroidStepTracker({Key? key, required this.authToken}) : super(key: key);

  @override
  _AndroidStepTrackerState createState() => _AndroidStepTrackerState();
}

class _AndroidStepTrackerState extends State<AndroidStepTracker> {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // 1. Request Android Activity Recognition Permission
    PermissionStatus status = await Permission.activityRecognition.request();
    
    if (status.isGranted) {
      // 2. Start listening to the Android pedometer sensor
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
      
      setState(() {
        _isTracking = true;
      });
    } else {
      print("Permission denied");
    }
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
    });
    
    // Optional: Only sync to backend every X steps to save battery and API calls
    if (_steps % 100 == 0) {
      syncStepsToBackend(_steps);
    }
  }

  void onStepCountError(error) {
    print("Pedometer Error: $error");
    setState(() {
      _isTracking = false;
    });
  }

  Future<void> syncStepsToBackend(int stepCount) async {
    final effectiveBase = (!kIsWeb && !kReleaseMode && Platform.isAndroid)
        ? 'http://10.0.2.2:8000'
        : ApiService.baseUrl;
    final url = Uri.parse('$effectiveBase/steps/sync');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Assuming your dependency expects a Bearer token or custom header
          'Authorization': 'Bearer ${widget.authToken}', 
        },
        body: jsonEncode({
          'steps': stepCount,
        }),
      );

      if (response.statusCode == 200) {
        print('Successfully synced steps');
      } else {
        print('Failed to sync: ${response.body}');
      }
    } catch (e) {
      print('Network error syncing steps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Android Step Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              _isTracking ? 'Steps Taken' : 'Sensor Not Active',
              style: const TextStyle(fontSize: 24),
            ),
            Text(
              '$_steps',
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => syncStepsToBackend(_steps),
              child: const Text('Force Sync to Backend'),
            )
          ],
        ),
      ),
    );
  }
}