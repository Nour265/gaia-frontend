import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/services/auth_session.dart';

class GaiaNavBarAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GaiaNavBarAppBar({Key? key, this.showLogin = true}) : super(key: key);

  final bool showLogin;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width < 980
        ? width - (AppSpacing.md * 2)
        : width * 0.7;

    return Container(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: SizedBox(
            width: contentWidth.clamp(300.0, width).toDouble(),
            child: NavBar(showLogin: showLogin),
          ),
        ),
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  const NavBar({Key? key, this.showLogin = true}) : super(key: key);

  final bool showLogin;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return SizedBox(
      height: 72.0,
      child: isMobile
          ? _buildMobileRow(context)
          : _buildDesktopRow(context),
    );
  }

  Widget _buildDesktopRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Logo(),
              const SizedBox(width: 24.0),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildItems(context, textTheme),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16.0),
        if (showLogin) const ImageLinks(),
      ],
    );
  }

  Widget _buildMobileRow(BuildContext context) {
    return Row(
      children: [
        const Logo(),
        const Spacer(),
        if (showLogin)
          IconButton(
            onPressed: () => _openMobileMenu(context),
            icon: Icon(Icons.menu, color: AppColors.gray.shade800, size: 26),
            tooltip: 'Menu',
          ),
      ],
    );
  }

  void _openMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MobileNavSheet(parentContext: context),
    );
  }

  Row _buildItems(BuildContext context, TextTheme textTheme) {
    final itemStyle = textTheme.bodyMedium;
    final user = AuthSession.user;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavItem(
          label: 'About',
          style: itemStyle,
          onTap: () => Navigator.pushNamed(context, Routes.about),
        ),
        const SizedBox(width: 24.0),
        NavItem(
          label: 'Contact',
          style: itemStyle,
          onTap: () => Navigator.pushNamed(context, Routes.contact),
        ),
        const SizedBox(width: 24.0),
        NavItem(
          label: 'Blog',
          style: itemStyle,
          onTap: () => Navigator.pushNamed(context, Routes.blog),
        ),
        const SizedBox(width: 24.0),
        NavItem(
          label: 'Symptoms',
          style: itemStyle,
          onTap: () => Navigator.pushNamed(context, Routes.symptoms),
        ),
        const SizedBox(width: 24.0),
        NavItem(
          label: 'Health Tracking',
          style: itemStyle,
          onTap: () => Navigator.pushNamed(context, Routes.healthTracking),
        ),
        if (user != null && user.isDoctor) ...[
          const SizedBox(width: 24.0),
          NavItem(
            label: 'My Dashboard',
            style: itemStyle?.copyWith(color: AppColors.purple, fontWeight: FontWeight.w600),
            onTap: () => Navigator.pushNamed(context, Routes.doctorDashboard),
          ),
        ] else if (user != null) ...[
          const SizedBox(width: 24.0),
          NavItem(
            label: 'My Appointments',
            style: itemStyle?.copyWith(color: AppColors.turquoise, fontWeight: FontWeight.w600),
            onTap: () => Navigator.pushNamed(context, Routes.myAppointments),
          ),
        ],
      ],
    );
  }
}

// ── Mobile bottom-sheet nav ───────────────────────────────────────────────────

class _MobileNavSheet extends StatelessWidget {
  const _MobileNavSheet({required this.parentContext});

  final BuildContext parentContext;

