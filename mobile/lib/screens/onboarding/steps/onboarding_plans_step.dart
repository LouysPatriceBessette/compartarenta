import 'package:flutter/material.dart';

import '../../../prefs/app_preferences.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want to set up?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Shared housing'),
            subtitle: const Text('Shared rent and household expenses.'),
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
            title: const Text('Car sharing'),
            subtitle: const Text('Track usage, fuel, maintenance, violations, and reservations.'),
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

