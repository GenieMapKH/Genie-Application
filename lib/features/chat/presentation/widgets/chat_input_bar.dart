import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/chat/presentation/widgets/chat_emoji_panel.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String>? onSend;

  /// Called when the user wants to attach a picture.
  final VoidCallback? onAttach;

  const ChatInputBar({super.key, this.onSend, this.onAttach});

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
        Container(
          color: Colors.white,
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
              GestureDetector(
                onTap: widget.onAttach,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.attach_file,
                      color: Color(0xFF6B7280),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
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
                            hintText: 'Message',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF9CA3AF),
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
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleSend,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.send_outlined,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/chat_voice.svg',
                      width: 44,
                      height: 44,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showEmojis) ChatEmojiPanel(onSelected: _insertEmoji),
      ],
    );
  }
}
