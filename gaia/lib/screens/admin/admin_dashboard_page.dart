import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await ApiService.getAdminDashboardSummary();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains("403")) {
      return "Access denied. Admin privileges required.";
    }
    if (message.contains("401")) {
      return "Authentication required. Please log in.";
    }
    if (message.contains("SocketException")) {
      return "Unable to reach the server. Is the backend running?";
    }
    return "Unable to load dashboard data. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.gray.shade100,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: textTheme.headlineSmall),
        backgroundColor: AppColors.white,
        elevation: 1,
        foregroundColor: AppColors.gray.shade900,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, Routes.adminDoctors);
              },
              icon: const Icon(Icons.medical_services_outlined),
              label: const Text('Manage Doctors'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDashboardContent(isWeb),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.gray.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadDashboardData();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(bool isWeb) {
    final totalUsers = _dashboardData?['total_users'] ?? 0;
    final totalDoctors = _dashboardData?['total_doctors'] ?? 0;
    final activeDoctors = _dashboardData?['active_doctors'] ?? 0;
    final totalAssessments = _dashboardData?['total_assessments'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildStatsGrid(
            isWeb: isWeb,
            stats: [
              _StatCard(
                title: 'Total Users',
                value: totalUsers.toString(),
                icon: Icons.people_outline,
                color: AppColors.purple,
              ),
              _StatCard(
                title: 'Total Doctors',
                value: totalDoctors.toString(),
                icon: Icons.medical_services_outlined,
                color: AppColors.turquoise,
              ),
              _StatCard(
                title: 'Active Doctors',
                value: activeDoctors.toString(),
                icon: Icons.verified_user_outlined,
                color: AppColors.orange,
              ),
              _StatCard(
                title: 'Total Assessments',
                value: totalAssessments.toString(),
                icon: Icons.assessment_outlined,
                color: AppColors.pink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required bool isWeb,
    required List<_StatCard> stats,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWeb ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index]),
    );
  }

  Widget _buildStatCard(_StatCard stat) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            colors: [stat.color.shade100, AppColors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: stat.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                stat.icon,
                color: stat.color,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray.shade900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray.shade700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}