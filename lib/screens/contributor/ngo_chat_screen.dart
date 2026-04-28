import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/resource_model.dart';
import '../../utils/constants.dart';
import '../../services/firestore_service.dart';

class NgoChatScreen extends StatefulWidget {
  final ResourceModel item;
  final String ngoId;

  const NgoChatScreen({
    super.key,
    required this.item,
    required this.ngoId,
  });

  @override
  State<NgoChatScreen> createState() => _NgoChatScreenState();
}

class _NgoChatScreenState extends State<NgoChatScreen> {
  final _firestoreService = FirestoreService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _firestoreService.sendChatMessage(
      itemId: widget.item.id,
      senderId: widget.ngoId,
      message: text,
      senderRole: AppConstants.roleNGO, // <-- NGO always sends with roleNGO
    );
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is! Timestamp) return '';
    final dt = timestamp.toDate();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildItemStrip(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.contributor.withOpacity(0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.contributor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                'C',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.contributor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contributor', style: AppTextStyles.headingMedium),
              Text('Online',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.ngo.withOpacity(0.06),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.ngo, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Re: ${widget.item.itemName}',
              style: AppTextStyles.caption.copyWith(color: AppColors.ngo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.ngo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.ngo.withOpacity(0.3)),
            ),
            child: Text(
              '${widget.item.category} · ${widget.item.condition}',
              style: AppTextStyles.caption.copyWith(color: AppColors.ngo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.streamChatMessages(widget.item.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: AppColors.textMuted, size: 40),
                const SizedBox(height: AppSpacing.sm),
                Text('Chat is open', style: AppTextStyles.headingMedium),
                Text('Say hello to the contributor!',
                    style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.lg),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final msg = messages[i];

            // ── KEY FIX: use senderRole, not senderId ──
            // The NGO sent this message if senderRole == 'ngo'.
            // This works correctly even when both parties share the
            // same device / Firebase Auth UID.
            final isMe = msg['senderRole'] == AppConstants.roleNGO;

            final isFirstInGroup = i == 0 ||
                messages[i - 1]['senderRole'] != msg['senderRole'];
            final isLastInGroup = i == messages.length - 1 ||
                messages[i + 1]['senderRole'] != msg['senderRole'];

            return _buildBubble(
              message: msg['message'] ?? '',
              timestamp: msg['timestamp'],
              isMe: isMe,
              senderLabel: isMe ? 'You (NGO)' : 'Contributor',
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
              accentColor: isMe ? AppColors.ngo : AppColors.contributor,
            );
          },
        );
      },
    );
  }

  Widget _buildBubble({
    required String message,
    required dynamic timestamp,
    required bool isMe,
    required String senderLabel,
    required bool isFirstInGroup,
    required bool isLastInGroup,
    required Color accentColor,
  }) {
    final avatarWidget = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(
          senderLabel.isNotEmpty ? senderLabel[0].toUpperCase() : '?',
          style: AppTextStyles.caption.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInGroup ? AppSpacing.md : 3,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left avatar — contributor side
          if (!isMe) ...[
            SizedBox(
              width: 32,
              child: isFirstInGroup ? avatarWidget : const SizedBox(),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isFirstInGroup)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 3,
                      left: isMe ? 0 : 4,
                      right: isMe ? 4 : 0,
                    ),
                    child: Text(
                      senderLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? accentColor.withOpacity(0.18)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : Radius.circular(isLastInGroup ? 4 : 18),
                      bottomRight: isMe
                          ? Radius.circular(isLastInGroup ? 4 : 18)
                          : const Radius.circular(18),
                    ),
                    border: Border.all(
                      color: isMe
                          ? accentColor.withOpacity(0.35)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    message,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 3,
                    left: isMe ? 0 : 4,
                    right: isMe ? 4 : 0,
                  ),
                  child: Text(
                    _formatTime(timestamp),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          // Right avatar — NGO (you) side
          if (isMe) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 32,
              child: isFirstInGroup ? avatarWidget : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 10),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.ngo,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}