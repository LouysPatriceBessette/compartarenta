import 'package:flutter/material.dart';

import '../../../prefs/app_preferences.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingPlansStep extends StatefulWidget {
  const OnboardingPlansStep({
    super.key,
    required this.prefs,
    required this.onContinue,
  });

  final AppPreferences prefs;
  final VoidCallback onContinue;

  @override
  State<OnboardingPlansStep> createState() => _OnboardingPlansStepState();
}

class _OnboardingPlansStepState extends State<OnboardingPlansStep> {
  late Set<PlanType> _selected = {...widget.prefs.planTypes};

  bool get _canContinue => _selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPlansTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: Text(l10n.onboardingPlanHousingTitle),
            subtitle: Text(l10n.onboardingPlanHousingSubtitle),
            value: _selected.contains(PlanType.housing),
            onChanged: (value) => setState(() {
              if (value == true) {
                _selected.add(PlanType.housing);
              } else {
                _selected.remove(PlanType.housing);
              }
            }),
          ),
          CheckboxListTile(
            title: Text(l10n.onboardingPlanCarSharingTitle),
            subtitle: Text(l10n.onboardingPlanCarSharingSubtitle),
            value: _selected.contains(PlanType.carSharing),
            onChanged: (value) => setState(() {
              if (value == true) {
                _selected.add(PlanType.carSharing);
              } else {
                _selected.remove(PlanType.carSharing);
              }
            }),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _canContinue
                ? () async {
                    await widget.prefs.setPlanTypes(_selected);
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

