import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import '../../models/repair_task_model.dart';
import '../../services/repair_chat_service.dart';
import '../../utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelperChatScreen extends StatefulWidget {
  final RepairTaskModel task;

  const HelperChatScreen({super.key, required this.task});

  @override
  State<HelperChatScreen> createState() => _HelperChatScreenState();
}

class _HelperChatScreenState extends State<HelperChatScreen> {
  final _chatService = RepairChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  late final String _helperId;
  RepairChatRoom? _chatRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _helperId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_helper';
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    try {
      final room = await _chatService.getOrCreateChatRoom(
        taskId: widget.task.id,
        ngoId: widget.task.ngoId ?? 'unassigned',
        helperId: _helperId,
      );

      await _chatService.markMessagesRead(
        chatRoomId: room.chatRoomId,
        readerRole: 'helper',
      );

      if (mounted) {
        setState(() {
          _chatRoom = room;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatRoom = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatRoom == null) return;

    _messageController.clear();

    await _chatService.sendMessage(
      chatRoomId: _chatRoom!.chatRoomId,
      senderId: _helperId,
      senderRole: 'helper',
      text: text,
    );

    _scrollToBottom();
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat with NGO',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '🔧 ${widget.task.repairType} repair',
              style: const TextStyle(
                color: AppColors.helper,
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.helper))
          : _chatRoom == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('Chat unavailable',
                          style: AppTextStyles.headingMedium),
                      const SizedBox(height: 8),
                      Text('Could not connect to chat. Try again.',
                          style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _initChatRoom();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildTaskInfoBanner(),
                    Expanded(child: _buildMessageList()),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  // ── Task info banner ──────────────────────────────────────────────────────

  Widget _buildTaskInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.helper.withOpacity(0.08),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.helper),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.task.description,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.helper),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.streamMessages(_chatRoom!.chatRoomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.helper));
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text('No messages yet',
                    style: AppTextStyles.headingMedium),
                Text('Start the conversation with the NGO',
                    style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        // Scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final msg = messages[i];
            final isMe = msg.senderId == _helperId;
            return _buildMessageBubble(msg, isMe);
          },
        );
      },
    );
  }

  // ── Message bubble ────────────────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.ngo.withOpacity(0.2),
              child: const Icon(Icons.handshake_outlined,
                  size: 14, color: AppColors.ngo),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.helper.withOpacity(0.85)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isMe ? AppRadius.lg : 4),
                  bottomRight: Radius.circular(isMe ? 4 : AppRadius.lg),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(msg.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.6)
                          : AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.helper.withOpacity(0.2),
              child: const Icon(Icons.handyman_outlined,
                  size: 14, color: AppColors.helper),
            ),
          ],
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Message NGO...',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: const BorderSide(color: AppColors.helper),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.helper,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}