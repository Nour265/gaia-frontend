import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'create_user_dialog.dart';

class AdminDoctorsPage extends StatefulWidget {
  const AdminDoctorsPage({Key? key}) : super(key: key);

  @override
  State<AdminDoctorsPage> createState() => _AdminDoctorsPageState();
}

class _AdminDoctorsPageState extends State<AdminDoctorsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _doctors = [];
  bool? _activeFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _activeFilter = args?['filterActive'] as bool?;
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final all = await ApiService.getDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = _activeFilter == null
            ? all
            : all.where((d) => (d['is_active'] as bool? ?? true) == _activeFilter).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _errorMessage = _friendlyError(error); _isLoading = false; });
    }
  }

  Future<void> _toggleStatus(int id, bool current) async {
    try {
      await ApiService.updateDoctorStatus(doctorId: id, isActive: !current);
      await _loadDoctors();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(current ? 'Doctor deactivated' : 'Doctor activated'),
        backgroundColor: AppColors.turquoise,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${_friendlyError(error)}'),
        backgroundColor: AppColors.pink,
      ));
    }
  }

  Future<void> _deleteDoctor(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Delete Doctor'),
        content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pink),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.deleteUser(userId: id);
      _loadDoctors();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Doctor deleted'),
        backgroundColor: AppColors.turquoise,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${_friendlyError(error)}'),
        backgroundColor: AppColors.pink,
      ));
    }
  }

  Future<void> _showAddDoctorDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateUserDialog(initialRole: 'doctor'),
    );
    if (result == true) _loadDoctors();
  }

  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains("403")) return "Access denied. Admin privileges required.";
    if (msg.contains("401")) return "Authentication required. Please log in.";
    if (msg.contains("SocketException")) return "Unable to reach the server.";
    return "Something went wrong. Please try again.";
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.turquoise.shade100 : AppColors.gray.shade200,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? AppColors.turquoise.shade800 : AppColors.gray.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.gray.shade100,
      appBar: const GaiaNavBarAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildContent(isWeb),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            runSpacing: 12,
            spacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Doctor Management', style: Theme.of(context).textTheme.headlineMedium),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, Routes.adminDashboard),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Dashboard'),
              ),
              ElevatedButton.icon(
                onPressed: _showAddDoctorDialog,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.gray.shade700),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() { _isLoading = true; _errorMessage = null; });
              _loadDoctors();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isWeb) {
    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 64, color: AppColors.gray.shade700),
            const SizedBox(height: 16),
            Text('No doctors found', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      );
    }
    return isWeb ? _buildWebTable() : _buildMobileList();
  }

  Widget _buildWebTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.gray.shade100),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Specialty')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _doctors.map<DataRow>((d) {
                  final isActive = d['is_active'] ?? false;
                  final id = d['id'] as int;
                  final name = d['name'] ?? '';
                  return DataRow(cells: [
                    DataCell(Text(name)),
                    DataCell(Text(d['email'] ?? '')),
                    DataCell(Text(d['specialty'] ?? '-')),
                    DataCell(Text(d['phone'] ?? '-')),
                    DataCell(_statusChip(isActive)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: isActive ? 'Deactivate' : 'Activate',
                          icon: Icon(
                            isActive ? Icons.block_outlined : Icons.check_circle_outline,
                            color: isActive ? AppColors.orange : AppColors.turquoise,
                            size: 20,
                          ),
                          onPressed: () => _toggleStatus(id, isActive),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: Icon(Icons.delete_outline, color: AppColors.pink, size: 20),
                          onPressed: () => _deleteDoctor(id, name),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final d = _doctors[index];
        final isActive = d['is_active'] ?? false;
        final id = d['id'] as int;
        final name = d['name'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
                    _statusChip(isActive),
                  ],
                ),
                const SizedBox(height: 8),
                if (d['specialty'] != null)
                  Row(children: [
                    Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.turquoise),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d['specialty'], style: Theme.of(context).textTheme.bodyMedium)),
                  ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.email_outlined, size: 16, color: AppColors.gray.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(d['email'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
                ]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleStatus(id, isActive),
                        icon: Icon(isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 16),
                        label: Text(isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.pink),
                      onPressed: () => _deleteDoctor(id, name),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
