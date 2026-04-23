import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/widgets/sections/footer.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  Map<String, dynamic>? _thread;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  int? _rateLimitSecondsLeft;

  Timer? _pollTimer;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (AuthSession.isLoggedIn) {
      _loadThread();
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() { _loading = true; _error = null; });
    try {
      final thread = await ApiService.getMyContactThread();
      setState(() { _thread = thread; _loading = false; });
      _scrollToBottom();
      if (thread != null) _startPolling();
    } catch (e) {
      setState(() { _error = _parseError(e); _loading = false; });
    }
  }

  Future<void> _startThread() async {
    setState(() { _loading = true; _error = null; });
    try {
      final thread = await ApiService.createContactThread();
      setState(() { _thread = thread; _loading = false; });
      _startPolling();
    } catch (e) {
      setState(() { _error = _parseError(e); _loading = false; });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages());
  }

  Future<void> _pollMessages() async {
    if (_thread == null) return;
    try {
      final updated = await ApiService.getMyContactThread();
      if (!mounted) return;
      final prevCount = ((_thread!['messages'] as List?) ?? []).length;
      final newCount = ((updated?['messages'] as List?) ?? []).length;
      if (newCount > prevCount) {
        setState(() => _thread = updated);
        _scrollToBottom();
      }
      // Stop polling once thread is closed
      if (updated?['status'] == 'closed') {
        _pollTimer?.cancel();
        setState(() => _thread = updated);
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thread == null) return;
    final threadId = _thread!['id'] as int;

    setState(() { _sending = true; _error = null; _rateLimitSecondsLeft = null; });
    try {
      await ApiService.sendContactMessage(threadId: threadId, content: text);
      _inputController.clear();
      // Refresh from server so local state and server are in sync —
      // prevents duplicates when the poll fires at the same time.
      final updated = await ApiService.getMyContactThread();
      if (!mounted) return;
      setState(() { _thread = updated; _sending = false; });
      _scrollToBottom();
    } catch (e) {
      final errStr = e.toString();
      // Try to parse rate-limit detail
      int? retry;
      if (errStr.contains('message_limit_reached') || errStr.contains('429')) {
        try {
          final start = errStr.indexOf('{');
          if (start != -1) {
            final json = jsonDecode(errStr.substring(start)) as Map<String, dynamic>;
            retry = json['retry_after_seconds'] as int?;
          }
        } catch (_) {}
        retry ??= 3600;
      }
      setState(() {
        _sending = false;
        _rateLimitSecondsLeft = retry;
        if (retry == null) _error = _parseError(e);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _parseError(Object e) {
    final s = e.toString();
    if (s.contains('401')) return 'Please log in to continue.';
    if (s.contains('403')) return 'Access denied.';
    if (s.contains('SocketException')) return 'Cannot reach the server. Check your connection.';
    final idx = s.indexOf(': ');
    if (idx != -1) return s.substring(idx + 2);
    return s;
  }

  String _formatRetryTime(int seconds) {
    if (seconds >= 3600) {
      final h = (seconds / 3600).ceil();
      return '$h hour${h == 1 ? '' : 's'}';
    }
    final m = (seconds / 60).ceil();
    return '$m minute${m == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final contentWidth = isMobile ? size.width - 32 : size.width * 0.7;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const GaiaNavBarAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(textTheme, size, isMobile, contentWidth),
            _buildInfoCards(textTheme, contentWidth),
            _buildChatSection(textTheme, contentWidth),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(TextTheme textTheme, Size size, bool isMobile, double contentWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 48 : 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.white, AppColors.gray.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTACT',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.gray.shade700,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Get in Touch',
                style: textTheme.displayMedium?.copyWith(height: 1.05),
              ),
              const SizedBox(height: 16),
              Text(
                'Have a question or need support? Chat with our team directly — '
                'we\'re here to help you get the most out of GAIA.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.gray.shade800,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards(TextTheme textTheme, double contentWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.gray.shade200),
          bottom: BorderSide(color: AppColors.gray.shade200),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.start,
            children: [
              _infoCard(
                textTheme,
                icon: Icons.email_outlined,
                label: 'Email',
                value: 'help@gaia.health',
              ),
              _infoCard(
                textTheme,
                icon: Icons.schedule_outlined,
                label: 'Hours',
                value: 'Mon – Fri, 9am – 6pm',
              ),
              _infoCard(
                textTheme,
                icon: Icons.timer_outlined,
                label: 'Response time',
                value: 'Within 24 hours',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
    TextTheme textTheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple.shade100, AppColors.turquoise.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.gray.shade700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection(TextTheme textTheme, double contentWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUPPORT',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.purple,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chat with Us',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                height: 3,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 24),
              _buildChatBody(textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBody(TextTheme textTheme) {
    if (!AuthSession.isLoggedIn) {
      return _buildLoginPrompt(textTheme);
    }
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }
    if (_error != null && _thread == null) {
      return _buildError(textTheme);
    }
    if (_thread == null) {
      return _buildNoThread(textTheme);
    }
    return _buildChat(textTheme);
  }

  Widget _buildLoginPrompt(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.gray.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple.shade100, AppColors.turquoise.shade100],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, color: AppColors.purple, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            'Login to chat with us',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'You need to be logged in to start a conversation with our support team.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade700, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.login),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.gray.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.gray.shade700, size: 48),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade800)),
          const SizedBox(height: 16),
          TextButton(onPressed: _loadThread, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildNoThread(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.gray.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple.shade100, AppColors.turquoise.shade100],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_outlined, color: AppColors.purple, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            'Start a conversation',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Send us a message and our team will get back to you within 24 hours. '
            'You can send up to 5 messages per day.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade700, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _startThread,
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text('Start a conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: textTheme.bodySmall?.copyWith(color: Colors.red.shade700)),
          ],
        ],
      ),
    );
  }

  Widget _buildChat(TextTheme textTheme) {
    final messages = (_thread!['messages'] as List?) ?? [];
    final isClosed = _thread!['status'] == 'closed';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.shade200,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.gray.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AppColors.gray.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.purple, AppColors.turquoise],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GAIA Support', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        isClosed ? 'Conversation closed' : 'Online · Replies within 24h',
                        style: textTheme.bodySmall?.copyWith(
                          color: isClosed ? AppColors.gray.shade700 : AppColors.turquoise,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gray.shade200,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('Closed', style: textTheme.labelLarge?.copyWith(color: AppColors.gray.shade700)),
                  ),
              ],
            ),
          ),

          // Messages
          SizedBox(
            height: 380,
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Send your first message below.',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.gray.shade700),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _buildBubble(textTheme, messages[i] as Map<String, dynamic>),
                  ),
          ),

          // Rate limit warning
          if (_rateLimitSecondsLeft != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Daily limit reached. You can send more in ${_formatRetryTime(_rateLimitSecondsLeft!)}.',
                      style: textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // Error banner
          if (_error != null && !isClosed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(_error!, style: textTheme.bodySmall?.copyWith(color: Colors.red.shade700)),
            ),

          // Input row
          if (!isClosed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray.shade100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.gray.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 1000,
                      enabled: !_sending && _rateLimitSecondsLeft == null,
                      decoration: InputDecoration(
                        hintText: 'Type your message…',
                        hintStyle: TextStyle(color: AppColors.gray.shade700),
                        filled: true,
                        fillColor: AppColors.white,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gray.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gray.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.purple, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: _sending ? 0.5 : 1.0,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _sending || _rateLimitSecondsLeft != null ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Closed: show start-new button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    setState(() { _thread = null; });
                    await _startThread();
                  },
                  icon: const Icon(Icons.add_comment_outlined, size: 16),
                  label: const Text('Start a new conversation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purple,
                    side: BorderSide(color: AppColors.purple),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(TextTheme textTheme, Map<String, dynamic> msg) {
    final isUser = msg['sender_type'] == 'user';
    final content = msg['content'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.purple, AppColors.turquoise]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.purple : AppColors.gray.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Text(
                      'GAIA Support',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    content,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isUser ? AppColors.white : AppColors.gray.shade900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
