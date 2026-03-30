import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class MessageInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool showQuickActions;
  final VoidCallback onToggleQuickActions;
  final List<Widget> quickActionChips;
  final ValueChanged<bool>? onTypingChanged;
  final VoidCallback? onAttachmentPressed;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.showQuickActions,
    required this.onToggleQuickActions,
    this.quickActionChips = const [],
    this.onTypingChanged,
    this.onAttachmentPressed,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  Timer? _typingTimer;
  bool _isTyping = false;

  void _onTextChanged(String text) {
    if (widget.onTypingChanged == null) return;

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTypingChanged!(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged!(false);
      }
    });
  }

  void _handleSend() {
    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      widget.onTypingChanged?.call(false);
    }
    widget.onSend();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: AppColors.getGlassBackground(0.05),
            border: Border(
              top: BorderSide(
                color: AppColors.getGlassBorder(0.4),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.showQuickActions ? null : 0,
            child: widget.showQuickActions
                ? Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: widget.quickActionChips),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: widget.onToggleQuickActions,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.showQuickActions
                        ? theme.colorScheme.primary
                        : AppColors.getGlassBackground(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.showQuickActions ? Icons.close : Icons.add,
                    color: widget.showQuickActions ? Colors.white : theme.colorScheme.onSurface,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.getGlassBackground(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.getGlassBorder(),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          onChanged: _onTextChanged,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      if (widget.onAttachmentPressed != null)
                        Semantics(
                          button: true,
                          label: 'Attach file',
                          child: GestureDetector(
                            onTap: widget.onAttachmentPressed,
                            child: Tooltip(
                              message: 'Attach file',
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.attach_file,
                                  size: 22,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Send message',
                child: GestureDetector(
                  onTap: _handleSend,
                  child: Tooltip(
                    message: 'Send message',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}
