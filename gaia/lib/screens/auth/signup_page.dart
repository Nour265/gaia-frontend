import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static const String _googleClientId = String.fromEnvironment(
    "GAIA_GOOGLE_CLIENT_ID",
    defaultValue:
        "466714216329-edlr37blfk69r93n2qa7pqs8b42s5a4l.apps.googleusercontent.com",
  );
  static const String _googleServerClientId = String.fromEnvironment(
    "GAIA_GOOGLE_SERVER_CLIENT_ID",
  );

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _gender;
  String? _preciseLocation;
  bool _isLocating = false;
  final List<String> _genders = const ["male", "female", "other"];
  bool _isLoading = false;
  bool _hasPromptedForLocation = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  bool get _supportsGeolocator {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForPreciseLocation();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _promptForPreciseLocation() async {
    if (!mounted || _hasPromptedForLocation || _preciseLocation != null) return;
    _hasPromptedForLocation = true;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Allow precise location?"),
        content: const Text(
          "GAIA uses your exact location to show nearby doctors on the results map.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Not now"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _capturePreciseLocation();
            },
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePreciseLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      if (!_supportsGeolocator) {
        throw Exception("Precise location is not supported on this platform.");
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled on your device.");
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission was denied.");
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          "Location permission is permanently denied. Enable it in browser or device settings.",
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() {
        _preciseLocation =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            "Location plugin is unavailable in this runtime. Please fully restart the app.";
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parsedAge = int.tryParse(_ageController.text.trim());
      if (parsedAge == null) {
        throw Exception("Invalid age");
      }
      final location = _preciseLocation;
      if (location == null) {
        throw Exception("Please allow location access to continue.");
      }

      await ApiService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        age: parsedAge,
        gender: _gender ?? "other",
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        location: location,
      );

      if (!mounted) return;

      // Redirect based on user role
      final user = AuthSession.user;
      if (user != null && user.isAdmin) {
        Navigator.pushReplacementNamed(context, Routes.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, Routes.landing);
      }
    } catch (error) {
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

  Future<void> _signUpWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb && _googleClientId.isEmpty) {
        throw Exception(
          "Google Web client ID is missing. Run with --dart-define=GAIA_GOOGLE_CLIENT_ID=<your_web_client_id>.",
        );
      }

      final googleSignIn = GoogleSignIn(
        scopes: const ["email", "profile", "openid"],
        clientId: _googleClientId.isEmpty ? null : _googleClientId,
        serverClientId: _googleServerClientId.isEmpty
            ? null
            : _googleServerClientId,
      );

      final account = await googleSignIn.signIn().timeout(
        const Duration(seconds: 60),
      );
      if (account == null) {
        throw Exception("Google sign-in was canceled.");
      }

      final auth = await account.authentication.timeout(
        const Duration(seconds: 20),
      );
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      final ageText = _ageController.text.trim();
      final parsedAge = ageText.isEmpty ? null : int.tryParse(ageText);
      if (ageText.isNotEmpty && parsedAge == null) {
        throw Exception("Invalid age");
      }

      final phone = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();
      final location = _preciseLocation;
      if (location == null) {
        throw Exception("Please allow location access to continue.");
      }

      if (idToken != null && idToken.isNotEmpty) {
        await ApiService.authenticateWithGoogle(
          idToken: idToken,
          age: parsedAge,
          gender: _gender,
          phone: phone,
          location: location,
        );
      } else if (accessToken != null && accessToken.isNotEmpty) {
        await ApiService.authenticateWithGoogleAccessToken(
          accessToken: accessToken,
          age: parsedAge,
          gender: _gender,
          phone: phone,
          location: location,
        );
      } else {
        throw Exception("Google id and access tokens are missing.");
      }

      if (!mounted) return;

      // Redirect based on user role
      final user = AuthSession.user;
      if (user != null && user.isAdmin) {
        Navigator.pushReplacementNamed(context, Routes.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, Routes.landing);
      }
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

  String _friendlyError(Object error) {
    final message = error.toString();
    final backendDetail = _extractBackendDetail(message);

    if (backendDetail != null && backendDetail.isNotEmpty) {
      return backendDetail;
    }

    if (message.contains("Google sign-in was canceled")) {
      return "Google sign-in was canceled.";
    }
    if (message.contains("popup_closed")) {
      return "Google sign-in popup was closed.";
    }
    if (message.contains("popup_blocked")) {
      return "Allow popups for this site to continue with Google sign-in.";
    }
    if (message.contains("idpiframe_initialization_failed")) {
      return "Google sign-in is blocked by browser privacy settings.";
    }
    if (message.contains("Google id token missing")) {
      return "Google sign-in is not fully configured on this app yet.";
    }
    if (message.contains("Google id and access tokens are missing")) {
      return "Google sign-in did not return tokens for this session.";
    }
    if (message.contains("Invalid Google token") ||
        message.contains("Google client id is not allowed")) {
      return "Google sign-in failed. Check OAuth client IDs.";
    }
    if (message.contains("409")) {
      return "Email already registered. Try logging in.";
    }
    if (message.contains("Location is required") ||
        message.contains("Please allow location access")) {
      return "Allow precise location access so we can show nearby doctors.";
    }
    if (message.contains("Precise location is not supported")) {
      return "Precise location is not supported on this platform.";
    }
    if (message.contains("Location services are disabled")) {
      return "Please enable location services on your device/browser.";
    }
    if (message.contains("deniedForever")) {
      return "Location permission is blocked. Enable it in browser settings.";
    }
    if (message.contains("permission was denied")) {
      return "Location permission is required for nearby doctor matching.";
    }
    if (message.contains("Invalid age")) {
      return "Please provide a valid age.";
    }
    if (message.contains("SocketException")) {
      return "Unable to reach the server. Is the backend running?";
    }
    if (message.contains("TimeoutException")) {
      return "Request timed out. Check your backend connection and try again.";
    }

    final cleaned = message.replaceFirst(RegExp(r"^Exception:\s*"), "").trim();
    if (cleaned.isNotEmpty && cleaned != "Exception") {
      return cleaned.length > 180 ? "${cleaned.substring(0, 180)}..." : cleaned;
    }

    return "Unable to create account. Please try again.";
  }

  String? _extractBackendDetail(String message) {
    final detailMatch = RegExp(
      r'''["']detail["']\s*:\s*["']([^"']+)["']''',
    ).firstMatch(message);
    if (detailMatch != null) {
      return detailMatch.group(1);
    }

    final msgMatch = RegExp(
      r'''["']msg["']\s*:\s*["']([^"']+)["']''',
    ).firstMatch(message);
    if (msgMatch != null) {
      return msgMatch.group(1);
    }

    final messageMatch = RegExp(
      r'''["']message["']\s*:\s*["']([^"']+)["']''',
    ).firstMatch(message);
    if (messageMatch != null) {
      return messageMatch.group(1);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: const GaiaNavBarAppBar(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF4E6), Color(0xFFF1ECFF)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          Positioned(
            left: -90,
            top: -90,
            child: _orb(AppColors.orange.shade100, 200),
          ),
          Positioned(
            right: -110,
            bottom: -120,
            child: _orb(AppColors.purple.shade100, 240),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minWidth: size.width < 520 ? size.width - 48 : 360,
                ),
                child: Card(
                  elevation: 10,
                  shadowColor: AppColors.gray.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Create your account",
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppColors.gray.shade900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "Start receiving clearer guidance in minutes.",
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
                          const SizedBox(height: AppSpacing.md),
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
                            initialValue: _gender,
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
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              label: "Password",
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password is required.";
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
                            obscureText: _obscureConfirm,
                            decoration: _inputDecoration(
                              label: "Confirm password",
                              icon: Icons.lock_reset,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please confirm your password.";
                              }
                              if (value != _passwordController.text) {
                                return "Passwords do not match.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              label: "Phone (optional)",
                              icon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.gray.shade100,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.gray.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.my_location_outlined,
                                      size: 18,
                                      color: AppColors.gray.shade800,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      "Precise location",
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  _preciseLocation == null
                                      ? "Allow location access to show doctors exactly around you."
                                      : "Captured: $_preciseLocation",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.gray.shade800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: (_isLoading || _isLocating)
                                        ? null
                                        : _capturePreciseLocation,
                                    icon: _isLocating
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.gps_fixed_rounded,
                                            size: 16,
                                          ),
                                    label: Text(
                                      _preciseLocation == null
                                          ? "Use My Current Location"
                                          : "Refresh Location",
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.turquoise,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
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
                                  : const Text("Create Account"),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signUpWithGoogle,
                              icon: _googleMark(),
                              label: const Text("Sign up with Google"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.gray.shade900,
                                side: BorderSide(
                                  color: AppColors.gray.shade300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                Routes.login,
                              );
                            },
                            child: Text(
                              "Already have an account? Sign in",
                              style: textTheme.labelLarge?.copyWith(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.gray.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _googleMark() {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "G",
        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4285F4)),
      ),
    );
  }
}
