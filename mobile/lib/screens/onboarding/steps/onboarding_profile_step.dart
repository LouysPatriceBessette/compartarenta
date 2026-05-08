import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../../prefs/app_preferences.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingProfileStep extends StatefulWidget {
  const OnboardingProfileStep({
    super.key,
    required this.prefs,
    required this.onContinue,
  });

  final AppPreferences prefs;
  final VoidCallback onContinue;

  @override
  State<OnboardingProfileStep> createState() => _OnboardingProfileStepState();
}

class _OnboardingProfileStepState extends State<OnboardingProfileStep> {
  late final TextEditingController _name =
      TextEditingController(text: widget.prefs.displayName);
  String _avatarId = '';

  static const List<IconData> _avatarIcons = [
    MdiIcons.account,
    MdiIcons.accountCircle,
    MdiIcons.accountCowboyHat,
    MdiIcons.accountHeart,
    MdiIcons.accountStar,
    MdiIcons.alien,
    MdiIcons.cat,
    MdiIcons.dog,
    MdiIcons.penguin,
    MdiIcons.panda,
    MdiIcons.robot,
    MdiIcons.ninja,
    MdiIcons.pirate,
    MdiIcons.faceMan,
    MdiIcons.faceWoman,
    MdiIcons.emoticonHappyOutline,
    MdiIcons.emoticonCoolOutline,
    MdiIcons.ghost,
    MdiIcons.owl,
    MdiIcons.fish,
  ];

  @override
  void initState() {
    super.initState();
    _avatarId = widget.prefs.avatarId;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canContinue => _name.text.trim().isNotEmpty && _avatarId.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingProfileTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              hintText: l10n.onboardingNameHint,
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingAvatarTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _avatarIcons.length,
              itemBuilder: (context, index) {
                final icon = _avatarIcons[index];
                final id = 'mdi:$index';
                final selected = id == _avatarId;
                return InkWell(
                  onTap: () => setState(() => _avatarId = id),
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                        width: selected ? 2 : 1,
                      ),
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                    ),
                    child: Icon(icon),
                  ),
                );
              },
            ),
          ),
          FilledButton(
            onPressed: _canContinue
                ? () async {
                    await widget.prefs.setDisplayName(_name.text);
                    await widget.prefs.setAvatarId(_avatarId);
                    widget.onContinue();
                  }
                : null,
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
  }
}

