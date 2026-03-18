import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/providers/call_provider.dart';

class CallScreen extends ConsumerWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);

    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      ref.read(callProvider.notifier).endCall();
                      context.pop();
                    },
                  ),
                  Text(
                    callState.call?.isVideo == true ? 'Video Call' : 'Voice Call',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the row
                ],
              ),
            ),

            // Remote video or avatar
            Expanded(
              child: callState.call?.isVideo == true
                  ? _buildVideoView(callState)
                  : _buildAvatarView(callState),
            ),

            // Call controls
            _buildCallControls(context, ref, callState),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView(CallState state) {
    return Stack(
      children: [
        // Remote video - placeholder
        Center(
          child: Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'Video will appear here',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Local video preview - placeholder
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.grey[800],
            ),
            child: const Center(
              child: Icon(Icons.person, size: 40, color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarView(CallState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: state.remoteUser?.avatar != null
                ? NetworkImage(state.remoteUser!.avatar!)
                : null,
            child: state.remoteUser?.avatar == null
                ? Text(
                    state.remoteUser?.username[0].toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            state.remoteUser?.username ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCallStatusText(state.status),
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, WidgetRef ref, CallState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _CallButton(
            icon: state.isMuted ? Icons.mic_off : Icons.mic,
            isActive: state.isMuted,
            onPressed: () => ref.read(callProvider.notifier).toggleMute(),
          ),

          // Speaker button (only for audio calls)
          if (state.call?.isVideo != true)
            _CallButton(
              icon: state.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              isActive: state.isSpeakerOn,
              onPressed: () => ref.read(callProvider.notifier).toggleSpeaker(),
            ),

          // End call button
          _CallButton(
            icon: Icons.call_end,
            backgroundColor: AppColors.error,
            iconColor: Colors.white,
            onPressed: () {
              ref.read(callProvider.notifier).endCall();
              context.pop();
            },
          ),

          // Video button (only for audio calls, to upgrade)
          if (state.call?.isVideo != true)
            _CallButton(
              icon: Icons.videocam,
              isActive: state.isVideoEnabled,
              onPressed: () => ref.read(callProvider.notifier).toggleVideo(),
            ),
        ],
      ),
    );
  }

  String _getCallStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call Ended';
      default:
        return 'Calling...';
    }
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? backgroundColor;
  final Color? iconColor;

  const _CallButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? (isActive ? Colors.white : Colors.white.withAlpha(51)),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: iconColor ?? (isActive ? AppColors.textPrimary : Colors.white),
        ),
        iconSize: 28,
        onPressed: onPressed,
      ),
    );
  }
}