  void _go(String route) {
    Navigator.pop(parentContext); // close sheet
    Navigator.pushNamed(parentContext, route);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.user;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Logo
          const Logo(),
          const SizedBox(height: 20),
          Divider(color: AppColors.gray.shade200),
          const SizedBox(height: 8),

          // Nav items
          _SheetItem(label: 'About', icon: Icons.info_outline,
              onTap: () => _go(Routes.about)),
          _SheetItem(label: 'Contact', icon: Icons.chat_bubble_outline,
              onTap: () => _go(Routes.contact)),
          _SheetItem(label: 'Blog', icon: Icons.article_outlined,
              onTap: () => _go(Routes.blog)),
          _SheetItem(label: 'Symptoms', icon: Icons.health_and_safety_outlined,
              onTap: () => _go(Routes.symptoms)),
          _SheetItem(label: 'Health Tracking', icon: Icons.monitor_heart_outlined,
              onTap: () => _go(Routes.healthTracking)),

          if (user != null && user.isDoctor)
            _SheetItem(
              label: 'My Dashboard',
              icon: Icons.dashboard_outlined,
              onTap: () => _go(Routes.doctorDashboard),
              color: AppColors.purple,
            )
          else if (user != null)
            _SheetItem(
              label: 'My Appointments',
              icon: Icons.calendar_today_outlined,
              onTap: () => _go(Routes.myAppointments),
              color: AppColors.turquoise,
            ),

          const SizedBox(height: 8),
          Divider(color: AppColors.gray.shade200),
          const SizedBox(height: 8),

          // Auth section
          ValueListenableBuilder<AuthUser?>(
            valueListenable: AuthSession.userNotifier,
            builder: (context, authUser, _) {
              if (authUser != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (authUser.isAdmin)
                      _SheetItem(
                        label: 'Dashboard',
                        icon: Icons.admin_panel_settings_outlined,
                        onTap: () => _go(Routes.adminDashboard),
                      ),
                    _SheetItem(
                      label: 'Profile',
                      icon: Icons.person_outline,
                      onTap: () => _go(Routes.profile),
                    ),
                    _SheetItem(
                      label: 'Logout',
                      icon: Icons.logout,
                      onTap: () {
                        Navigator.pop(parentContext);
                        AuthSession.clear();
                        Navigator.pushNamedAndRemoveUntil(
                          parentContext,
                          Routes.landing,
                          (route) => false,
                        );
                      },
                      color: Colors.red.shade600,
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetItem(label: 'Login', icon: Icons.login,
                      onTap: () => _go(Routes.login)),
                  _SheetItem(label: 'Sign Up', icon: Icons.person_add_alt_1,
                      onTap: () => _go(Routes.signup)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final effectiveColor = color ?? AppColors.gray.shade800;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: effectiveColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Existing widgets (unchanged) ──────────────────────────────────────────────

class ImageLinks extends StatelessWidget {
  const ImageLinks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthSession.userNotifier,
      builder: (context, user, _) {
        if (user != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.isAdmin) ...[
                _LoginButton(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  textTheme: textTheme,
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.adminDashboard);
                  },
                ),
              ],
              _LoginButton(
                label: 'Profile',
                icon: Icons.person_outline,
                textTheme: textTheme,
                onPressed: () {
                  Navigator.pushNamed(context, Routes.profile);
                },
              ),
              const SizedBox(width: 12),
              _LoginButton(
                label: 'Logout',
                icon: Icons.logout,
                textTheme: textTheme,
                onPressed: () {
                  AuthSession.clear();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.landing,
                    (route) => false,
                  );
                },
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LoginButton(
              label: 'Login',
              icon: Icons.login,
              textTheme: textTheme,
              onPressed: () {
                Navigator.pushNamed(context, Routes.login);
              },
            ),
            const SizedBox(width: 12),
            _LoginButton(
              label: 'Sign Up',
              icon: Icons.person_add_alt_1,
              textTheme: textTheme,
              onPressed: () {
                Navigator.pushNamed(context, Routes.signup);
              },
            ),
          ],
        );
      },
    );
  }
}

class Logo extends StatelessWidget {
  const Logo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (currentRoute == Routes.landing) {
            return;
          }
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.landing,
            (route) => false,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(ImagePath.logo, width: 44, height: 44, fit: BoxFit.contain),
            const SizedBox(width: 10.0),
            Text('GAIA', style: textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _LoginButton extends StatefulWidget {
  const _LoginButton({
    Key? key,
    required this.label,
    required this.textTheme,
    this.icon = Icons.login,
    this.onPressed,
  }) : super(key: key);

  final String label;
  final TextTheme textTheme;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final textColor = _hovered
        ? AppColors.gray.shade900
        : AppColors.gray.shade800;
    final iconColor = textColor;
    final fillColor = _hovered ? AppColors.gray.shade100 : Colors.transparent;
    final borderColor = _hovered
        ? AppColors.gray.shade300
        : AppColors.gray.shade200;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                style:
                    (widget.textTheme.labelLarge ??
                            const TextStyle(fontSize: 12))
                        .copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatefulWidget {
  const NavItem({
    Key? key,
    required this.label,
    required this.style,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  final String label;
  final TextStyle? style;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodyMedium;
    final normalColor = baseStyle?.color ?? AppColors.gray[900];
    const hoverColor = AppColors.purple;
    final textDirection = Directionality.of(context);
    final labelPainter = TextPainter(
      text: TextSpan(text: widget.label, style: baseStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final labelWidth = labelPainter.width;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: _hovered
              ? (Matrix4.identity()..translateByDouble(0.0, -1.5, 0.0, 1.0))
              : Matrix4.identity(),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    style: (baseStyle ?? const TextStyle()).copyWith(
                      color: _hovered ? hoverColor : normalColor,
                    ),
                    child: Text(widget.label),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 4.0),
                    IconTheme(
                      data: IconThemeData(
                        color: _hovered ? hoverColor : normalColor,
                      ),
                      child: widget.trailing!,
                    ),
                  ],
                ],
              ),
              Positioned(
                left: 0.0,
                bottom: -4.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: 2.0,
                  width: _hovered ? labelWidth : 0.0,
                  decoration: BoxDecoration(
                    color: hoverColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
