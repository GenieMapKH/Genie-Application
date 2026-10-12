import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/settings/providers/app_settings_providers.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/option_sheet.dart';
import 'package:genie/shared/widgets/settings_list.dart';

/// Settings row that shows the theme in use and opens the picker for it.
class AppearanceRow extends ConsumerWidget {
  const AppearanceRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(themeModeProvider);
    final options = [
      SheetOption(ThemeMode.system, l10n.appearanceSystem),
      SheetOption(ThemeMode.light, l10n.appearanceLight),
      SheetOption(ThemeMode.dark, l10n.appearanceDark),
    ];

    return SettingsRow(
      icon: Icons.dark_mode_outlined,
      title: l10n.accountAppearance,
      value: options.firstWhere((option) => option.value == current).label,
      onTap: () async {
        final picked = await showOptionSheet(
          context,
          title: l10n.appearanceTitle,
          options: options,
          selected: current,
        );
        if (picked != null) {
          await ref.read(themeModeProvider.notifier).select(picked.value);
        }
      },
    );
  }
}

/// Settings row that shows the language in use and opens the picker for it.
class LanguageRow extends ConsumerWidget {
  const LanguageRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The language on screen, whether it was picked or came from the phone.
    final current = Locale(Localizations.localeOf(context).languageCode);

    return SettingsRow(
      icon: Icons.language_outlined,
      title: l10n.accountLanguage,
      value: AppLanguages.nativeName(current),
      onTap: () async {
        final picked = await showOptionSheet(
          context,
          title: l10n.languageTitle,
          options: [
            for (final locale in AppLanguages.all)
              SheetOption(locale, AppLanguages.nativeName(locale)),
          ],
          selected: current,
        );
        if (picked != null) {
          await ref.read(localeProvider.notifier).select(picked.value);
        }
      },
    );
  }
}
