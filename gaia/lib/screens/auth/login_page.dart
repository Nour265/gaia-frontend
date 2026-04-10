import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _googleClientId = String.fromEnvironment(
    "GAIA_GOOGLE_CLIENT_ID",
    defaultValue:
        "466714216329-edlr37blfk69r93n2qa7pqs8b42s5a4l.apps.googleusercontent.com",
  );
  static const String _googleServerClientId = String.fromEnvironment(
    "GAIA_GOOGLE_SERVER_CLIENT_ID",
  );

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      _redirectAfterAuth();
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

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb && _googleClientId.isEmpty) {
        throw Exception(
          "Google Web client ID is missing. Run with --dart-define=GAIA_GOOGLE_CLIENT_ID=859555287794-ecjlafnvnccemsgqj715ho4spfm55d3h.apps.googleusercontent.com.",
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

      if (idToken != null && idToken.isNotEmpty) {
        await ApiService.authenticateWithGoogle(idToken: idToken);
      } else if (accessToken != null && accessToken.isNotEmpty) {
        await ApiService.authenticateWithGoogleAccessToken(
          accessToken: accessToken,
        );
      } else {
        throw Exception("Google id and access tokens are missing.");
      }

      _redirectAfterAuth();
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

  void _redirectAfterAuth() {
    if (!mounted) return;
    final user = AuthSession.user;
    if (user != null && user.isAdmin) {
      Navigator.pushReplacementNamed(context, Routes.adminDashboard);
    } else {
      // NEW LOGIC: Check if it is running on Web or Mobile
      if (kIsWeb) {
        Navigator.pushReplacementNamed(context, Routes.landing);
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/mobile_dashboard', 
          (route) => false,
        );
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

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
    if (message.contains("Invalid Google token") ||
        message.contains("Google client id is not allowed")) {
      return "Google sign-in failed. Check OAuth client IDs.";
    }
    if (message.contains("TimeoutException")) {
      return "Request timed out. Check your backend connection and try again.";
    }
    if (message.contains("401")) {
      return "Invalid email or password.";
    }
    if (message.contains("SocketException")) {
      return "Unable to reach the server. Is the backend running?";
    }
    return "Unable to sign in. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: kIsWeb ? const GaiaNavBarAppBar() : null,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6F0FF), Color(0xFFE8FBFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -120,
            top: -80,
            child: _orb(AppColors.purple.shade100, 220),
          ),
          Positioned(
            left: -80,
            bottom: -100,
            child: _orb(AppColors.turquoise.shade100, 200),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 460,
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
                            "Welcome back",
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppColors.gray.shade900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "Sign in to continue your health journey.",
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.gray.shade800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
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
                          // Only show forgot password on web
                          if (kIsWeb)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    Routes.forgotPassword,
                                  );
                                },
                                child: Text(
                                  "Forgot password?",
                                  style: textTheme.labelLarge?.copyWith(
                                    color: AppColors.gray.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
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
                                backgroundColor: AppColors.purple,
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
                                  : const Text("Sign In"),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Google signin only available on web
                          if (kIsWeb)
                            SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                icon: _googleMark(),
                                label: const Text("Continue with Google"),
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
                          // Web: Show the clickable Sign Up button
                          if (kIsWeb)
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, Routes.signup);
                              },
                              child: Text(
                                "New here? Create an account",
                                style: textTheme.labelLarge?.copyWith(
                                  color: AppColors.turquoise,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          
                          // Mobile: Show the text directing them to the website
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Center(
                                child: Text(
                                  "Don't have an account?\nPlease visit the GAIA website to register.",
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.gray.shade800,
                                  ),
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
    ));
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
