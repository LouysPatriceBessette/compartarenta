import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../car_sharing/binary_availability_week_editor.dart';
import '../../car_sharing/car_sharing_plan_draft.dart';
import '../../housing/agreement_rules_json.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/format_money.dart';

/// Vertical-stepper wizard for a shared-car plan (local draft in [AppPreferences]).
class CarSharingPlanScreen extends StatefulWidget {
  const CarSharingPlanScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<CarSharingPlanScreen> createState() => _CarSharingPlanScreenState();
}

class _CarSharingPlanScreenState extends State<CarSharingPlanScreen> {
  static const int _stepCount = 9;

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

  late CarSharingPlanDraft _draft;
  int _stepIndex = 0;
  int _availabilityDayIndex = 0;
  int _coEditorIndex = 0;
  final List<TextEditingController> _coNameControllers = [];
  final List<String> _coAvatarIds = [];

  late final TextEditingController _make = TextEditingController();
  late final TextEditingController _model = TextEditingController();
  late final TextEditingController _color = TextEditingController();
  late final TextEditingController _year = TextEditingController();
  late final TextEditingController _estimatedValue = TextEditingController();
  late final TextEditingController _photoFront = TextEditingController();
  late final TextEditingController _photoLeft = TextEditingController();
  late final TextEditingController _photoRight = TextEditingController();
  late final TextEditingController _photoRear = TextEditingController();
  late final TextEditingController _photoSeatsFront = TextEditingController();
  late final TextEditingController _photoSeatsRear = TextEditingController();
  late final TextEditingController _photoDashboard = TextEditingController();
  late final TextEditingController _photoOdometer = TextEditingController();
  late final TextEditingController _fuelCustom = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = CarSharingPlanDraft.decode(widget.prefs.carSharingPlanDraftJson);
    _applyDraftToControllers();
    if (_draft.ownerDisplayName.trim().isEmpty) {
      _draft.ownerDisplayName = widget.prefs.displayName.trim();
    }
    _initCoParticipantControllersFromDraft();
  }

  void _initCoParticipantControllersFromDraft() {
    for (final c in _coNameControllers) {
      c.dispose();
    }
    _coNameControllers.clear();
    _coAvatarIds.clear();
    for (var i = 0; i < _draft.coParticipants.length; i++) {
      final p = _draft.coParticipants[i];
      _coNameControllers.add(TextEditingController(text: p.displayName));
      final aid = p.avatarId.trim();
      _coAvatarIds.add(aid.isEmpty ? 'mdi:0' : aid);
    }
    _coEditorIndex = _coEditorIndex.clamp(0, _draft.coParticipants.length - 1);
  }

  void _setCoParticipantCount(int next) {
    final v = next.clamp(1, 7);
    setState(() {
      while (_draft.coParticipants.length < v) {
        _draft.coParticipants.add(CarSharingCoParticipantDraft());
        _coNameControllers.add(TextEditingController());
        _coAvatarIds.add('mdi:0');
      }
      while (_draft.coParticipants.length > v) {
        _draft.coParticipants.removeLast();
        _coNameControllers.removeLast().dispose();
        _coAvatarIds.removeLast();
      }
      _coEditorIndex = _coEditorIndex.clamp(0, v - 1);
    });
    unawaited(_persist());
  }

  void _syncCoParticipantsToDraft() {
    for (var i = 0; i < _draft.coParticipants.length; i++) {
      if (i < _coNameControllers.length && i < _coAvatarIds.length) {
        _draft.coParticipants[i].displayName = _coNameControllers[i].text;
        _draft.coParticipants[i].avatarId = _coAvatarIds[i];
      }
    }
  }

  void _applyDraftToControllers() {
    _make.text = _draft.vehicleMake;
    _model.text = _draft.vehicleModel;
    _color.text = _draft.vehicleColor;
    _year.text = _draft.vehicleYear;
    _estimatedValue.text = _draft.estimatedValueMinor == 0
        ? ''
        : (_draft.estimatedValueMinor / 100).toStringAsFixed(2);
    _photoFront.text = _draft.photoFrontPath;
    _photoLeft.text = _draft.photoLeftPath;
    _photoRight.text = _draft.photoRightPath;
    _photoRear.text = _draft.photoRearPath;
    _photoSeatsFront.text = _draft.photoSeatsFrontPath;
    _photoSeatsRear.text = _draft.photoSeatsRearPath;
    _photoDashboard.text = _draft.photoDashboardPath;
    _photoOdometer.text = _draft.photoOdometerPath;
    _fuelCustom.text = _draft.customFuelPolicyText;
  }

  void _applyControllersToDraft() {
    _draft.vehicleMake = _make.text.trim();
    _draft.vehicleModel = _model.text.trim();
    _draft.vehicleColor = _color.text.trim();
    _draft.vehicleYear = _year.text.trim();
    final ev = double.tryParse(_estimatedValue.text.replaceAll(',', '.')) ?? 0;
    _draft.estimatedValueMinor = (ev * 100).round();
    _draft.photoFrontPath = _photoFront.text.trim();
    _draft.photoLeftPath = _photoLeft.text.trim();
    _draft.photoRightPath = _photoRight.text.trim();
    _draft.photoRearPath = _photoRear.text.trim();
    _draft.photoSeatsFrontPath = _photoSeatsFront.text.trim();
    _draft.photoSeatsRearPath = _photoSeatsRear.text.trim();
    _draft.photoDashboardPath = _photoDashboard.text.trim();
    _draft.photoOdometerPath = _photoOdometer.text.trim();
    _draft.customFuelPolicyText = _fuelCustom.text.trim();
    _syncCoParticipantsToDraft();
  }

  Future<void> _persist() async {
    _applyControllersToDraft();
    await widget.prefs.setCarSharingPlanDraftJson(_draft.encode(), notify: false);
  }

  @override
  void dispose() {
    _applyControllersToDraft();
    unawaited(widget.prefs.setCarSharingPlanDraftJson(_draft.encode(), notify: false));
    _make.dispose();
    _model.dispose();
    _color.dispose();
    _year.dispose();
    _estimatedValue.dispose();
    _photoFront.dispose();
    _photoLeft.dispose();
    _photoRight.dispose();
    _photoRear.dispose();
    _photoSeatsFront.dispose();
    _photoSeatsRear.dispose();
    _photoDashboard.dispose();
    _photoOdometer.dispose();
    _fuelCustom.dispose();
    for (final c in _coNameControllers) {
      c.dispose();
    }
    _coNameControllers.clear();
    super.dispose();
  }

  List<String> _stepTitles(AppLocalizations l10n) => [
        l10n.carSharingStepVehicle,
        l10n.carSharingStepOwner,
        l10n.carSharingStepParticipants,
        l10n.carSharingStepInsurance,
        l10n.carSharingStepCurrentState,
        l10n.carSharingStepMaintenance,
        l10n.carSharingStepAvailability,
        l10n.carSharingStepFuel,
        l10n.carSharingStepClauses,
      ];

  Widget _stepperRail(AppLocalizations l10n) {
    return SizedBox(
      width: 52,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 0, 16),
        child: Column(
          children: [
            for (var i = 0; i < _stepCount; i++) ...[
              if (i > 0)
                SizedBox(
                  height: 12,
                  child: Center(
                    child: Container(
                      width: 2,
                      height: 12,
                      color: i <= _stepIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              Tooltip(
                message: _stepTitles(l10n)[i],
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: i == _stepIndex
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: i < _stepIndex
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepVehicle(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _make, decoration: InputDecoration(labelText: l10n.carSharingFieldMake)),
        const SizedBox(height: 12),
        TextField(controller: _model, decoration: InputDecoration(labelText: l10n.carSharingFieldModel)),
        const SizedBox(height: 12),
        TextField(controller: _color, decoration: InputDecoration(labelText: l10n.carSharingFieldColor)),
        const SizedBox(height: 12),
        TextField(
          controller: _year,
          decoration: InputDecoration(labelText: l10n.carSharingFieldYear),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _stepOwner(AppLocalizations l10n) {
    final name = widget.prefs.displayName.trim().isEmpty ? '—' : widget.prefs.displayName.trim();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.carSharingOwnerPrompt(name), style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.carSharingOwnerIsOwner)),
            ButtonSegment(value: true, label: Text(l10n.carSharingOwnerIsRental)),
          ],
          selected: {_draft.ownerIsRental},
          onSelectionChanged: (s) {
            setState(() => _draft.ownerIsRental = s.first);
            unawaited(_persist());
          },
        ),
        if (_draft.ownerIsRental) ...[
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _draft.rentalSharePermissionFromLessor,
            onChanged: (v) {
              setState(() => _draft.rentalSharePermissionFromLessor = v ?? false);
              unawaited(_persist());
            },
            title: Text(l10n.carSharingRentalSharePermission),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _draft.rentalContractCopyOnAcceptance,
            onChanged: (v) {
              setState(() => _draft.rentalContractCopyOnAcceptance = v ?? false);
              unawaited(_persist());
            },
            title: Text(l10n.carSharingRentalContractCopy),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ],
    );
  }

  Widget _stepParticipants(AppLocalizations l10n) {
    final i = _draft.coParticipants.length > 1 ? _coEditorIndex : 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_draft.coParticipants.length > 1) ...[
          Row(
            children: [
              OutlinedButton(
                onPressed: _coEditorIndex > 0 ? () => setState(() => _coEditorIndex--) : null,
                child: Text(l10n.housingPlanPreviousPerson),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _coEditorIndex < _draft.coParticipants.length - 1
                    ? () => setState(() => _coEditorIndex++)
                    : null,
                child: Text(l10n.housingPlanNextPerson),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _coNameControllers[i],
          decoration: InputDecoration(labelText: l10n.housingPlanParticipantNameLabel),
          onChanged: (_) {
            setState(() {});
            unawaited(_persist());
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: _avatarIcons.length,
            itemBuilder: (context, idx) {
              final id = 'mdi:$idx';
              final sel = _coAvatarIds[i] == id;
              return InkWell(
                onTap: () {
                  setState(() => _coAvatarIds[i] = id);
                  unawaited(_persist());
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: sel ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                      width: sel ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_avatarIcons[idx]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.housingPlanParticipantsPlaceholderNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _stepInsurance(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CheckboxListTile(
          value: _draft.insuranceNotifyOnAcceptance,
          onChanged: (v) {
            setState(() => _draft.insuranceNotifyOnAcceptance = v ?? false);
            unawaited(_persist());
          },
          title: Text(l10n.carSharingInsuranceNotify),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _draft.insuranceAssumePremiumIncrease,
          onChanged: (v) {
            setState(() => _draft.insuranceAssumePremiumIncrease = v ?? false);
            unawaited(_persist());
          },
          title: Text(l10n.carSharingInsuranceAssumeIncrease),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _draft.insuranceProvideDocsOnAcceptance,
          onChanged: (v) {
            setState(() => _draft.insuranceProvideDocsOnAcceptance = v ?? false);
            unawaited(_persist());
          },
          title: Text(l10n.carSharingInsuranceProvideDocs),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _stepCurrentState(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _estimatedValue,
          decoration: InputDecoration(labelText: l10n.carSharingEstimatedValueLabel),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextField(controller: _photoFront, decoration: InputDecoration(labelText: l10n.carSharingPhotoFront)),
        const SizedBox(height: 8),
        TextField(controller: _photoLeft, decoration: InputDecoration(labelText: l10n.carSharingPhotoLeft)),
        const SizedBox(height: 8),
        TextField(controller: _photoRight, decoration: InputDecoration(labelText: l10n.carSharingPhotoRight)),
        const SizedBox(height: 8),
        TextField(controller: _photoRear, decoration: InputDecoration(labelText: l10n.carSharingPhotoRear)),
        const SizedBox(height: 8),
        TextField(
          controller: _photoSeatsFront,
          decoration: InputDecoration(labelText: l10n.carSharingPhotoSeatsFront),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _photoSeatsRear,
          decoration: InputDecoration(labelText: l10n.carSharingPhotoSeatsRear),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _photoDashboard,
          decoration: InputDecoration(labelText: l10n.carSharingPhotoDashboard),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _photoOdometer,
          decoration: InputDecoration(labelText: l10n.carSharingPhotoOdometer),
        ),
      ],
    );
  }

  Widget _stepMaintenance(AppLocalizations l10n) {
    final dc = displayCurrencyCodeForPlan(widget.prefs, const []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.carSharingMaintenanceIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (_draft.maintenanceLines.isEmpty)
          Text(l10n.carSharingMaintenanceEmpty, style: Theme.of(context).textTheme.bodySmall)
        else
          ..._draft.maintenanceLines.map((line) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(line.title.isEmpty ? '—' : line.title),
                subtitle: Text(
                  line.isRecurring
                      ? '${formatMinorAsMoney(context, line.amountMinor, dc)} · '
                          '↻ ${line.recurrenceDayOfMonth}'
                      : '${formatMinorAsMoney(context, line.amountMinor, dc)} · 1×',
                ),
                onTap: () => _showMaintenanceLineEditor(line),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => _draft.maintenanceLines.remove(line));
                    unawaited(_persist());
                  },
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: () => _showMaintenanceLineEditor(null),
            icon: const Icon(Icons.add),
            label: Text(l10n.carSharingMaintenanceAdd),
          ),
        ),
      ],
    );
  }

  Future<void> _showMaintenanceLineEditor(CarSharingMaintenanceLineDraft? existing) async {
    final line = await showDialog<CarSharingMaintenanceLineDraft>(
      context: context,
      builder: (ctx) => _AddCarMaintenanceDialog(initial: existing),
    );
    if (!mounted || line == null) return;
    if (existing == null) {
      setState(() => _draft.maintenanceLines.add(line));
    } else {
      setState(() {
        final idx = _draft.maintenanceLines.indexWhere((l) => l.id == existing.id);
        if (idx >= 0) {
          _draft.maintenanceLines[idx] = line;
        }
      });
    }
    await _persist();
  }

  Widget _stepAvailability(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.carSharingAvailabilityIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        BinaryAvailabilityWeekEditor(
          grid: _draft.availabilityHalfHours,
          uiSelectedDayIndex: _availabilityDayIndex,
          onSelectDay: (i) => setState(() => _availabilityDayIndex = i),
          onToggleCell: (day, slot) {
            setState(() {
              final v = _draft.availabilityHalfHours[day][slot];
              _draft.availabilityHalfHours[day][slot] = v == 1 ? 0 : 1;
            });
            unawaited(_persist());
          },
          labelAvailable: l10n.carSharingAvailabilityAvailable,
          labelOwnerOnly: l10n.carSharingAvailabilityOwner,
        ),
      ],
    );
  }

  Widget _stepFuel(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.carSharingFuelIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _draft.useAppFuelTracking,
          onChanged: (v) {
            setState(() => _draft.useAppFuelTracking = v ?? true);
            unawaited(_persist());
          },
          title: Text(l10n.carSharingFuelUseAppTracking),
        ),
        if (!_draft.useAppFuelTracking) ...[
          const SizedBox(height: 8),
          Text(l10n.carSharingFuelCustomHint, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _fuelCustom,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (_) => unawaited(_persist()),
          ),
        ],
      ],
    );
  }

  Widget _stepClauses(AppLocalizations l10n) {
    final rules = _draft.clauseRules;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.carSharingClausesIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        for (var i = 0; i < rules.customRules.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(rules.customRules[i].title),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(rules.customRules[i].body),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.housingAgreementRuleRemove),
                  onTap: () {
                    setState(() => rules.customRules.removeAt(i));
                    unawaited(_persist());
                  },
                ),
              ],
            ),
          ),
        if (!rules.dismissedSuggestionIds.contains(kAgreementSuggestionCommonCleanliness))
          _suggestionTile(
            l10n,
            id: kAgreementSuggestionCommonCleanliness,
            title: l10n.housingAgreementSuggestionCleanlinessTitle,
            body: l10n.housingAgreementSuggestionCleanlinessBody,
          ),
        if (!rules.dismissedSuggestionIds.contains(kAgreementSuggestionFridgeManagement))
          _suggestionTile(
            l10n,
            id: kAgreementSuggestionFridgeManagement,
            title: l10n.housingAgreementSuggestionFridgeTitle,
            body: l10n.housingAgreementSuggestionFridgeBody,
          ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => _showAddCustomRule(l10n),
          icon: const Icon(Icons.add),
          label: Text(l10n.housingAgreementRuleAdd),
        ),
      ],
    );
  }

  Widget _suggestionTile(
    AppLocalizations l10n, {
    required String id,
    required String title,
    required String body,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: ValueKey(id),
        title: Text(title),
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  if (!_draft.clauseRules.dismissedSuggestionIds.contains(id)) {
                    _draft.clauseRules.dismissedSuggestionIds.add(id);
                  }
                });
                unawaited(_persist());
              },
              icon: const Icon(Icons.close),
              label: Text(l10n.housingAgreementRuleDismissSuggestion),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCustomRule(AppLocalizations l10n) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final d10n = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(d10n.housingAgreementRuleAddTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: d10n.housingAgreementRuleCustomTitleLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyCtrl,
                    decoration: InputDecoration(
                      labelText: d10n.housingAgreementRuleCustomBodyLabel,
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(d10n.housingPlanCancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(d10n.housingPlanSave)),
            ],
          );
        },
      );
      if (ok != true || !mounted) return;
      final t = titleCtrl.text.trim();
      if (t.isEmpty) return;
      setState(() {
        _draft.clauseRules.customRules.add(
          AgreementCustomRule(
            id: 'rule:${DateTime.now().microsecondsSinceEpoch}',
            title: t,
            body: bodyCtrl.text.trim(),
            enabled: true,
          ),
        );
      });
      await _persist();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleCtrl.dispose();
        bodyCtrl.dispose();
      });
    }
  }

  Widget _buildStepBody(AppLocalizations l10n) {
    switch (_stepIndex) {
      case 0:
        return _stepVehicle(l10n);
      case 1:
        return _stepOwner(l10n);
      case 2:
        return _stepParticipants(l10n);
      case 3:
        return _stepInsurance(l10n);
      case 4:
        return _stepCurrentState(l10n);
      case 5:
        return _stepMaintenance(l10n);
      case 6:
        return _stepAvailability(l10n);
      case 7:
        return _stepFuel(l10n);
      case 8:
        return _stepClauses(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.prefs,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(centerTitle: true, title: Text(l10n.carSharingPlanTitle)),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stepperRail(l10n),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                      child: _stepIndex == 2
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton.filledTonal(
                                  tooltip: l10n.housingPlanFewerParticipantsTooltip,
                                  onPressed: _draft.coParticipants.length <= 1
                                      ? null
                                      : () => _setCoParticipantCount(_draft.coParticipants.length - 1),
                                  icon: const Icon(Icons.remove),
                                ),
                                Expanded(
                                  child: Text(
                                    l10n.housingPlanParticipantsCount(1 + _draft.coParticipants.length),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                ),
                                IconButton.filledTonal(
                                  tooltip: l10n.housingPlanMoreParticipantsTooltip,
                                  onPressed: _draft.coParticipants.length >= 7
                                      ? null
                                      : () => _setCoParticipantCount(_draft.coParticipants.length + 1),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            )
                          : Text(
                              _stepTitles(l10n)[_stepIndex],
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                    ),
                    Expanded(child: _buildStepBody(l10n)),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        16 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_stepIndex > 0)
                            OutlinedButton(
                              onPressed: () async {
                                await _persist();
                                if (mounted) setState(() => _stepIndex--);
                              },
                              child: Text(l10n.housingPlanBack),
                            ),
                          if (_stepIndex > 0) const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () async {
                              await _persist();
                              if (!mounted) return;
                              if (_stepIndex >= _stepCount - 1) {
                                if (context.mounted) Navigator.of(context).pop();
                                return;
                              }
                              setState(() => _stepIndex++);
                            },
                            child: Text(
                              _stepIndex >= _stepCount - 1
                                  ? l10n.carSharingPlanFinish
                                  : l10n.housingPlanNext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddCarMaintenanceDialog extends StatefulWidget {
  const _AddCarMaintenanceDialog({this.initial});

  final CarSharingMaintenanceLineDraft? initial;

  @override
  State<_AddCarMaintenanceDialog> createState() => _AddCarMaintenanceDialogState();
}

class _AddCarMaintenanceDialogState extends State<_AddCarMaintenanceDialog> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late bool _recurring;
  late int _dayOfMonth;
  late String _lineId;

  @override
  void initState() {
    super.initState();
    final ex = widget.initial;
    _title = TextEditingController(text: ex?.title ?? '');
    _amount = TextEditingController(
      text: ex == null || ex.amountMinor == 0
          ? ''
          : (ex.amountMinor / 100).toStringAsFixed(2),
    );
    _recurring = ex?.isRecurring ?? true;
    _dayOfMonth = ex?.recurrenceDayOfMonth ?? 1;
    _lineId = ex?.id ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? l10n.carSharingMaintenanceEditTitle : l10n.carSharingMaintenanceAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.carSharingMaintenanceTitleLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              decoration: InputDecoration(labelText: l10n.carSharingMaintenanceAmountLabel),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v ?? false),
              title: Text(l10n.housingPlanRecurringSwitch),
            ),
            if (_recurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _dayOfMonth,
                decoration: InputDecoration(labelText: l10n.housingPlanDayOfMonthLabel),
                items: [for (var d = 1; d <= 31; d++) DropdownMenuItem(value: d, child: Text('$d'))],
                onChanged: (v) => setState(() => _dayOfMonth = v ?? 1),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.housingPlanCancel)),
        FilledButton(
          onPressed: () {
            final t = _title.text.trim();
            if (t.isEmpty) return;
            final amt = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
            Navigator.pop(
              context,
              CarSharingMaintenanceLineDraft(
                id: _lineId.isNotEmpty ? _lineId : 'maint:${DateTime.now().microsecondsSinceEpoch}',
                title: t,
                amountMinor: (amt * 100).round(),
                isRecurring: _recurring,
                recurrenceDayOfMonth: _dayOfMonth,
              ),
            );
          },
          child: Text(l10n.housingPlanSave),
        ),
      ],
    );
  }
}
