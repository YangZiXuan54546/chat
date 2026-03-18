import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'friend_request.g.dart';

@JsonSerializable()
class FriendRequest extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status; // pending, accepted, rejected
  final User? fromUser;
  final User? toUser;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    this.fromUser,
    this.toUser,
    required this.createdAt,
    this.updatedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => _$FriendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$FriendRequestToJson(this);

  FriendRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? status,
    User? fromUser,
    User? toUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      fromUser: fromUser ?? this.fromUser,
      toUser: toUser ?? this.toUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [id, fromUserId, toUserId, status, fromUser, toUser, createdAt, updatedAt];
}
