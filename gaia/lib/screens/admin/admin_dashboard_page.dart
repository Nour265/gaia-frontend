import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';

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
        title: 'Total Assessments',
        value: '$totalAssess',
        sub: '$assessToday today',
        icon: Icons.assessment_outlined,
        accentColor: const Color(0xFF8C30F5),
        bgColor: const Color(0xFFF1E4FF),
        route: null,
        alert: false,
      ),
      _CardData(
        title: 'Assessments Today',
        value: '$assessToday',
        sub: 'Completed today',
        icon: Icons.today_outlined,
        accentColor: const Color(0xFF2EC5CE),
        bgColor: const Color(0xFFD5FAFC),
        route: null,
        alert: false,
      ),
      _CardData(
        title: 'New Patients (7d)',
        value: '$newUsers',
        sub: 'Registered this week',
        icon: Icons.person_add_outlined,
        accentColor: const Color(0xFFFE9A22),
        bgColor: const Color(0xFFFFE3C1),
        route: Routes.adminUsers,
        alert: false,
      ),
      _CardData(
        title: 'Total Doctors',
        value: '$totalDoctors',
        sub: '$activeDoctors active',
        icon: Icons.badge_outlined,
        accentColor: const Color(0xFFF22BB2),
        bgColor: const Color(0xFFFFB1E6),
        route: Routes.adminDoctors,
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
          Text('Tap a card to manage that section.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade700)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWeb ? 4 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isWeb ? 1.55 : 1.1,
            ),
            itemCount: cards.length,
            itemBuilder: (_, i) => _buildCard(cards[i]),
          ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.bgColor,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(c.icon, color: c.accentColor, size: 20),
                        ),
                        const Spacer(),
                        if (clickable)
                          Icon(Icons.chevron_right, size: 18, color: AppColors.gray.shade700)
                        else
                          Tooltip(
                            message: 'View only',
                            child: Icon(Icons.info_outline, size: 16, color: AppColors.gray.shade700),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.value,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: c.alert ? c.accentColor : AppColors.gray.shade900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.sub,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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

class _CardData {
  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final String? route;
  final Map<String, dynamic>? routeArgs;
  final bool alert;

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
}
