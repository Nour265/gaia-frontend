import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';

class AdminThreadPage extends StatefulWidget {
  const AdminThreadPage({
    super.key,
    required this.threadId,
    required this.userName,
  });

  final int threadId;
  final String userName;

  @override
  State<AdminThreadPage> createState() => _AdminThreadPageState();
}

class _AdminThreadPageState extends State<AdminThreadPage> {
  Map<String, dynamic>? _thread;
  bool _loading = true;
  bool _sending = false;
  bool _closing = false;
  String? _error;

  Timer? _pollTimer;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final thread = await ApiService.getAdminContactThread(widget.threadId);
      setState(() { _thread = thread; _loading = false; });
      _scrollToBottom();
      if (thread['status'] != 'closed') _startPolling();
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
      final updated = await ApiService.getAdminContactThread(widget.threadId);
      if (!mounted) return;
      final prevCount = ((_thread!['messages'] as List?) ?? []).length;
      final newCount = ((updated['messages'] as List?) ?? []).length;
      if (newCount > prevCount) {
        setState(() => _thread = updated);
        _scrollToBottom();
      }
      if (updated['status'] == 'closed') {
        _pollTimer?.cancel();
        setState(() => _thread = updated);
      }
    } catch (_) {}
  }

  Future<void> _sendReply() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() { _sending = true; _error = null; });
    try {
      await ApiService.adminReplyContactThread(
        threadId: widget.threadId,
        content: text,
      );
      _inputController.clear();
      // Refresh from server to stay in sync with the poll timer.
      final updated = await ApiService.getAdminContactThread(widget.threadId);
      if (!mounted) return;
      setState(() { _thread = updated; _sending = false; });
      _scrollToBottom();
    } catch (e) {
      setState(() { _error = _parseError(e); _sending = false; });
    }
  }

  Future<void> _closeThread() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close conversation'),
        content: const Text('Are you sure you want to close this conversation? The user will be able to start a new one.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _closing = true);
    try {
      await ApiService.closeContactThread(widget.threadId);
      setState(() {
        _thread = {..._thread!, 'status': 'closed'};
        _closing = false;
      });
    } catch (e) {
      setState(() { _error = _parseError(e); _closing = false; });
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
    if (s.contains('403')) return 'Access denied.';
    if (s.contains('401')) return 'Authentication required.';
    if (s.contains('SocketException')) return 'Cannot reach the server.';
    final idx = s.indexOf(': ');
    return idx != -1 ? s.substring(idx + 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isClosed = _thread?['status'] == 'closed';
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width < 980 ? size.width - 32 : size.width * 0.7;

    return Scaffold(
      backgroundColor: AppColors.gray.shade100,
      appBar: const GaiaNavBarAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _thread == null
              ? _buildError(textTheme)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back + header row
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                color: AppColors.gray.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.userName,
                                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      isClosed ? 'Conversation closed' : 'Open conversation',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isClosed ? AppColors.gray.shade700 : AppColors.turquoise,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isClosed)
                                OutlinedButton.icon(
                                  onPressed: _closing ? null : _closeThread,
                                  icon: _closing
                                      ? const SizedBox(
                                          width: 14, height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.check_circle_outline, size: 16),
                                  label: const Text('Close thread'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.gray.shade800,
                                    side: BorderSide(color: AppColors.gray.shade300),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Chat container
                          Container(
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
                                // Messages
                                Builder(builder: (ctx) {
                                  final messages = (_thread!['messages'] as List?) ?? [];
                                  return SizedBox(
                                    height: 480,
                                    child: messages.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No messages yet.',
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: AppColors.gray.shade700,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            controller: _scrollController,
                                            padding: const EdgeInsets.all(16),
                                            itemCount: messages.length,
                                            itemBuilder: (_, i) => _buildBubble(
                                              textTheme,
                                              messages[i] as Map<String, dynamic>,
                                            ),
                                          ),
                                  );
                                }),

                                // Error
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                    child: Text(
                                      _error!,
                                      style: textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                                    ),
                                  ),

                                // Input or closed notice
                                if (!isClosed)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray.shade100,
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(20),
                                      ),
                                      border: Border(
                                        top: BorderSide(color: AppColors.gray.shade200),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _inputController,
                                            maxLines: 3,
                                            minLines: 1,
                                            maxLength: 1000,
                                            enabled: !_sending,
                                            decoration: InputDecoration(
                                              hintText: 'Reply to ${widget.userName}…',
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
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                            ),
                                            onSubmitted: (_) => _sendReply(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: ElevatedButton(
                                            onPressed: _sending ? null : _sendReply,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.purple,
                                              foregroundColor: AppColors.white,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: _sending
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Icon(Icons.send_rounded, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        'This conversation is closed.',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.gray.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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

  Widget _buildBubble(TextTheme textTheme, Map<String, dynamic> msg) {
    final isUser = msg['sender_type'] == 'user';
    final content = msg['content'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.gray.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: AppColors.gray.shade700, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.gray.shade100 : AppColors.purple,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 4 : 16),
                  bottomRight: Radius.circular(isUser ? 16 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? widget.userName : 'You (Admin)',
                    style: textTheme.labelLarge?.copyWith(
                      color: isUser ? AppColors.gray.shade700 : AppColors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isUser ? AppColors.gray.shade900 : AppColors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.purple, AppColors.turquoise]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}
