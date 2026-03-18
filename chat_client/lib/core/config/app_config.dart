class AppConfig {
  static const String appName = 'ChatApp';
  static const String baseUrl = 'http://localhost:8080';
  static const String wsUrl = 'ws://localhost:8080/ws';

  // API Endpoints
  static const String apiPrefix = '/api/v1';
  static const String authLogin = '$apiPrefix/auth/login';
  static const String authRegister = '$apiPrefix/auth/register';
  static const String authRefresh = '$apiPrefix/auth/refresh';
  static const String authLogout = '$apiPrefix/auth/logout';

  static const String usersSearch = '$apiPrefix/users/search';
  static const String usersProfile = '$apiPrefix/users/profile';

  static const String friendsList = '$apiPrefix/friends';
  static const String friendsRequest = '$apiPrefix/friends/request';
  static const String friendsAccept = '$apiPrefix/friends/accept';
  static const String friendsReject = '$apiPrefix/friends/reject';

  static const String messages = '$apiPrefix/messages';
  static const String messagesPrivate = '$apiPrefix/messages/private';
  static const String messagesGroup = '$apiPrefix/messages/group';

  static const String groupsCreate = '$apiPrefix/groups';
  static const String groupsJoin = '$apiPrefix/groups/join';
  static const String groupsLeave = '$apiPrefix/groups/leave';
  static const String groupsMembers = '$apiPrefix/groups/members';

  static const String callOffer = '$apiPrefix/call/offer';
  static const String callAnswer = '$apiPrefix/call/answer';
  static const String callIce = '$apiPrefix/call/ice';
  static const String callEnd = '$apiPrefix/call/end';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration wsReconnectDelay = Duration(seconds: 5);

  // Pagination
  static const int defaultPageSize = 20;
}
