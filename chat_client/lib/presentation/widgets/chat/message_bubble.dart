import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback? onRecall;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.onRecall,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isRecalled) {
      return _buildRecalledMessage();
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showAvatar && !isMe) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    'U', // Should be sender's initial
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'User', // Should be sender's name
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          GestureDetector(
            onLongPress: onRecall,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.sentMessage : AppColors.receivedMessage,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.type == AppConstants.messageTypeText)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                      ),
                    )
                  else if (message.type == AppConstants.messageTypeImage)
                    _buildImageMessage()
                  else if (message.type == AppConstants.messageTypeFile)
                    _buildFileMessage(),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormatter.formatMessageTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.messageTime,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecalledMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isMe ? 'You recalled this message' : 'This message was recalled',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        message.content,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: AppColors.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: AppColors.textHint,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.attach_file,
          color: isMe ? Colors.white : AppColors.textPrimary,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : AppColors.textPrimary,
              decoration: TextDecoration.underline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    switch (message.status) {
      case AppConstants.messageStatusSending:
        icon = Icons.access_time;
        break;
      case AppConstants.messageStatusSent:
        icon = Icons.check;
        break;
      case AppConstants.messageStatusDelivered:
        icon = Icons.done_all;
        break;
      case AppConstants.messageStatusRead:
        icon = Icons.done_all;
        break;
      case AppConstants.messageStatusFailed:
        icon = Icons.error_outline;
        break;
      default:
        icon = Icons.check;
    }

    return Icon(
      icon,
      size: 14,
      color: message.status == AppConstants.messageStatusRead
          ? AppColors.secondary
          : Colors.white.withOpacity(0.7),
    );
  }
}
