// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Call _$CallFromJson(Map<String, dynamic> json) => Call(
      id: json['id'] as String,
      callerId: json['callerId'] as String,
      calleeId: json['calleeId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      caller: json['caller'] == null
          ? null
          : User.fromJson(json['caller'] as Map<String, dynamic>),
      callee: json['callee'] == null
          ? null
          : User.fromJson(json['callee'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      duration: (json['duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CallToJson(Call instance) => <String, dynamic>{
      'id': instance.id,
      'callerId': instance.callerId,
      'calleeId': instance.calleeId,
      'type': instance.type,
      'status': instance.status,
      'caller': instance.caller?.toJson(),
      'callee': instance.callee?.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'duration': instance.duration,
    };
