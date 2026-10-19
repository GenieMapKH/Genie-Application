import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/chat/models/chat_composer_mode.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_emoji_panel.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_record_button.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String>? onSend;

  /// Called when the user wants to attach a picture.
  final VoidCallback? onAttach;

  /// Called when the user taps the microphone to record a voice message.
  final VoidCallback? onRecordVoice;

  /// The microphone is held down: record until it is let go.
  final VoidCallback? onHoldVoiceStart;

  /// The microphone was let go (send) or slid away from (cancelled).
  final void Function({required bool cancelled})? onHoldVoiceEnd;

  /// Shown in place of the attach button and the message field while the
  /// microphone is held. The microphone itself stays, still held.
  final Widget? recordingPanel;

  /// Replying to or editing a message. Editing puts its text in the field,
  /// and only text can be sent.
  final ChatComposerMode? mode;

  /// Shown above the field while [mode] is set.
  final Widget? banner;

  const ChatInputBar({
    super.key,
    this.onSend,
    this.onAttach,
    this.onRecordVoice,
    this.onHoldVoiceStart,
    this.onHoldVoiceEnd,
    this.recordingPanel,
    this.mode,
    this.banner,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojis = false;

  @override
  void initState() {
    super.initState();
    // The emoji panel and the keyboard take the same place.
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojis) {
        setState(() => _showEmojis = false);
      }
    });
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final mode = widget.mode;
    if (identical(mode, oldWidget.mode)) return;

    if (mode is EditingMessage) {
      _controller.value = TextEditingValue(
        text: mode.message.text,
        selection: TextSelection.collapsed(offset: mode.message.text.length),
      );
    } else if (oldWidget.mode is EditingMessage) {
      // Editing was cancelled: the old text is not a new message.
      _controller.clear();
    }
    if (mode != null && !_showEmojis) _focusNode.requestFocus();
  }

  void _toggleEmojis() {
    setState(() => _showEmojis = !_showEmojis);
    if (_showEmojis) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  /// Puts [emoji] where the cursor is, replacing any selected text.
  void _insertEmoji(String emoji) {
    final value = _controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    _controller.value = TextEditingValue(
      text: value.text.replaceRange(selection.start, selection.end, emoji),
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend?.call(text);
      _controller.clear();
    }
  }

  /// Only the text can change: no picture or voice message is added.
  bool get _editing => widget.mode is EditingMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?widget.banner,
        Container(
          color: context.colors.surface,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom:
                12 + (_showEmojis ? 0 : MediaQuery.of(context).padding.bottom),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.recordingPanel case final panel?)
                Expanded(child: panel)
              else ...[
                if (!_editing) ...[
                  GestureDetector(
                    onTap: widget.onAttach,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.border,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.attach_file,
                          color: context.colors.textMuted,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.colors.iconSubtle),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onSubmitted: (_) => _handleSend(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: context.l10n.chatMessage,
                              hintStyle: GoogleFonts.inter(
                                color: context.colors.textHint,
                                fontSize: 15,
                              ),
                            ),
                            maxLines: 4,
                            minLines: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleEmojis,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _showEmojis
                                  ? Icons.keyboard_outlined
                                  : Icons.sentiment_satisfied_alt,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleSend,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _editing ? Icons.check : Icons.send_outlined,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (!_editing) ...[
                const SizedBox(width: 12),
                VoiceRecordButton(
                  // Keeps the held button the same one while the row changes.
                  key: const ValueKey('voice-record-button'),
                  label: context.l10n.chatRecordVoice,
                  onTap: widget.onRecordVoice,
                  onHoldStart: widget.onHoldVoiceStart,
                  onHoldEnd: widget.onHoldVoiceEnd,
                ),
              ],
            ],
          ),
        ),
        if (_showEmojis) ChatEmojiPanel(onSelected: _insertEmoji),
      ],
    );
  }
}
