import 'package:flutter/material.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

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
      (l10n) => l10n.chatEmojiSmileys,
      '😀 😃 😄 😁 😆 😅 😂 🤣 🙂 😉 😊 😇 🥰 😍 😘 😋 😜 🤪 🤗 🤔 🤫 😐 '
      '😏 🙄 😴 😌 😔 😢 😭 😤 😠 😡 🤯 😳 🥺 😱 😎 🤓 🥳 😷 🤒 🤝 🙏 👀',
    ),
    _EmojiCategory(
      Icons.back_hand_outlined,
      (l10n) => l10n.chatEmojiGestures,
      '👍 👎 👌 ✌️ 🤞 🤟 🤙 👈 👉 👆 👇 ☝️ ✋ 🖐️ 👋 '
      '👏 🙌 🤲 💪 🫶 🫡 🤷 🙋 🙅 🙆 💁 🚶 🏃 💃 🕺',
    ),
    _EmojiCategory(
      Icons.favorite_border,
      (l10n) => l10n.chatEmojiHearts,
      '❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎 💔 ❣️ 💕 💞 💓 💗 '
      '💖 💘 💝 💯 ✨ ⭐ 🌟 🔥 🎉 🎊 🎁 🎈 🌹 🌸 🌺',
    ),
    _EmojiCategory(
      Icons.home_outlined,
      (l10n) => l10n.chatEmojiPlaces,
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
      color: context.colors.surfaceMuted,
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < _categories.length; i++)
                Expanded(
                  child: IconButton(
                    tooltip: _categories[i].label(context.l10n),
                    icon: Icon(
                      _categories[i].icon,
                      color: i == _category
                          ? context.colors.accent
                          : context.colors.textHint,
                    ),
                    onPressed: () => setState(() => _category = i),
                  ),
                ),
            ],
          ),
          Divider(height: 1, color: context.colors.border),
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
  final String Function(AppLocalizations l10n) label;
  final List<String> emojis;

  _EmojiCategory(this.icon, this.label, String emojis)
    : emojis = emojis.split(' ');
}
