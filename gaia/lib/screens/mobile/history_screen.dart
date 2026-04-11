import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStepsHistory();
  }

  Future<void> _fetchStepsHistory() async {
    if (AuthSession.token == null || AuthSession.token!.isEmpty) {
      setState(() {
        _error = 'No auth token available';
        _isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/steps/history');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${AuthSession.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = data['records'] as List;

        setState(() {
          _history = records.map((record) {
            final date = DateTime.parse(record['record_date'] as String);
            final formattedDate = _formatDate(date);
            return {
              'date': formattedDate,
              'steps': record['steps'] as int,
              'record_date': date,
            };
          }).toList();
          _isLoading = false;
          _error = null;
        });
        print('✅ Loaded ${_history.length} step records from database');
      } else {
        setState(() {
          _error = 'Failed to load history';
          _isLoading = false;
        });
        print('❌ Failed to fetch history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
      print('❌ Network error fetching history: $e');
    }
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9147ff)),
              ),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : _history.isEmpty
                  ? const Center(
                      child: Text(
                        'No step records yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        bool goalReached = item["steps"] >= 10000;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
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
                                      color: goalReached
                                          ? const Color(0xFF9147ff)
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    goalReached
                                        ? Icons.check_circle
                                        : Icons.directions_walk,
                                    color: goalReached
                                        ? const Color(0xFF9147ff)
                                        : Colors.grey[500],
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