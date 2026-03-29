import 'package:flutter/material.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/constants/specialties.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({Key? key}) : super(key: key);

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedRole = 'user';
  String? _selectedSpecialty;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _roles = ['user', 'doctor', 'admin'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        specialty: _selectedRole == 'doctor' ? _selectedSpecialty : null,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedRole[0].toUpperCase()}${_selectedRole.substring(1)} created successfully'),
          backgroundColor: AppColors.turquoise,
        ),
      );
    } catch (error) {
      setState(() {
        final msg = error.toString();
        if (msg.contains("409")) {
          _errorMessage = "A user with this email already exists.";
        } else if (msg.contains("403")) {
          _errorMessage = "Access denied. Admin privileges required.";
        } else if (msg.contains("401")) {
          _errorMessage = "Authentication required. Please log in.";
        } else if (msg.contains("SocketException")) {
          _errorMessage = "Unable to reach the server.";
        } else {
          _errorMessage = "Unable to create user. Please try again.";
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppColors.purple;
      case 'doctor': return AppColors.turquoise;
      default: return AppColors.gray.shade600;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin': return Icons.admin_panel_settings_outlined;
      case 'doctor': return Icons.medical_services_outlined;
      default: return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Container(
        width: isWide ? 500 : double.infinity,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.person_add_outlined, color: AppColors.purple, size: 28),
                    const SizedBox(width: 12),
                    Text('Add New User', style: textTheme.headlineSmall),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                      color: AppColors.gray.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Error banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pink.shade100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.pink.shade800),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.pink.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: textTheme.bodyMedium?.copyWith(color: AppColors.pink.shade800)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.gray.shade700,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role selector
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(_roleIcon(_selectedRole), color: _roleColor(_selectedRole)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: AppColors.gray.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: AppColors.gray.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: AppColors.purple, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(_roleIcon(role), size: 18, color: _roleColor(role)),
                          const SizedBox(width: 10),
                          Text(role[0].toUpperCase() + role.substring(1)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _selectedRole = v ?? 'user';
                    if (_selectedRole != 'doctor') _selectedSpecialty = null;
                  }),
                ),
                if (_selectedRole == 'doctor') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    decoration: InputDecoration(
                      labelText: 'Specialty',
                      prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.turquoise),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: AppColors.gray.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: AppColors.gray.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: AppColors.turquoise, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    hint: const Text('Select specialty'),
                    items: kDoctorSpecialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedSpecialty = v),
                    validator: (_) => _selectedRole == 'doctor' && _selectedSpecialty == null ? 'Specialty is required for doctors' : null,
                  ),
                ],
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location (Optional)',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm)),
                          side: BorderSide(color: AppColors.gray.shade300),
                        ),
                        child: Text('Cancel',
                            style: textTheme.titleMedium?.copyWith(color: AppColors.gray.shade700)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(AppColors.white)),
                              )
                            : Text('Create User',
                                style: textTheme.titleMedium?.copyWith(color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.gray.shade700),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.gray.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.gray.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.pink, width: 2),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }
}
