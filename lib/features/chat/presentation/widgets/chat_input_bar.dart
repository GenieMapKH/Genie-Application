import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String>? onSend;

  const ChatInputBar({super.key, this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _showExtraState = false;

  void _toggleExtraState() {
    setState(() {
      _showExtraState = !_showExtraState;
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showExtraState) _buildExtraStateOverlay(),
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _toggleExtraState,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.attach_file, color: Color(0xFF6B7280), size: 22),
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
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.sentiment_satisfied_alt,
                              color: const Color(0xFF6B7280)),
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleSend,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.send_outlined,
                              color: const Color(0xFF6B7280)),
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
                    child: SvgPicture.asset('assets/icons/chat_voice.svg', width: 44, height: 44),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtraStateOverlay() {
    return Container(
      color: const Color(0xFFD1D5DB).withOpacity(0.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionPill(
            label: 'Auto scroll down',
            iconPath: 'assets/icons/chat_scroll_down.svg',
          ),
          const SizedBox(height: 12),
          _buildActionPill(
            label: 'Voice or Camera',
            iconPath: 'assets/icons/chat_voice.svg',
            iconPath2: 'assets/icons/chat_camera.svg',
          ),
          const SizedBox(height: 12),
          _buildActionPill(
            label: 'Send photo / document',
            iconPath: 'assets/icons/chat_document.svg',
          ),
          const SizedBox(height: 12),
          _buildActionPill(
            label: 'Send sticker',
            iconPath: 'assets/icons/chat_sticker.svg',
            isLight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required String label,
    required String iconPath,
    String? iconPath2,
    bool isLight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF3730A3),
        borderRadius: BorderRadius.circular(24),
        border: isLight ? Border.all(color: const Color(0xFFE5E7EB)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isLight ? const Color(0xFF6B7280) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          if (iconPath.endsWith('.svg')) 
             SvgPicture.asset(iconPath, width: 40, height: 40)
          else 
             Icon(Icons.image, color: isLight ? const Color(0xFF6B7280) : Colors.white),
          if (iconPath2 != null) ...[
            const SizedBox(width: 8),
            SvgPicture.asset(iconPath2, width: 40, height: 40),
          ]
        ],
      ),
    );
  }
}
