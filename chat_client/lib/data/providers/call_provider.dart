import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/services/api_service.dart';
import '../models/call.dart';
import '../models/user.dart';
import 'auth_provider.dart';

enum CallStatus { idle, ringing, connecting, connected, ended }

class CallState {
  final CallStatus status;
  final Call? call;
  final User? remoteUser;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isVideoEnabled;
  final RTCVideoRenderer? localRenderer;
  final RTCVideoRenderer? remoteRenderer;
  final String? error;

  const CallState({
    this.status = CallStatus.idle,
    this.call,
    this.remoteUser,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isVideoEnabled = true,
    this.localRenderer,
    this.remoteRenderer,
    this.error,
  });

  CallState copyWith({
    CallStatus? status,
    Call? call,
    User? remoteUser,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isVideoEnabled,
    RTCVideoRenderer? localRenderer,
    RTCVideoRenderer? remoteRenderer,
    String? error,
  }) {
    return CallState(
      status: status ?? this.status,
      call: call ?? this.call,
      remoteUser: remoteUser ?? this.remoteUser,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      localRenderer: localRenderer ?? this.localRenderer,
      remoteRenderer: remoteRenderer ?? this.remoteRenderer,
      error: error,
    );
  }
}

class CallNotifier extends StateNotifier<CallState> {
  final ApiService _apiService;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  CallNotifier(this._apiService) : super(const CallState());

  Future<void> initRenderers() async {
    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    state = state.copyWith(localRenderer: localRenderer, remoteRenderer: remoteRenderer);
  }

  Future<void> makeCall(String calleeId, String type) async {
    await initRenderers();
    state = state.copyWith(status: CallStatus.connecting);

    try {
      // Get local media stream
      _localStream = await _getMediaStream(type == 'video');
      state.localRenderer?.srcObject = _localStream;

      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration);

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle incoming remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty && state.remoteRenderer != null) {
          state.remoteRenderer!.srcObject = event.streams[0];
        }
      };

      // Create offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Send call offer via API (WebSocket would be better)
      final response = await _apiService.sendCallOffer({
        'callee_id': calleeId,
        'type': type,
        'offer': offer.toMap(),
      });

      final call = Call.fromJson(response.data['call']);
      state = state.copyWith(status: CallStatus.ringing, call: call, remoteUser: call.callee);
    } catch (e) {
      state = state.copyWith(status: CallStatus.idle, error: e.toString());
      await _cleanup();
    }
  }

  Future<void> answerCall(Call call) async {
    state = state.copyWith(status: CallStatus.connecting);

    try {
      // Get local media stream
      _localStream = await _getMediaStream(call.isVideo);
      state.localRenderer?.srcObject = _localStream;

      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration);

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle incoming remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty && state.remoteRenderer != null) {
          state.remoteRenderer!.srcObject = event.streams[0];
        }
      };

      // Set remote description from offer
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(call.status, 'offer'),
      );

      // Create answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Send answer via API
      await _apiService.sendCallAnswer({
        'call_id': call.id,
        'answer': answer.toMap(),
      });

      state = state.copyWith(
        status: CallStatus.connected,
        call: call.copyWith(status: 'accepted'),
        isVideoEnabled: call.isVideo,
      );
    } catch (e) {
      state = state.copyWith(status: CallStatus.idle, error: e.toString());
      await _cleanup();
    }
  }

  Future<void> handleIncomingOffer(Call call, Map<String, dynamic> offer) async {
    await initRenderers();
    state = state.copyWith(
      status: CallStatus.ringing,
      call: call,
      remoteUser: call.caller,
    );

    try {
      // Get local media stream
      _localStream = await _getMediaStream(call.isVideo);
      state.localRenderer?.srcObject = _localStream;

      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration);

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle incoming remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty && state.remoteRenderer != null) {
          state.remoteRenderer!.srcObject = event.streams[0];
        }
      };

      // Set remote description
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> handleIncomingAnswer(String sdp) async {
    if (_peerConnection == null) return;

    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp, 'answer'),
      );
      state = state.copyWith(status: CallStatus.connected);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    if (_peerConnection == null) return;

    try {
      await _peerConnection!.addCandidate(RTCIceCandidate(
        candidate['candidate'] as String,
        candidate['sdpMid'] as String?,
        candidate['sdpMLineIndex'] as int?,
      ));
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> toggleMute() async {
    if (_localStream == null) return;

    final audioTracks = _localStream!.getAudioTracks();
    for (final track in audioTracks) {
      track.enabled = !track.enabled;
    }
    state = state.copyWith(isMuted: !state.isMuted);
  }

  Future<void> toggleSpeaker() async {
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  Future<void> toggleVideo() async {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    for (final track in videoTracks) {
      track.enabled = !track.enabled;
    }
    state = state.copyWith(isVideoEnabled: !state.isVideoEnabled);
  }

  Future<void> endCall() async {
    if (state.call != null) {
      try {
        await _apiService.endCall(state.call!.id);
      } catch (e) {
        // Ignore API errors
      }
    }

    await _cleanup();
    state = const CallState();
  }

  Future<void> _cleanup() async {
    _localStream?.dispose();
    _localStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
    state.localRenderer?.srcObject = null;
    state.remoteRenderer?.srcObject = null;
  }

  Future<MediaStream> _getMediaStream(bool enableVideo) async {
    final mediaConstraints = {
      'audio': true,
      'video': enableVideo
          ? {
              'facingMode': 'user',
              'width': 640,
              'height': 480,
            }
          : false,
    };
    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  @override
  void dispose() {
    _cleanup();
    state.localRenderer?.dispose();
    state.remoteRenderer?.dispose();
    super.dispose();
  }
}

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CallNotifier(apiService);
});

// Incoming call provider
final incomingCallProvider = StateProvider<Call?>((ref) => null);
