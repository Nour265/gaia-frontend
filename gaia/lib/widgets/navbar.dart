import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/services/auth_session.dart';

class NavBar extends StatelessWidget {
  const NavBar({
    Key? key,
    this.showLogin = false,
  }) : super(key: key);

  final bool showLogin;
  

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 72.0,
      child: Row(
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
      ),
    );
  }

  Row _buildItems(BuildContext context, TextTheme textTheme) {
    final itemStyle = textTheme.bodyMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavItem(
          label: 'About',
          style: itemStyle,
          onTap: () {
            Navigator.pushNamed(context, Routes.about);
          },
        ),
        const SizedBox(width: 24.0),
        NavItem(label: 'Contact', style: itemStyle, onTap: () {}),
        const SizedBox(width: 24.0),
        NavItem(label: 'Blog', style: itemStyle, onTap: () {}),
        const SizedBox(width: 24.0),
        NavItem(label: 'Resources', style: itemStyle, onTap: () {}),
        const SizedBox(width: 24.0),
        NavItem(
          label: 'More',
          style: itemStyle,
          onTap: () {},
          trailing: const Padding(
            padding: EdgeInsets.only(bottom: 2.0),
            child: Icon(Icons.expand_more, size: 20.0),
          ),
        ),
      ],
    );
  }
}

class ImageLinks extends StatelessWidget {
  const ImageLinks({
    Key? key,
  }) : super(key: key);

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
              _LoginButton(
                label: 'Profile',
                icon: Icons.person_outline,
                textTheme: textTheme,
                onPressed: () {
                  Navigator.pushNamed(context, Routes.profile);
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
  const Logo({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(ImagePath.logo),
        const SizedBox(width: 10.0),
        Text('GAIA', style: textTheme.titleMedium),
      ],
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
    final textColor = _hovered ? AppColors.gray.shade900 : AppColors.gray.shade800;
    final iconColor = textColor;
    final fillColor = _hovered ? AppColors.gray.shade100 : Colors.transparent;
    final borderColor =
        _hovered ? AppColors.gray.shade300 : AppColors.gray.shade200;

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
                style: (widget.textTheme.labelLarge ??
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
              ? (Matrix4.identity()..translate(0.0, -1.5))
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
