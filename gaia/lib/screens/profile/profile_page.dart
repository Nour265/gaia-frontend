import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/values/values.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _idController = TextEditingController();
  final _createdAtController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  String _initialName = "";
  String _initialEmail = "";
  int? _initialAge;
  String? _initialGender;
  String? _initialPhone;
  String? _initialLocation;
  String? _gender;
  final List<String> _genders = const ["male", "female", "other"];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _idController.dispose();
    _createdAtController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      AuthUser? user = AuthSession.user;
      user ??= await ApiService.fetchMe();
      _setFormValues(user);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setFormValues(AuthUser user) {
    _initialName = user.name;
    _initialEmail = user.email;
    _initialAge = user.age;
    _initialGender = user.gender;
    _initialPhone = user.phone;
    _initialLocation = user.location;
    _gender = user.gender;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _ageController.text = user.age?.toString() ?? "";
    _phoneController.text = user.phone ?? "";
    _locationController.text = user.location ?? "";
    _idController.text = user.id.toString();
    _createdAtController.text = user.createdAt ?? "-";
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final ageText = _ageController.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();

    final hasChanges =
        name != _initialName ||
        email != _initialEmail ||
        password.isNotEmpty ||
        age != _initialAge ||
        _gender != _initialGender ||
        phone != (_initialPhone ?? "") ||
        location != (_initialLocation ?? "");

    if (!hasChanges) {
      setState(() {
        _successMessage = "Nothing to update.";
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = await ApiService.updateProfile(
        name: name != _initialName ? name : null,
        email: email != _initialEmail ? email : null,
        password: password.isNotEmpty ? password : null,
        age: age != _initialAge ? age : null,
        gender: _gender != _initialGender ? _gender : null,
        phone: phone != (_initialPhone ?? "") ? phone : null,
        location: location != (_initialLocation ?? "") ? location : null,
      );
      _setFormValues(user);
      _passwordController.clear();
      _confirmController.clear();
      if (!mounted) return;
      setState(() {
        _successMessage = "Profile updated.";
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _logout() {
    AuthSession.clear();
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.landing,
      (route) => false,
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains("401")) {
      return "Session expired. Please sign in again.";
    }
    if (message.contains("409")) {
      return "Email already registered.";
    }
    if (message.contains("Invalid age")) {
      return "Please provide a valid age.";
    }
    if (message.contains("SocketException")) {
      return "Unable to reach the server. Is the backend running?";
    }
    return "Unable to update profile. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray.shade900,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    elevation: 8,
                    shadowColor: AppColors.gray.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Account details",
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              "Update your name, email, or password.",
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppColors.gray.shade800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                label: "Full name",
                                icon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Name is required.";
                                }
                                if (value.trim().length < 2) {
                                  return "Name is too short.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                label: "Email",
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email is required.";
                                }
                                if (!value.contains("@")) {
                                  return "Enter a valid email.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                label: "Age",
                                icon: Icons.cake_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Age is required.";
                                }
                                final parsed = int.tryParse(value.trim());
                                if (parsed == null) {
                                  return "Enter a valid age.";
                                }
                                if (parsed < 0 || parsed > 120) {
                                  return "Age must be between 0 and 120.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: _inputDecoration(
                                label: "Sex",
                                icon: Icons.wc_outlined,
                              ),
                              items: _genders
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(
                                        gender[0].toUpperCase() +
                                            gender.substring(1),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Sex is required.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration(
                                label: "Phone",
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _locationController,
                              decoration: _inputDecoration(
                                label: "Location",
                                icon: Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              "Account info",
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _idController,
                              readOnly: true,
                              decoration: _inputDecoration(
                                label: "User ID",
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _createdAtController,
                              readOnly: true,
                              decoration: _inputDecoration(
                                label: "Member since",
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              "Change password",
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: _inputDecoration(
                                label: "New password",
                                icon: Icons.lock_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                if (value.length < 8) {
                                  return "Password must be at least 8 characters.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: true,
                              decoration: _inputDecoration(
                                label: "Confirm password",
                                icon: Icons.lock_reset,
                              ),
                              validator: (value) {
                                if (_passwordController.text.isEmpty) {
                                  return null;
                                }
                                if (value == null || value.isEmpty) {
                                  return "Confirm your new password.";
                                }
                                if (value != _passwordController.text) {
                                  return "Passwords do not match.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_errorMessage != null) ...[
                              Text(
                                _errorMessage!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            if (_successMessage != null) ...[
                              Text(
                                _successMessage!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.purple,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.white,
                                          ),
                                        ),
                                      )
                                    : const Text("Save Changes"),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton(
                              onPressed: _logout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.gray.shade900,
                                side: BorderSide(
                                  color: AppColors.gray.shade300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Log Out"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.gray.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
