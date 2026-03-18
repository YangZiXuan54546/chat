import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  late final Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle errors globally
        return handler.next(error);
      },
    ));
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  // Auth endpoints
  Future<Response> login(String username, String password) async {
    return _dio.post(AppConfig.authLogin, data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> register(String username, String password, {String? email, String? avatar}) async {
    return _dio.post(AppConfig.authRegister, data: {
      'username': username,
      'password': password,
      if (email != null) 'email': email,
      if (avatar != null) 'avatar': avatar,
    });
  }

  Future<Response> refreshToken(String refreshToken) async {
    return _dio.post(AppConfig.authRefresh, data: {
      'refresh_token': refreshToken,
    });
  }

  Future<Response> logout() async {
    return _dio.post(AppConfig.authLogout);
  }

  // User endpoints
  Future<Response> searchUsers(String query) async {
    return _dio.get(AppConfig.usersSearch, queryParameters: {'q': query});
  }

  Future<Response> getProfile() async {
    return _dio.get(AppConfig.usersProfile);
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return _dio.put(AppConfig.usersProfile, data: data);
  }

  // Friends endpoints
  Future<Response> getFriends() async {
    return _dio.get(AppConfig.friendsList);
  }

  Future<Response> sendFriendRequest(String userId) async {
    return _dio.post(AppConfig.friendsRequest, data: {'user_id': userId});
  }

  Future<Response> acceptFriendRequest(String requestId) async {
    return _dio.post(AppConfig.friendsAccept, data: {'request_id': requestId});
  }

  Future<Response> rejectFriendRequest(String requestId) async {
    return _dio.post(AppConfig.friendsReject, data: {'request_id': requestId});
  }

  Future<Response> deleteFriend(String userId) async {
    return _dio.delete('${AppConfig.friendsList}/$userId');
  }

  // Messages endpoints
  Future<Response> getPrivateMessages(String userId, {int page = 1, int limit = 50}) async {
    return _dio.get(AppConfig.messagesPrivate, queryParameters: {
      'user_id': userId,
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> getGroupMessages(String groupId, {int page = 1, int limit = 50}) async {
    return _dio.get(AppConfig.messagesGroup, queryParameters: {
      'group_id': groupId,
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> sendMessage(Map<String, dynamic> messageData) async {
    return _dio.post(AppConfig.messages, data: messageData);
  }

  Future<Response> recallMessage(String messageId) async {
    return _dio.delete('${AppConfig.messages}/$messageId');
  }

  Future<Response> markAsRead(String chatId) async {
    return _dio.post('${AppConfig.messages}/read', data: {'chat_id': chatId});
  }

  // Groups endpoints
  Future<Response> createGroup(String name, {String? description, List<String>? memberIds}) async {
    return _dio.post(AppConfig.groupsCreate, data: {
      'name': name,
      if (description != null) 'description': description,
      if (memberIds != null) 'members': memberIds,
    });
  }

  Future<Response> getGroups() async {
    return _dio.get(AppConfig.groupsCreate);
  }

  Future<Response> joinGroup(String groupId) async {
    return _dio.post(AppConfig.groupsJoin, data: {'group_id': groupId});
  }

  Future<Response> leaveGroup(String groupId) async {
    return _dio.post(AppConfig.groupsLeave, data: {'group_id': groupId});
  }

  Future<Response> getGroupMembers(String groupId) async {
    return _dio.get('${AppConfig.groupsMembers}/$groupId');
  }

  Future<Response> addGroupMembers(String groupId, List<String> memberIds) async {
    return _dio.post('${AppConfig.groupsMembers}/$groupId', data: {'member_ids': memberIds});
  }

  Future<Response> removeGroupMember(String groupId, String memberId) async {
    return _dio.delete('${AppConfig.groupsMembers}/$groupId/$memberId');
  }

  // Call endpoints
  Future<Response> sendCallOffer(Map<String, dynamic> offerData) async {
    return _dio.post(AppConfig.callOffer, data: offerData);
  }

  Future<Response> sendCallAnswer(Map<String, dynamic> answerData) async {
    return _dio.post(AppConfig.callAnswer, data: answerData);
  }

  Future<Response> sendCallIceCandidate(Map<String, dynamic> candidateData) async {
    return _dio.post(AppConfig.callIce, data: candidateData);
  }

  Future<Response> endCall(String callId) async {
    return _dio.post(AppConfig.callEnd, data: {'call_id': callId});
  }

  // File upload
  Future<Response> uploadFile(String filePath, String fileName, {String? folder}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (folder != null) 'folder': folder,
    });
    return _dio.post('${AppConfig.apiPrefix}/upload', data: formData);
  }
}
