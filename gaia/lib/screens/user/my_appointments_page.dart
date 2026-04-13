import 'package:flutter/material.dart';
import 'package:gaia/screens/appointments/appointment_card.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/widgets/navbar.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  late Future<List<dynamic>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _appointmentsFuture = ApiService.getMyAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Appointments')),
        body: const Center(
            child: Text('Please log in to view your appointments.')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const NavBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<dynamic>>(
                future: _appointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(snapshot.error.toString()),
                          const SizedBox(height: 12),
                          ElevatedButton(
                              onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    );
                  }

                  final appointments = snapshot.data ?? [];

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _AppointmentsHeader(
                          userName: AuthSession.user?.name ?? 'User',
                          count: appointments.length,
                        ),
                      ),
                      if (appointments.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No appointments yet.',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                                SizedBox(height: 8),
                                Text(
                                    'Book one from the assessment results page.',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => AppointmentCard(
                                appointment:
                                    appointments[i] as Map<String, dynamic>,
                                isDoctor: false,
                                onStatusChanged: _reload,
                              ),
                              childCount: appointments.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsHeader extends StatelessWidget {
  const _AppointmentsHeader({required this.userName, required this.count});
  final String userName;
  final int    count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.cyan.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person_outline,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Appointments',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '$count appointment${count == 1 ? '' : 's'}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
