import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';

import 'history_screen.dart';
class MobileDashboard extends StatefulWidget {
  const MobileDashboard({super.key});

  @override
  State<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<MobileDashboard> {
  late Stream<StepCount> _stepCountStream;
  String _steps = '?';
  int _currentSteps = 0;
  
  // Variable to hold the giant initial hardware number
  int _startingLineSteps = 0;
  
  // For syncing steps every 100 steps
  int _lastSyncedSteps = 0;
  bool _isSyncing = false;
  String? _syncError;
  
  // Track if we've fetched database steps to avoid resetting them
  bool _hasFetchedDatabaseSteps = false;

  int _waterIntakeMl = 0;
  final int _dailyWaterGoalMl = 2500;

  // --- Water Tracking Methods ---
  void _addWater() {
    setState(() {
      _waterIntakeMl += 250;
    });
    _syncWaterToBackend(); // Silently syncs to DB
  }

  void _removeWater() {
    if (_waterIntakeMl >= 250) {
      setState(() {
        _waterIntakeMl -= 250;
      });
      _syncWaterToBackend(); // Silently syncs to DB
    }
  }

  StreamSubscription<StepCount>? _stepCountSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
  // Wait for the database fetch to finish FIRST
  await _fetchTodaysStepsFromDatabase();
  
  await _fetchTodaysWaterFromDatabase();
  // THEN start the pedometer logic
  await checkPermissionsAndStart();
}

