import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'group.g.dart';

@JsonSerializable()
class Group extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final List<User> members;
  final String ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Group({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.members,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    List<User>? members,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      members: members ?? this.members,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isOwner(String userId) => ownerId == userId;
  bool isMember(String userId) => members.any((m) => m.id == userId);

  @override
  List<Object?> get props => [id, name, description, avatar, members, ownerId, createdAt, updatedAt];
}
