import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  // 1. Our Dummy Data
  final List<Map<String, dynamic>> _dummyHistory = [
    {"date": "Today", "steps": 6432},
    {"date": "Yesterday", "steps": 8210},
    {"date": "Monday", "steps": 10450},
    {"date": "Sunday", "steps": 4320},
    {"date": "Saturday", "steps": 12000},
    {"date": "Friday", "steps": 7500},
    {"date": "Thursday", "steps": 9100},
  ];

  @override
  Widget build(BuildContext context) {
    // Notice there is NO PopScope here! We want them to be able to swipe back.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Step History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _dummyHistory.length,
        itemBuilder: (context, index) {
          final item = _dummyHistory[index];
          // Check if they hit the daily 10k goal for UI styling
          bool goalReached = item["steps"] >= 10000;

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5), // GAIA Light purple
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item["date"],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${item["steps"]}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: goalReached ? const Color(0xFF9147ff) : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      goalReached ? Icons.check_circle : Icons.directions_walk,
                      color: goalReached ? const Color(0xFF9147ff) : Colors.grey[500],
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}