  Future<void> _fetchTodaysStepsFromDatabase() async {
    // Fetch today's steps from the backend to restore them if the user logged out and back in
    if (AuthSession.token == null || AuthSession.token!.isEmpty) {
      print('⚠️  No auth token, skipping fetch');
      return;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/steps/today');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${AuthSession.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dbSteps = data['steps'] as int;
        setState(() {
          _currentSteps = dbSteps;
          _lastSyncedSteps = dbSteps;
          _steps = dbSteps.toString();
          _hasFetchedDatabaseSteps = true;
        });
        print('✅ Fetched today\'s steps from database: $dbSteps');
      }
    } catch (e) {
      print('⚠️  Failed to fetch today\'s steps: $e');
    }
  }

  Future<void> _fetchTodaysWaterFromDatabase() async {
    try {
      // Accessing the static variable directly, no 'await' needed
      final token = AuthSession.token; 
      
      if (token != null) {
        final fetchedWater = await ApiService.fetchTodaysWater(token);
        setState(() {
          _waterIntakeMl = fetchedWater;
        });
      }
    } catch (e) {
      print("Failed to fetch water: $e");
    }
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

  Future<void> _syncWaterToBackend() async {
    try {
      // Accessing the static variable directly
      final token = AuthSession.token; 
      
      if (token != null) {
        await ApiService.syncWater(token, _waterIntakeMl);
      }
    } catch (e) {
      print("Failed to sync water: $e");
    }
  }

  void initPedometer() {
    _stepCountSubscription = Pedometer.stepCountStream.listen(
    (StepCount event) {
      setState(() {
        // 5. Handle Device Reboot edge case (hardware counter reset)
        if (event.steps < _startingLineSteps) {
           // If hardware resets, we adjust the starting line so we don't get negative steps
           _startingLineSteps = event.steps - _currentSteps;
        }

        if (_startingLineSteps == 0) {
          if (_hasFetchedDatabaseSteps && _currentSteps > 0) {
            _startingLineSteps = event.steps - _currentSteps;
          } else {
            _startingLineSteps = event.steps;
            _lastSyncedSteps = 0;
          }
        }

        int actualStepsTakenToday = event.steps - _startingLineSteps;
        _currentSteps = actualStepsTakenToday;
        _steps = actualStepsTakenToday.toString();
      });
      
      if ((_currentSteps - _lastSyncedSteps) >= 100) {
        _syncStepsToBackend();
      }
    },
  )..onError( // Note: use cascade operator (..) for onError when assigning to a variable
    (error) {
      setState(() {
        _steps = '0';
      });
      print("Pedometer Error: $error");
    },
  );
}
@override
void dispose() {
  _stepCountSubscription?.cancel();
  super.dispose();
}
  Future<void> _syncStepsToBackend() async {
    // Only sync if we have an auth token
    if (AuthSession.token == null || AuthSession.token!.isEmpty) {
      print('❌ Sync failed: No auth token available');
      return;
    }

    // Don't sync if no new steps since last sync
    if (_currentSteps <= _lastSyncedSteps) {
      print('⏭️  Skipping sync: Not 100+ steps yet ($_currentSteps - $_lastSyncedSteps < 100)');
      return;
    }

    setState(() => _isSyncing = true);

    print('🔄 Syncing steps to backend...');
    print('  📍 URL: ${ApiService.baseUrl}/steps/sync');
    print('  👟 Steps: $_currentSteps');
    print('  🔐 Token: ${AuthSession.token?.substring(0, 20)}...');

    try {
      final url = Uri.parse('${ApiService.baseUrl}/steps/sync');
      final body = jsonEncode({'steps': _currentSteps});
      
      print('  📤 Sending POST request...');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('  📥 Response status: ${response.statusCode}');
      print('  📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _lastSyncedSteps = _currentSteps;
          _syncError = null;
          _isSyncing = false;
        });
        print('✅ Steps synced successfully: $_currentSteps');
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Unknown error';
        print('❌ Failed to sync steps: $error');
        setState(() {
          _syncError = 'Sync failed: $error';
          _isSyncing = false;
        });
      }
    } catch (e) {
      print('❌ Network error syncing steps: $e');
      setState(() {
        _syncError = 'Network error: $e';
        _isSyncing = false;
      });
    }
  }

  Future<void> _logout() async {
    // Clear auth session
    AuthSession.token = null;
    AuthSession.user = null;
    
    // Navigate back to login
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 🛑 Disables the system back swipe
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
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
                          const SizedBox(height: 15),
                          // Sync status indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSyncing)
                                const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9147ff)),
                                  ),
                                )
                              else if (_syncError != null)
                                const Icon(Icons.error_outline, color: Colors.red, size: 16)
                              else
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _isSyncing 
                                  ? 'Syncing...' 
                                  : (_syncError != null ? 'Sync failed' : 'In sync'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _syncError != null ? Colors.red : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          // Show error message if present
                          if (_syncError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _syncError!,
                              style: const TextStyle(color: Colors.red, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // --- Water Tracker Card ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD), // Light blue theme
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Hydration Goal: 2,000 ml", 
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "$_waterIntakeMl", 
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)
                          ),
                          const Text(
                            "ml Logged", 
                            style: TextStyle(color: Colors.grey)
                          ),
                          const SizedBox(height: 20),
                          
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              // Clamp prevents the bar from breaking if they drink over the goal
                              value: (_waterIntakeMl / _dailyWaterGoalMl).clamp(0.0, 1.0),
                              minHeight: 12,
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Remove Water Button
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red[300],
                                iconSize: 32,
                                onPressed: _waterIntakeMl > 0 ? _removeWater : null, // Disables if 0
                              ),
                              
                              // Add Water Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                ),
                                onPressed: _addWater,
                                icon: const Icon(Icons.local_drink, color: Colors.white),
                                label: const Text(
                                  '+ 250ml', 
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Manual Sync Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9147ff),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSyncing ? null : _syncStepsToBackend,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSyncing)
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              const Icon(Icons.cloud_upload, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _isSyncing ? 'Syncing...' : 'Sync Steps Now',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    // View History Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9147ff),
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
            // Logo - positioned in top left
            Positioned(
              top: 30,
              left: 30,
              child: Image.asset('assets/images/logo.png', height: 75),
            ),
            // Logout Button - positioned in top right
            Positioned(
              top: 40,
              right: 30,
              child: SizedBox(
                width: 50,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _logout,
                  child: const Icon(Icons.logout, size: 20, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}