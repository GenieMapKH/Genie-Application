import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/view_models/profile_edit_controller.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/profile/presentation/widgets/profile_field_editor.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/widgets/app_page_scaffold.dart';
import 'package:genie/shared/widgets/option_sheet.dart';
import 'package:genie/shared/widgets/settings_list.dart';

/// Everything the account knows about its owner, each row editable on its own.
class PersonalInfoPage extends ConsumerWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return AppPageScaffold(
      title: context.l10n.personalInfoTitle,
      // Only reachable from the account screen, which has loaded the profile.
      child: profile == null
          ? const Center(child: CircularProgressIndicator())
          : _PersonalInfoList(profile: profile),
    );
  }
}

class _PersonalInfoList extends ConsumerWidget {
  final UserProfile profile;

  const _PersonalInfoList({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final username = profile.username;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        SettingsSectionTitle(l10n.personalInfoSectionProfile),
        SettingsSection(
          children: [
            SettingsRow(
              icon: Icons.alternate_email,
              title: l10n.personalInfoUsername,
              value: username == null ? l10n.commonNotSet : '@$username',
              onTap: () => showProfileFieldEditor(
                context,
                field: ProfileField.username,
                label: l10n.personalInfoUsername,
                help: l10n.personalInfoUsernameHelp,
                initialValue: username,
                invalidMessage: l10n.personalInfoUsernameInvalid,
                takenMessage: l10n.personalInfoUsernameTaken,
              ),
            ),
            SettingsRow(
              icon: Icons.badge_outlined,
              title: l10n.personalInfoName,
              value: profile.name ?? l10n.commonNotSet,
              onTap: () => showProfileFieldEditor(
                context,
                field: ProfileField.displayName,
                label: l10n.personalInfoName,
                help: l10n.personalInfoNameHelp,
                initialValue: profile.name,
                invalidMessage: l10n.personalInfoTooLong,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionTitle(l10n.personalInfoSectionDetails),
        SettingsSection(
          children: [
            SettingsRow(
              icon: Icons.person_outline,
              title: l10n.personalInfoFirstName,
              value: profile.firstName ?? l10n.commonNotSet,
              onTap: () => showProfileFieldEditor(
                context,
                field: ProfileField.firstName,
                label: l10n.personalInfoFirstName,
                initialValue: profile.firstName,
                invalidMessage: l10n.personalInfoTooLong,
              ),
            ),
            SettingsRow(
              icon: Icons.people_outline,
              title: l10n.personalInfoLastName,
              value: profile.lastName ?? l10n.commonNotSet,
              onTap: () => showProfileFieldEditor(
                context,
                field: ProfileField.lastName,
                label: l10n.personalInfoLastName,
                initialValue: profile.lastName,
                invalidMessage: l10n.personalInfoTooLong,
              ),
            ),
            SettingsRow(
              icon: Icons.wc_outlined,
              title: l10n.personalInfoSex,
              value: _sexLabel(l10n, profile.sex),
              onTap: () => _pickSex(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionTitle(l10n.personalInfoSectionContact),
        SettingsSection(
          children: [
            SettingsRow(
              icon: Icons.phone_outlined,
              title: l10n.personalInfoPhone,
              value: profile.phone ?? l10n.commonNotSet,
              onTap: () => showProfileFieldEditor(
                context,
                field: ProfileField.phone,
                label: l10n.personalInfoPhone,
                help: l10n.personalInfoPhoneHelp,
                initialValue: profile.phone,
                keyboardType: TextInputType.phone,
                invalidMessage: l10n.personalInfoPhoneInvalid,
                takenMessage: l10n.personalInfoPhoneTaken,
              ),
            ),
            SettingsRow(
              icon: Icons.email_outlined,
              title: l10n.personalInfoEmail,
              value: profile.email ?? l10n.commonNotSet,
            ),
          ],
        ),
      ],
    );
  }

  static String _sexLabel(AppLocalizations l10n, Sex? sex) => switch (sex) {
    Sex.male => l10n.personalInfoSexMale,
    Sex.female => l10n.personalInfoSexFemale,
    Sex.other => l10n.personalInfoSexOther,
    null => l10n.commonNotSet,
  };

  Future<void> _pickSex(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final picked = await showOptionSheet<Sex?>(
      context,
      title: l10n.personalInfoSex,
      options: [
        for (final sex in [...Sex.values, null])
          SheetOption(sex, _sexLabel(l10n, sex)),
      ],
      selected: profile.sex,
    );
    if (picked == null || picked.value == profile.sex) return;

    final result = await ref
        .read(profileEditControllerProvider)
        .save(ProfileField.sex, picked.value?.name);
    if (!context.mounted || result == ProfileSaveResult.saved) return;
    AppPopup.showError(context, l10n.commonSomethingWentWrong);
  }
}
