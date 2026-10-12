import 'package:flutter/material.dart';

/// A compact emoji keyboard shown under the message box.
class ChatEmojiPanel extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const ChatEmojiPanel({super.key, required this.onSelected});

  @override
  State<ChatEmojiPanel> createState() => _ChatEmojiPanelState();
}

class _ChatEmojiPanelState extends State<ChatEmojiPanel> {
  /// Each category's emojis, separated by spaces.
  static final _categories = [
    _EmojiCategory(
      Icons.sentiment_satisfied_alt,
      'Smileys',
      '😀 😃 😄 😁 😆 😅 😂 🤣 🙂 😉 😊 😇 🥰 😍 😘 😋 😜 🤪 🤗 🤔 🤫 😐 '
          '😏 🙄 😴 😌 😔 😢 😭 😤 😠 😡 🤯 😳 🥺 😱 😎 🤓 🥳 😷 🤒 🤝 🙏 👀',
    ),
    _EmojiCategory(
      Icons.back_hand_outlined,
      'Gestures',
      '👍 👎 👌 ✌️ 🤞 🤟 🤙 👈 👉 👆 👇 ☝️ ✋ 🖐️ 👋 '
          '👏 🙌 🤲 💪 🫶 🫡 🤷 🙋 🙅 🙆 💁 🚶 🏃 💃 🕺',
    ),
    _EmojiCategory(
      Icons.favorite_border,
      'Hearts',
      '❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎 💔 ❣️ 💕 💞 💓 💗 '
          '💖 💘 💝 💯 ✨ ⭐ 🌟 🔥 🎉 🎊 🎁 🎈 🌹 🌸 🌺',
    ),
    _EmojiCategory(
      Icons.home_outlined,
      'Places',
      '🏠 🏡 🏢 🏬 🏗️ 🏘️ 🏙️ 🏞️ 🌳 🌴 🛏️ 🛋️ 🚪 🪟 🚿 🛁 🔑 🗝️ '
          '📍 🗺️ 🚗 🛵 🚌 ✈️ 💰 💵 💳 📄 📝 📅 ⏰ 📞 📷 ✅ ❌ ❓',
    ),
  ];

  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final emojis = _categories[_category].emojis;

    return Container(
      height: 260,
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < _categories.length; i++)
                Expanded(
                  child: IconButton(
                    tooltip: _categories[i].label,
                    icon: Icon(
                      _categories[i].icon,
                      color: i == _category
                          ? const Color(0xFF5B5FEF)
                          : const Color(0xFF9CA3AF),
                    ),
                    onPressed: () => setState(() => _category = i),
                  ),
                ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 48,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) => InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onSelected(emojis[index]),
                child: Center(
                  child: Text(
                    emojis[index],
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiCategory {
  final IconData icon;
  final String label;
  final List<String> emojis;

  _EmojiCategory(this.icon, this.label, String emojis)
    : emojis = emojis.split(' ');
}
