import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';
import 'message.dart';

part 'chat.g.dart';

@JsonSerializable()
class Chat extends Equatable {
  final String id;
  final String type; // private, group
  final User? participant; // For private chat
  final String? groupName; // For group chat
  final String? groupAvatar; // For group chat
  final List<User>? participants; // For group chat
  final Message? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const Chat({
    required this.id,
    required this.type,
    this.participant,
    this.groupName,
    this.groupAvatar,
    this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageAt,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
  Map<String, dynamic> toJson() => _$ChatToJson(this);

  Chat copyWith({
    String? id,
    String? type,
    User? participant,
    String? groupName,
    String? groupAvatar,
    List<User>? participants,
    Message? lastMessage,
    int? unreadCount,
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) {
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      participant: participant ?? this.participant,
      groupName: groupName ?? this.groupName,
      groupAvatar: groupAvatar ?? this.groupAvatar,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPrivate => type == 'private';
  bool get isGroup => type == 'group';

  @override
  List<Object?> get props => [
        id,
        type,
        participant,
        groupName,
        groupAvatar,
        participants,
        lastMessage,
        unreadCount,
        lastMessageAt,
        createdAt,
      ];
}
