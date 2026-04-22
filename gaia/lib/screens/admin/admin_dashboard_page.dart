import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'admin_messages_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await ApiService.getAdminDashboardSummary();
      setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = _err(e); _isLoading = false; });
    }
  }

  String _err(Object e) {
    final s = e.toString();
    if (s.contains("403")) return "Access denied. Admin privileges required.";
    if (s.contains("401")) return "Authentication required. Please log in.";
    if (s.contains("SocketException")) return "Unable to reach the server.";
    return "Unable to load dashboard. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: AppColors.gray.shade100,
      appBar: const GaiaNavBarAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _buildBody(isWeb),
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

  Widget _buildBody(bool isWeb) {
    final d = _data!;
    final int totalUsers      = (d['total_users']        as num?)?.toInt() ?? 0;
    final int inactiveUsers   = (d['inactive_users']     as num?)?.toInt() ?? 0;
    final int activeUsers     = totalUsers - inactiveUsers;
    final int totalDoctors    = (d['total_doctors']      as num?)?.toInt() ?? 0;
    final int activeDoctors   = (d['active_doctors']     as num?)?.toInt() ?? 0;
    final int inactiveDoctors = (d['inactive_doctors']   as num?)?.toInt() ?? 0;
    final int totalAdmins     = (d['total_admins']        as num?)?.toInt() ?? 0;
    final int totalAssess     = (d['total_assessments']  as num?)?.toInt() ?? 0;
    final int assessToday     = (d['assessments_today']  as num?)?.toInt() ?? 0;
    final int newUsers        = (d['new_users_this_week'] as num?)?.toInt() ?? 0;

    final cards = <_CardData>[
      _CardData(
        title: 'Total Patients',
        value: '$totalUsers',
        sub: '+$newUsers this week',
        icon: Icons.people_outline,
        accentColor: const Color(0xFF8C30F5),
        bgColor: const Color(0xFFF1E4FF),
        route: Routes.adminUsers,
        alert: false,
      ),
      _CardData(
        title: 'Inactive Patients',
        value: '$inactiveUsers',
        sub: 'Deactivated accounts',
        icon: Icons.person_off_outlined,
        accentColor: const Color(0xFFFE9A22),
        bgColor: const Color(0xFFFFE3C1),
        route: Routes.adminUsers,
        routeArgs: const {'filterActive': false},
        alert: inactiveUsers > 0,
      ),
      _CardData(
        title: 'Active Doctors',
        value: '$activeDoctors',
        sub: 'of $totalDoctors total',
        icon: Icons.medical_services_outlined,
        accentColor: const Color(0xFF2EC5CE),
        bgColor: const Color(0xFFD5FAFC),
        route: Routes.adminDoctors,
        alert: false,
      ),
      _CardData(
        title: 'Inactive Doctors',
        value: '$inactiveDoctors',
        sub: 'Need review',
        icon: Icons.local_hospital_outlined,
        accentColor: const Color(0xFFF22BB2),
        bgColor: const Color(0xFFFFB1E6),
        route: Routes.adminDoctors,
        routeArgs: const {'filterActive': false},
        alert: inactiveDoctors > 0,
      ),
      _CardData(
        title: 'Total Admins',
        value: '$totalAdmins',
        sub: 'System administrators',
        icon: Icons.admin_panel_settings_outlined,
        accentColor: const Color(0xFF8C30F5),
        bgColor: const Color(0xFFF1E4FF),
        route: Routes.adminAdmins,
        alert: false,
      ),
      _CardData(
        title: 'Assessments Today',
        value: '$assessToday',
        sub: '$totalAssess total',
        icon: Icons.today_outlined,
        accentColor: const Color(0xFF2EC5CE),
        bgColor: const Color(0xFFD5FAFC),
        route: null,
        alert: false,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Overview of system activity and health.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade700)),
          const SizedBox(height: 24),

          // ── Stat cards ──────────────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWeb ? 3 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isWeb ? 1.6 : 1.1,
            ),
            itemCount: cards.length,
            itemBuilder: (_, i) => _buildCard(cards[i]),
          ),
          const SizedBox(height: 32),

          // ── Charts ──────────────────────────────────────────────────────
          Text('Charts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Visual breakdown of key metrics.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade700)),
          const SizedBox(height: 16),

          isWeb
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPatientChart(activeUsers, inactiveUsers, newUsers)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDoctorChart(activeDoctors, inactiveDoctors)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAssessmentChart(assessToday, totalAssess)),
                  ],
                )
              : Column(
                  children: [
                    _buildPatientChart(activeUsers, inactiveUsers, newUsers),
                    const SizedBox(height: 16),
                    _buildDoctorChart(activeDoctors, inactiveDoctors),
                    const SizedBox(height: 16),
                    _buildAssessmentChart(assessToday, totalAssess),
                  ],
                ),
          const SizedBox(height: 32),

          // ── Support messages shortcut ────────────────────────────────────
          Text('Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Manage user support conversations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade700)),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminMessagesPage()),
              ),
              mouseCursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8C30F5), Color(0xFF2EC5CE)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.forum_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Support Messages',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )),
                          const SizedBox(height: 2),
                          Text('View and reply to user conversations',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.gray.shade700,
                                  )),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray.shade600),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPatientChart(int active, int inactive, int newThisWeek) {
    final total = active + inactive;
    return _ChartCard(
      title: 'Patient Status',
      subtitle: '$total total patients',
      child: Column(
        children: [
          _DonutChart(
            segments: [
              _ChartSegment('Active', active, const Color(0xFF8C30F5)),
              _ChartSegment('Inactive', inactive, const Color(0xFFFE9A22)),
            ],
            centerLabel: '$total',
            centerSublabel: 'patients',
          ),
          const SizedBox(height: 16),
          _LegendRow(items: [
            _LegendItem('Active', active, const Color(0xFF8C30F5)),
            _LegendItem('Inactive', inactive, const Color(0xFFFE9A22)),
            _LegendItem('New (7d)', newThisWeek, const Color(0xFF2EC5CE)),
          ]),
        ],
      ),
    );
  }

  Widget _buildDoctorChart(int active, int inactive) {
    final total = active + inactive;
    return _ChartCard(
      title: 'Doctor Status',
      subtitle: '$total total doctors',
      child: Column(
        children: [
          _DonutChart(
            segments: [
              _ChartSegment('Active', active, const Color(0xFF2EC5CE)),
              _ChartSegment('Inactive', inactive, const Color(0xFFF22BB2)),
            ],
            centerLabel: '$total',
            centerSublabel: 'doctors',
          ),
          const SizedBox(height: 16),
          _LegendRow(items: [
            _LegendItem('Active', active, const Color(0xFF2EC5CE)),
            _LegendItem('Inactive', inactive, const Color(0xFFF22BB2)),
          ]),
        ],
      ),
    );
  }

  Widget _buildAssessmentChart(int today, int total) {
    return _ChartCard(
      title: 'Assessments',
      subtitle: 'Activity overview',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RadialProgressChart(
            value: total == 0 ? 0 : (today / max(today, total / 30)).clamp(0, 1),
            label: '$today',
            sublabel: 'today',
            color: const Color(0xFF8C30F5),
          ),
          const SizedBox(height: 16),
          _LegendRow(items: [
            _LegendItem('Total', total, const Color(0xFF8C30F5)),
            _LegendItem('Today', today, const Color(0xFF2EC5CE)),
          ]),
        ],
      ),
    );
  }

  Widget _buildCard(_CardData c) {
    final clickable = c.route != null;

    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: c.alert
            ? BorderSide(color: c.accentColor.withAlpha(120), width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: clickable ? () => Navigator.pushNamed(context, c.route!, arguments: c.routeArgs) : null,
        mouseCursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: c.accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(c.icon, color: c.accentColor, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: c.alert ? c.accentColor : AppColors.gray.shade900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.sub,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (clickable) ...[
                      const SizedBox(height: 6),
                      Icon(Icons.arrow_forward, size: 14, color: AppColors.gray.shade700),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart card wrapper ────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.gray.shade700)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Donut chart ───────────────────────────────────────────────────────────────

class _ChartSegment {
  const _ChartSegment(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.segments, required this.centerLabel, required this.centerSublabel});
  final List<_ChartSegment> segments;
  final String centerLabel;
  final String centerSublabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _DonutPainter(segments: segments),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerLabel,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(centerSublabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.gray.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments});
  final List<_ChartSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -pi / 2;
    for (final seg in segments) {
      final sweep = 2 * pi * (seg.value / total);
      canvas.drawArc(
        rect,
        startAngle,
        sweep - 0.03,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments;
}

// ── Radial progress chart ─────────────────────────────────────────────────────

class _RadialProgressChart extends StatelessWidget {
  const _RadialProgressChart({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
  });
  final double value;
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _RadialPainter(value: value, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800, color: color)),
              Text(sublabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.gray.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  const _RadialPainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Track
    canvas.drawArc(
      rect, -pi / 2, 2 * pi, false,
      Paint()
        ..color = color.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Fill
    if (value > 0) {
      canvas.drawArc(
        rect, -pi / 2, 2 * pi * value, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RadialPainter old) => old.value != value || old.color != color;
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _LegendItem {
  const _LegendItem(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.items});
  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              '${item.label}: ${item.value}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.gray.shade800, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Card data ─────────────────────────────────────────────────────────────────

class _CardData {
  const _CardData({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    this.route,
    this.routeArgs,
    this.alert = false,
  });

  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final String? route;
  final Map<String, dynamic>? routeArgs;
  final bool alert;
}
