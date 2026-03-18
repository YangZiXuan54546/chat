import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'call.g.dart';

@JsonSerializable()
class Call extends Equatable {
  final String id;
  final String callerId;
  final String calleeId;
  final String type; // audio, video
  final String status; // ringing, accepted, rejected, ended, missed
  final User? caller;
  final User? callee;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration; // in seconds

  const Call({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.type,
    required this.status,
    this.caller,
    this.callee,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.duration,
  });

  factory Call.fromJson(Map<String, dynamic> json) => _$CallFromJson(json);
  Map<String, dynamic> toJson() => _$CallToJson(this);

  Call copyWith({
    String? id,
    String? callerId,
    String? calleeId,
    String? type,
    String? status,
    User? caller,
    User? callee,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      type: type ?? this.type,
      status: status ?? this.status,
      caller: caller ?? this.caller,
      callee: callee ?? this.callee,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
    );
  }

  bool get isAudio => type == 'audio';
  bool get isVideo => type == 'video';
  bool get isRinging => status == 'ringing';
  bool get isAccepted => status == 'accepted';
  bool get isEnded => status == 'ended';
  bool get isMissed => status == 'missed';

  @override
  List<Object?> get props => [
        id,
        callerId,
        calleeId,
        type,
        status,
        caller,
        callee,
        createdAt,
        startedAt,
        endedAt,
        duration,
      ];
}
