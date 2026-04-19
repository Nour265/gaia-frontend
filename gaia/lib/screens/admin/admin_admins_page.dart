import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'create_user_dialog.dart';

class AdminAdminsPage extends StatefulWidget {
  const AdminAdminsPage({Key? key}) : super(key: key);

  @override
  State<AdminAdminsPage> createState() => _AdminAdminsPageState();
}

class _AdminAdminsPageState extends State<AdminAdminsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _admins = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await ApiService.getUsers();
      if (!mounted) return;
      setState(() {
        _admins = all.where((u) => u['role'] == 'admin').toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _errorMessage = _err(error); _isLoading = false; });
    }
  }

  Future<void> _toggleStatus(int id, bool current) async {
    try {
      await ApiService.updateUserStatus(userId: id, isActive: !current);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(current ? 'Admin deactivated' : 'Admin activated'),
        backgroundColor: AppColors.turquoise,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${_err(error)}'),
        backgroundColor: AppColors.pink,
      ));
    }
  }

  Future<void> _delete(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Delete Admin'),
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
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Admin deleted'),
        backgroundColor: AppColors.turquoise,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${_err(error)}'),
        backgroundColor: AppColors.pink,
      ));
    }
  }

  Future<void> _showAddAdminDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateUserDialog(initialRole: 'admin'),
    );
    if (result == true) _load();
  }

  String _err(Object e) {
    final s = e.toString();
    if (s.contains("403")) return "Access denied.";
    if (s.contains("401")) return "Authentication required.";
    if (s.contains("400")) return s.contains(":") ? s.split(":").last.trim() : "Bad request.";
    if (s.contains("SocketException")) return "Unable to reach the server.";
    return "Something went wrong.";
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
                    ? _buildError()
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
              Text('Admin Management', style: Theme.of(context).textTheme.headlineMedium),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, Routes.adminDashboard),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Dashboard'),
              ),
              ElevatedButton.icon(
                onPressed: _showAddAdminDialog,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.gray.shade700),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(bool isWeb) {
    if (_admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_outlined, size: 64, color: AppColors.gray.shade700),
            const SizedBox(height: 16),
            Text('No admins found', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      );
    }
    return isWeb ? _buildTable() : _buildList();
  }

  Widget _buildTable() {
    final myId = AuthSession.user?.id;
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
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _admins.map<DataRow>((a) {
                  final isActive = a['is_active'] as bool? ?? true;
                  final id = a['id'] as int;
                  final name = a['name'] as String? ?? '';
                  final isMe = id == myId;
                  return DataRow(cells: [
                    DataCell(Row(children: [
                      Text(name),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('You', style: TextStyle(fontSize: 11, color: AppColors.purple, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ])),
                    DataCell(Text(a['email'] as String? ?? '')),
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
                          onPressed: isMe ? null : () => _toggleStatus(id, isActive),
                        ),
                        IconButton(
                          tooltip: isMe ? 'Cannot delete yourself' : 'Delete',
                          icon: Icon(Icons.delete_outline, color: isMe ? AppColors.gray.shade700 : AppColors.pink, size: 20),
                          onPressed: isMe ? null : () => _delete(id, name),
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

  Widget _buildList() {
    final myId = AuthSession.user?.id;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _admins.length,
      itemBuilder: (_, i) {
        final a = _admins[i];
        final isActive = a['is_active'] as bool? ?? true;
        final id = a['id'] as int;
        final name = a['name'] as String? ?? '';
        final isMe = id == myId;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
                  if (isMe)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.purple.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text('You', style: TextStyle(fontSize: 11, color: AppColors.purple, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 8),
                  _statusChip(isActive),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.email_outlined, size: 16, color: AppColors.gray.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a['email'] as String? ?? '', style: Theme.of(context).textTheme.bodyMedium)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isMe ? null : () => _toggleStatus(id, isActive),
                      icon: Icon(isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 16),
                      label: Text(isActive ? 'Deactivate' : 'Activate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: isMe ? AppColors.gray.shade700 : AppColors.pink),
                    onPressed: isMe ? null : () => _delete(id, name),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}
