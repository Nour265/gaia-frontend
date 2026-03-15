import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';
import 'create_doctor_dialog.dart';

class AdminDoctorsPage extends StatefulWidget {
  const AdminDoctorsPage({Key? key}) : super(key: key);

  @override
  State<AdminDoctorsPage> createState() => _AdminDoctorsPageState();
}

class _AdminDoctorsPageState extends State<AdminDoctorsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await ApiService.getDoctors();
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDoctorStatus(int doctorId, bool currentStatus) async {
    try {
      await ApiService.updateDoctorStatus(
        doctorId: doctorId,
        isActive: !currentStatus,
      );
      // Reload the doctors list to reflect the change
      _loadDoctors();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus ? 'Doctor deactivated successfully' : 'Doctor activated successfully',
          ),
          backgroundColor: AppColors.turquoise,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating doctor status: ${_friendlyError(error)}'),
          backgroundColor: AppColors.pink,
        ),
      );
    }
  }

  Future<void> _showCreateDoctorDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateDoctorDialog(),
    );
    
    if (result == true) {
      _loadDoctors(); // Refresh the list
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
    return "Unable to load doctors. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.gray.shade100,
      appBar: AppBar(
        title: Text('Doctor Management', style: textTheme.headlineSmall),
        backgroundColor: AppColors.white,
        elevation: 1,
        foregroundColor: AppColors.gray.shade900,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.adminDashboard);
              },
              icon: const Icon(Icons.dashboard_outlined),
              tooltip: 'Go to Dashboard',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showCreateDoctorDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Doctor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
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
              : _buildDoctorsContent(isWeb),
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
              _loadDoctors();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsContent(bool isWeb) {
    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: AppColors.gray.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'No doctors found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add the first doctor using the button above',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray.shade700,
                  ),
            ),
          ],
        ),
      );
    }

    return isWeb ? _buildWebTable() : _buildMobileList();
  }

  Widget _buildWebTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.gray.shade100),
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _doctors.map<DataRow>((doctor) {
              final isActive = doctor['is_active'] ?? false;
              return DataRow(
                cells: [
                  DataCell(Text(doctor['name'] ?? '')),
                  DataCell(Text(doctor['email'] ?? '')),
                  DataCell(Text(doctor['phone'] ?? '-')),
                  DataCell(Text(doctor['location'] ?? '-')),
                  DataCell(_buildStatusChip(isActive)),
                  DataCell(_buildActionButton(doctor['id'], isActive)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        final isActive = doctor['is_active'] ?? false;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        doctor['name'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _buildStatusChip(isActive),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email_outlined, doctor['email'] ?? ''),
                if (doctor['phone'] != null && doctor['phone'].isNotEmpty)
                  _buildInfoRow(Icons.phone_outlined, doctor['phone']),
                if (doctor['location'] != null && doctor['location'].isNotEmpty)
                  _buildInfoRow(Icons.location_on_outlined, doctor['location']),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(doctor['id'], isActive),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.gray.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray.shade700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.turquoise.shade100 : AppColors.gray.shade200,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive ? AppColors.turquoise.shade800 : AppColors.gray.shade700,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildActionButton(int doctorId, bool isActive) {
    return ElevatedButton.icon(
      onPressed: () => _toggleDoctorStatus(doctorId, isActive),
      icon: Icon(isActive ? Icons.block : Icons.check_circle_outline),
      label: Text(isActive ? 'Deactivate' : 'Activate'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? AppColors.pink : AppColors.turquoise,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}