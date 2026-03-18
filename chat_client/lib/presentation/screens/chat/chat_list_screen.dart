import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/chat.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListState = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {
              // TODO: Navigate to new chat
            },
          ),
        ],
      ),
      body: chatListState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatListState.chats.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => ref.read(chatListProvider.notifier).loadChats(),
                  child: ListView.builder(
                    itemCount: chatListState.chats.length,
                    itemBuilder: (context, index) {
                      final chat = chatListState.chats[index];
                      return _ChatListItem(chat: chat);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new chat with a friend',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Chat chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context) {
    final name = chat.isPrivate ? chat.participant?.username ?? 'Unknown' : chat.groupName ?? 'Group';
    final avatar = chat.isPrivate ? chat.participant?.avatar : chat.groupAvatar;
    final isOnline = chat.participant?.isOnline ?? false;

    return ListTile(
      onTap: () {
        if (chat.isPrivate) {
          context.push('/chat/private/${chat.participant?.id}');
        } else {
          context.push('/chat/group/${chat.id}');
        }
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
        child: avatar == null
            ? Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.lastMessage != null)
            Text(
              DateFormatter.formatMessageTime(chat.lastMessage!.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: chat.unreadCount > 0 ? AppColors.primary : AppColors.textHint,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (chat.isPrivate && isOnline)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(
              chat.lastMessage?.content ?? 'No messages yet',
              style: TextStyle(
                color: chat.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
