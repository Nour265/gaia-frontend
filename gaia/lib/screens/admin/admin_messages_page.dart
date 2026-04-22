import 'package:flutter/material.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'admin_thread_page.dart';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  List<dynamic> _threads = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final threads = await ApiService.getAdminContactThreads();
      setState(() { _threads = threads; _loading = false; });
    } catch (e) {
      setState(() { _error = _parseError(e); _loading = false; });
    }
  }

  String _parseError(Object e) {
    final s = e.toString();
    if (s.contains('403')) return 'Access denied. Admin privileges required.';
    if (s.contains('401')) return 'Authentication required.';
    if (s.contains('SocketException')) return 'Cannot reach the server.';
    final idx = s.indexOf(': ');
    return idx != -1 ? s.substring(idx + 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.gray.shade100,
      appBar: const GaiaNavBarAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(textTheme)
              : _buildBody(textTheme),
    );
  }

  Widget _buildError(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.gray.shade700),
          const SizedBox(height: 16),
          Text(_error!, style: textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width < 980 ? size.width - 32 : size.width * 0.7;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Support Messages', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${_threads.length} conversation${_threads.length == 1 ? '' : 's'}',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade700),
              ),
              const SizedBox(height: 24),
              if (_threads.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'No conversations yet.',
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.gray.shade600),
                    ),
                  ),
                )
              else
                ...(_threads.map((t) => _buildThreadCard(textTheme, t as Map<String, dynamic>))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreadCard(TextTheme textTheme, Map<String, dynamic> thread) {
    final isClosed = thread['status'] == 'closed';
    final userName = thread['user_name'] as String? ?? 'Unknown';
    final userEmail = thread['user_email'] as String? ?? '';
    final msgCount = thread['message_count'] as int? ?? 0;
    final lastMsg = thread['last_message'] as String?;
    final threadId = thread['id'] as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminThreadPage(threadId: threadId, userName: userName),
              ),
            );
            _load();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isClosed ? AppColors.gray.shade200 : AppColors.purple.shade100,
                width: isClosed ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isClosed
                        ? LinearGradient(colors: [AppColors.gray.shade300, AppColors.gray.shade400])
                        : const LinearGradient(colors: [AppColors.purple, AppColors.turquoise]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName,
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isClosed ? AppColors.gray.shade200 : AppColors.purple.shade100,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isClosed ? 'Closed' : 'Open',
                              style: textTheme.labelLarge?.copyWith(
                                color: isClosed ? AppColors.gray.shade700 : AppColors.purple,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.gray.shade600),
                      ),
                      if (lastMsg != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          lastMsg,
                          style: textTheme.bodySmall?.copyWith(color: AppColors.gray.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$msgCount msg${msgCount == 1 ? '' : 's'}',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.gray.shade600),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.chevron_right, color: AppColors.gray.shade500),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
