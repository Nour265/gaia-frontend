import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/values/values.dart';

class AppointmentCard extends StatefulWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.isDoctor,
    required this.onStatusChanged,
  });

  final Map<String, dynamic> appointment;
  final bool isDoctor;
  final VoidCallback onStatusChanged;

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  bool _chatOpen = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green.shade600;
      case 'completed': return Colors.blue.shade600;
      case 'cancelled':  return Colors.red.shade600;
      default:           return Colors.orange.shade700;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle_outline;
      case 'completed': return Icons.done_all;
      case 'cancelled':  return Icons.cancel_outlined;
      default:           return Icons.hourglass_empty;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final id = widget.appointment['id'] as int;
    try {
      await ApiService.updateAppointmentStatus(appointmentId: id, status: newStatus);
      widget.onStatusChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt    = widget.appointment;
    final status  = appt['status'] as String? ?? 'pending';
    final id      = appt['id'] as int;
    final counterpartName = widget.isDoctor
        ? (appt['user_name']   as String? ?? 'Patient')
        : (appt['doctor_name'] as String? ?? 'Doctor');
    final condition = appt['condition']        as String?;
    final specialty = appt['doctor_specialty'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            leading: CircleAvatar(
              backgroundColor: _statusColor(status).withValues(alpha: 0.12),
              child: Icon(_statusIcon(status), color: _statusColor(status)),
            ),
            title: Text(
              counterpartName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (condition != null && condition.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Condition: $condition',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                if (specialty != null && !widget.isDoctor)
                  Text(specialty,
                      style: TextStyle(color: Colors.indigo.shade400, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: status != 'cancelled' && status != 'completed'
                ? PopupMenuButton<String>(
                    onSelected: _updateStatus,
                    itemBuilder: (_) => [
                      if (widget.isDoctor) ...[
                        if (status == 'pending')
                          const PopupMenuItem(value: 'confirmed', child: Text('Confirm')),
                        if (status != 'completed')
                          const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                      ],
                      const PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
                    ],
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _chatOpen = !_chatOpen),
                  icon: Icon(
                    _chatOpen ? Icons.keyboard_arrow_up : Icons.chat_bubble_outline,
                    size: 18,
                  ),
                  label: Text(_chatOpen ? 'Hide Chat' : 'Open Chat'),
                ),
              ],
            ),
          ),
          if (_chatOpen)
            AppointmentChat(
              appointmentId: id,
              isCancelled: status == 'cancelled',
            ),
        ],
      ),
    );
  }
}

// ── Chat ──────────────────────────────────────────────────────────────────────

class AppointmentChat extends StatefulWidget {
  const AppointmentChat({
    super.key,
    required this.appointmentId,
    required this.isCancelled,
  });

  final int appointmentId;
  final bool isCancelled;

  @override
  State<AppointmentChat> createState() => _AppointmentChatState();
}

class _AppointmentChatState extends State<AppointmentChat> {
  final _controller       = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await ApiService.getMessages(appointmentId: widget.appointmentId);
      if (!mounted) return;
      final prevCount = _messages.length;
      setState(() => _messages = msgs);
      if (msgs.length > prevCount) _scrollToBottom();
    } catch (_) {}
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiService.sendMessage(
          appointmentId: widget.appointmentId, content: text);
      _controller.clear();
      await _fetchMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthSession.user?.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          if (_messages.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg  = _messages[i] as Map<String, dynamic>;
                      final isMe = (msg['sender_id'] as int?) == currentUserId;
                      return MessageBubble(
                        content:    msg['content']     as String? ?? '',
                        senderName: msg['sender_name'] as String? ?? '',
                        isMe: isMe,
                        createdAt: msg['created_at'] as String?,
                      );
                    },
                  ),
                ),
          if (!widget.isCancelled)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send),
                          color: AppColors.purple,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.purple.withValues(alpha: 0.1),
                          ),
                        ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Appointment cancelled — messaging disabled.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.content,
    required this.senderName,
    required this.isMe,
    this.createdAt,
  });

  final String  content;
  final String  senderName;
  final bool    isMe;
  final String? createdAt;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.purple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color:  Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade400,
                ),
              ),
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.grey.shade900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
