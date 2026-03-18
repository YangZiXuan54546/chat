import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../models/message.dart';
import '../models/chat.dart';

class ChatListState {
  final List<Chat> chats;
  final bool isLoading;
  final String? error;

  const ChatListState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
  });

  ChatListState copyWith({
    List<Chat>? chats,
    bool? isLoading,
    String? error,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatListNotifier extends StateNotifier<ChatListState> {
  final ApiService _apiService;

  ChatListNotifier(this._apiService) : super(const ChatListState());

  Future<void> loadChats() async {
    state = state.copyWith(isLoading: true);

    try {
      // This would be an actual API call
      // For now, we'll initialize with empty
      state = state.copyWith(chats: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateChat(Chat chat) {
    final index = state.chats.indexWhere((c) => c.id == chat.id);
    if (index >= 0) {
      final updatedChats = [...state.chats];
      updatedChats[index] = chat;
      state = state.copyWith(chats: updatedChats);
    } else {
      state = state.copyWith(chats: [chat, ...state.chats]);
    }
  }

  void updateLastMessage(String chatId, Message message) {
    final index = state.chats.indexWhere((c) => c.id == chatId);
    if (index >= 0) {
      final updatedChats = [...state.chats];
      final chat = updatedChats[index];
      updatedChats[index] = chat.copyWith(
        lastMessage: message,
        lastMessageAt: message.createdAt,
      );
      // Sort by last message time
      updatedChats.sort((a, b) =>
          (b.lastMessageAt ?? b.createdAt).compareTo(a.lastMessageAt ?? a.createdAt));
      state = state.copyWith(chats: updatedChats);
    }
  }

  void incrementUnread(String chatId) {
    final index = state.chats.indexWhere((c) => c.id == chatId);
    if (index >= 0) {
      final updatedChats = [...state.chats];
      final chat = updatedChats[index];
      updatedChats[index] = chat.copyWith(unreadCount: chat.unreadCount + 1);
      state = state.copyWith(chats: updatedChats);
    }
  }

  void clearUnread(String chatId) {
    final index = state.chats.indexWhere((c) => c.id == chatId);
    if (index >= 0) {
      final updatedChats = [...state.chats];
      final chat = updatedChats[index];
      updatedChats[index] = chat.copyWith(unreadCount: 0);
      state = state.copyWith(chats: updatedChats);
    }
  }
}

final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatListNotifier(apiService);
});

// Message list for a specific chat
class MessageListState {
  final List<Message> messages;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const MessageListState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  MessageListState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return MessageListState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class MessageListNotifier extends StateNotifier<MessageListState> {
  final ApiService _apiService;
  final String chatId;
  final String chatType; // 'private' or 'group'

  MessageListNotifier(this._apiService, this.chatId, this.chatType)
      : super(const MessageListState());

  Future<void> loadMessages({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final response = chatType == 'private'
          ? await _apiService.getPrivateMessages(chatId, page: refresh ? 1 : 1)
          : await _apiService.getGroupMessages(chatId, page: refresh ? 1 : 1);

      final messages = (response.data['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList();

      state = state.copyWith(
        messages: refresh ? messages : [...state.messages, ...messages],
        isLoading: false,
        hasMore: messages.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addMessage(Message message) {
    // Check if message already exists
    if (state.messages.any((m) => m.id == message.id)) return;

    state = state.copyWith(messages: [...state.messages, message]);
  }

  void updateMessage(Message message) {
    final index = state.messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      final updatedMessages = [...state.messages];
      updatedMessages[index] = message;
      state = state.copyWith(messages: updatedMessages);
    }
  }

  void recallMessage(String messageId) {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      final updatedMessages = [...state.messages];
      updatedMessages[index] = updatedMessages[index].copyWith(isRecalled: true);
      state = state.copyWith(messages: updatedMessages);
    }
  }

  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final response = await _apiService.sendMessage(messageData);
      final message = Message.fromJson(response.data['message']);
      addMessage(message);
    } catch (e) {
      // Handle error - message could be added to failed state
    }
  }
}

final messageListProvider = StateNotifierProvider.family<MessageListNotifier, MessageListState, String>(
  (ref, chatId) {
    final apiService = ref.watch(apiServiceProvider);
    // For simplicity, we assume private chat type. Group chats will need a different approach.
    return MessageListNotifier(apiService, chatId, 'private');
  },
);
