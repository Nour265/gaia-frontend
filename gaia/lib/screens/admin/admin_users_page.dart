import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'create_user_dialog.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _changeRole(int userId, String currentRole) async {
    final roles = ['user', 'doctor', 'admin'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Role'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        children: roles.map((role) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, role),
            child: Row(
              children: [
                _roleIcon(role),
                const SizedBox(width: 12),
                Text(
                  role[0].toUpperCase() + role.substring(1),
                  style: TextStyle(
                    fontWeight: role == currentRole
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (role == currentRole) ...[
                  const Spacer(),
                  Icon(Icons.check, size: 16, color: AppColors.turquoise),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (selected == null || selected == currentRole) return;

    try {
      await ApiService.updateUserRole(userId: userId, role: selected);
      _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role updated to $selected'),
          backgroundColor: AppColors.turquoise,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_friendlyError(error)}'),
          backgroundColor: AppColors.pink,
        ),
      );
    }
  }

  Future<void> _toggleStatus(int userId, bool currentStatus) async {
    try {
      await ApiService.updateUserStatus(userId: userId, isActive: !currentStatus);
      _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'User deactivated' : 'User activated'),
          backgroundColor: AppColors.turquoise,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_friendlyError(error)}'),
          backgroundColor: AppColors.pink,
        ),
      );
    }
  }

  Future<void> _deleteUser(int userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
      await ApiService.deleteUser(userId: userId);
      _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted'),
          backgroundColor: AppColors.turquoise,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_friendlyError(error)}'),
          backgroundColor: AppColors.pink,
        ),
      );
    }
  }

  Future<void> _showCreateUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );
    if (result == true) _loadUsers();
  }

  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains("403")) return "Access denied. Admin privileges required.";
    if (msg.contains("401")) return "Authentication required. Please log in.";
    if (msg.contains("400")) return msg.contains(":") ? msg.split(":").last.trim() : "Bad request.";
    if (msg.contains("SocketException")) return "Unable to reach the server.";
    return "Something went wrong. Please try again.";
  }

  Widget _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icon(Icons.admin_panel_settings_outlined, size: 18, color: AppColors.purple);
      case 'doctor':
        return Icon(Icons.medical_services_outlined, size: 18, color: AppColors.turquoise);
      default:
        return Icon(Icons.person_outline, size: 18, color: AppColors.gray.shade700);
    }
  }

  Widget _roleChip(String role) {
    Color bg;
    Color fg;
    switch (role) {
      case 'admin':
        bg = AppColors.purple.shade100;
        fg = AppColors.purple.shade800;
        break;
      case 'doctor':
        bg = AppColors.turquoise.shade100;
        fg = AppColors.turquoise.shade800;
        break;
      default:
        bg = AppColors.gray.shade200;
        fg = AppColors.gray.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
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
      child: Wrap(
        runSpacing: 12,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('User Management', style: Theme.of(context).textTheme.headlineMedium),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Routes.adminDashboard),
            icon: const Icon(Icons.dashboard_outlined),
            label: const Text('Dashboard'),
          ),
          ElevatedButton.icon(
            onPressed: _showCreateUserDialog,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
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
              _loadUsers();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isWeb) {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.gray.shade700),
            const SizedBox(height: 16),
            Text('No users found', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      );
    }
    return isWeb ? _buildWebTable() : _buildMobileList();
  }

  Widget _buildWebTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _users.map<DataRow>((u) {
              final isActive = u['is_active'] ?? false;
              final role = u['role'] ?? 'user';
              final id = u['id'] as int;
              final name = u['name'] ?? '';
              return DataRow(cells: [
                DataCell(Text(name)),
                DataCell(Text(u['email'] ?? '')),
                DataCell(
                  GestureDetector(
                    onTap: () => _changeRole(id, role),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _roleChip(role),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_outlined, size: 14, color: AppColors.gray.shade700),
                      ],
                    ),
                  ),
                ),
                DataCell(_statusChip(isActive)),
                DataCell(Text(u['phone'] ?? '-')),
                DataCell(Text(u['location'] ?? '-')),
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
                      onPressed: () => _deleteUser(id, name),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final u = _users[index];
        final isActive = u['is_active'] ?? false;
        final role = u['role'] ?? 'user';
        final id = u['id'] as int;
        final name = u['name'] ?? '';

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
                    Expanded(
                      child: Text(name, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    _statusChip(isActive),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 16, color: AppColors.gray.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(u['email'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _roleChip(role),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _changeRole(id, role),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Change Role'),
                    ),
                  ],
                ),
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
                      onPressed: () => _deleteUser(id, name),
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
