import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../models/group.dart';
import '../models/user.dart';

class GroupsState {
  final List<Group> groups;
  final bool isLoading;
  final String? error;

  const GroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  GroupsState copyWith({
    List<Group>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GroupsNotifier extends StateNotifier<GroupsState> {
  final ApiService _apiService;

  GroupsNotifier(this._apiService) : super(const GroupsState());

  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.getGroups();
      final groups = (response.data['groups'] as List)
          .map((g) => Group.fromJson(g))
          .toList();
      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Group?> createGroup(String name, {String? description, List<String>? memberIds}) async {
    try {
      final response = await _apiService.createGroup(name, description: description, memberIds: memberIds);
      final group = Group.fromJson(response.data['group']);
      state = state.copyWith(groups: [...state.groups, group]);
      return group;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> joinGroup(String groupId) async {
    try {
      await _apiService.joinGroup(groupId);
      await loadGroups(); // Refresh groups
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _apiService.leaveGroup(groupId);
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != groupId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addMembers(String groupId, List<String> memberIds) async {
    try {
      await _apiService.addGroupMembers(groupId, memberIds);
      await loadGroups(); // Refresh groups
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeMember(String groupId, String memberId) async {
    try {
      await _apiService.removeGroupMember(groupId, memberId);
      await loadGroups(); // Refresh groups
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void updateGroup(Group group) {
    final index = state.groups.indexWhere((g) => g.id == group.id);
    if (index >= 0) {
      final updatedGroups = [...state.groups];
      updatedGroups[index] = group;
      state = state.copyWith(groups: updatedGroups);
    } else {
      state = state.copyWith(groups: [...state.groups, group]);
    }
  }
}

final groupsProvider = StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GroupsNotifier(apiService);
});

// Single group detail provider
final groupDetailProvider = FutureProvider.family<Group?, String>((ref, groupId) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    final response = await apiService.getGroupMembers(groupId);
    return Group.fromJson(response.data['group']);
  } catch (e) {
    return null;
  }
});
