import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class Message extends Equatable {
  final String id;
  final String senderId;
  final String receiverId; // For private messages
  final String? groupId; // For group messages
  final String content;
  final String type; // text, image, file, audio, video
  final String status; // sending, sent, delivered, read, failed
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? replyToId;
  final bool isRecalled;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.groupId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.replyToId,
    this.isRecalled = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? groupId,
    String? content,
    String? type,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? replyToId,
    bool? isRecalled,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyToId: replyToId ?? this.replyToId,
      isRecalled: isRecalled ?? this.isRecalled,
    );
  }

  bool get isPrivate => groupId == null;
  bool get isGroup => groupId != null;

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        groupId,
        content,
        type,
        status,
        createdAt,
        updatedAt,
        replyToId,
        isRecalled,
      ];
}
