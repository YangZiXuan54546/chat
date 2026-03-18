import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class MessageInput extends StatefulWidget {
  final Function(String content, String type) onSend;
  final Function(bool isTyping)? onTyping;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onTyping,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _handleTextChange(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTyping?.call(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTyping?.call(false);
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text, AppConstants.messageTypeText);
      _controller.clear();
      _focusNode.requestFocus();

      // Stop typing indicator
      if (_isTyping) {
        _isTyping = false;
        widget.onTyping?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              icon: const Icon(Icons.attach_file),
              color: AppColors.textSecondary,
              onPressed: () {
                // TODO: Show attachment options
              },
            ),

            // Emoji button
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              color: AppColors.textSecondary,
              onPressed: () {
                // TODO: Show emoji keyboard
              },
            ),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.newline,
                  maxLines: 5,
                  minLines: 1,
                  onChanged: _handleTextChange,
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),

            // Send button
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.send),
                color: AppColors.primary,
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
