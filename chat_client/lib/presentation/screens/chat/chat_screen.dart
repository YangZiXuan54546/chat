import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/message.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/call_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatType;
  final User? remoteUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatType,
    this.remoteUser,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocketListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    ref.read(messageListProvider(widget.chatId).notifier).loadMessages(refresh: true);
  }

  void _setupWebSocketListener() {
    final wsService = ref.read(webSocketServiceProvider);
    wsService.messageStream.listen((message) {
      if (message.event == 'message') {
        final msg = Message.fromJson(message.data);
        if ((msg.isPrivate && msg.senderId == widget.chatId) ||
            (msg.isGroup && msg.groupId == widget.chatId)) {
          ref.read(messageListProvider(widget.chatId).notifier).addMessage(msg);
          _scrollToBottom();
        }
      } else if (message.event == 'recall') {
        final messageId = message.data['message_id'] as String;
        ref.read(messageListProvider(widget.chatId).notifier).recallMessage(messageId);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String content, String type) {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    final messageData = {
      'receiver_id': widget.chatType == AppConstants.chatTypePrivate ? widget.chatId : null,
      'group_id': widget.chatType == AppConstants.chatTypeGroup ? widget.chatId : null,
      'content': content,
      'type': type,
    };

    ref.read(messageListProvider(widget.chatId).notifier).sendMessage(messageData);

    // Send via WebSocket for real-time delivery
    ref.read(webSocketServiceProvider).sendMessage(messageData);

    _scrollToBottom();
  }

  void _startCall(String type) {
    ref.read(callProvider.notifier).makeCall(widget.chatId, type);
    context.push('/call');
  }

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(messageListProvider(widget.chatId));
    final authState = ref.watch(authProvider);
    final wsService = ref.watch(webSocketServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: widget.remoteUser?.avatar != null
                  ? NetworkImage(widget.remoteUser!.avatar!)
                  : null,
              child: widget.remoteUser?.avatar == null
                  ? Text(
                      widget.remoteUser?.username[0].toUpperCase() ?? '?',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.remoteUser?.username ?? 'Chat',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.remoteUser != null)
                    Text(
                      widget.remoteUser!.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.remoteUser!.isOnline
                            ? AppColors.online
                            : AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _startCall(AppConstants.callTypeAudio),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _startCall(AppConstants.callTypeVideo),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messageState.isLoading && messageState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messageState.messages.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref
                              .read(messageListProvider(widget.chatId).notifier)
                              .loadMessages(refresh: true);
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: messageState.messages.length,
                          itemBuilder: (context, index) {
                            final message = messageState.messages[index];
                            final isMe = message.senderId == authState.user?.id;
                            final showAvatar = !isMe &&
                                (index == 0 ||
                                    messageState.messages[index - 1].senderId != message.senderId);

                            return MessageBubble(
                              message: message,
                              isMe: isMe,
                              showAvatar: showAvatar,
                              onRecall: isMe
                                  ? () => wsService.sendRecallMessage(message.id)
                                  : null,
                            );
                          },
                        ),
                      ),
          ),

          // Message input
          MessageInput(
            onSend: _sendMessage,
            onTyping: (isTyping) {
              if (_isTyping != isTyping) {
                _isTyping = isTyping;
                if (isTyping) {
                  wsService.sendTyping(widget.chatId, widget.chatType);
                } else {
                  wsService.sendStopTyping(widget.chatId, widget.chatType);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
