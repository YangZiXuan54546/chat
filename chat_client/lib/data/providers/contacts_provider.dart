import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../models/user.dart';
import '../models/friend_request.dart';

class ContactsState {
  final List<User> friends;
  final List<User> searchResults;
  final List<FriendRequest> pendingRequests;
  final bool isLoading;
  final bool isSearching;
  final String? error;

  const ContactsState({
    this.friends = const [],
    this.searchResults = const [],
    this.pendingRequests = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
  });

  ContactsState copyWith({
    List<User>? friends,
    List<User>? searchResults,
    List<FriendRequest>? pendingRequests,
    bool? isLoading,
    bool? isSearching,
    String? error,
  }) {
    return ContactsState(
      friends: friends ?? this.friends,
      searchResults: searchResults ?? this.searchResults,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ApiService _apiService;

  ContactsNotifier(this._apiService) : super(const ContactsState());

  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.getFriends();
      final friends = (response.data['friends'] as List)
          .map((f) => User.fromJson(f))
          .toList();
      state = state.copyWith(friends: friends, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }

    state = state.copyWith(isSearching: true);

    try {
      final response = await _apiService.searchUsers(query);
      final results = (response.data['users'] as List)
          .map((u) => User.fromJson(u))
          .toList();
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      await _apiService.sendFriendRequest(userId);
      // Remove from search results if present
      state = state.copyWith(
        searchResults: state.searchResults.where((u) => u.id != userId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final response = await _apiService.acceptFriendRequest(requestId);
      final friend = User.fromJson(response.data['friend']);

      // Remove from pending and add to friends
      state = state.copyWith(
        pendingRequests: state.pendingRequests.where((r) => r.id != requestId).toList(),
        friends: [...state.friends, friend],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _apiService.rejectFriendRequest(requestId);
      state = state.copyWith(
        pendingRequests: state.pendingRequests.where((r) => r.id != requestId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteFriend(String userId) async {
    try {
      await _apiService.deleteFriend(userId);
      state = state.copyWith(
        friends: state.friends.where((f) => f.id != userId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void addFriend(User friend) {
    if (!state.friends.any((f) => f.id == friend.id)) {
      state = state.copyWith(friends: [...state.friends, friend]);
    }
  }

  void updateFriendOnlineStatus(String userId, bool isOnline) {
    final index = state.friends.indexWhere((f) => f.id == userId);
    if (index >= 0) {
      final updatedFriends = [...state.friends];
      updatedFriends[index] = updatedFriends[index].copyWith(isOnline: isOnline);
      state = state.copyWith(friends: updatedFriends);
    }
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ContactsNotifier(apiService);
});

// Online users provider
final onlineUsersProvider = StateProvider<Set<String>>((ref) => {});
