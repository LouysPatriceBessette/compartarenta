import 'package:flutter/material.dart';

import '../../widgets/app_dialog.dart';
import '../../db/app_database.dart';
import '../../housing/participation/housing_participation_change_service.dart';
import '../../housing/participation/housing_withdrawal_penalty_ledger.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../widgets/screen_body_padding.dart';
import '../help/help_faq_screen.dart';

/// Major change: voluntary withdrawal, ejection, or invite-participant guidance.
class HousingAgreementRenewalScreen extends StatefulWidget {
  const HousingAgreementRenewalScreen({
    super.key,
    required this.planId,
    required this.packageId,
    required this.prefs,
    this.rosterChangeOnly = false,
  });

  final String planId;
  final String packageId;
  final AppPreferences prefs;

  /// Legacy parameter; major-change screen always shows participation flows.
  final bool rosterChangeOnly;

  @override
  State<HousingAgreementRenewalScreen> createState() =>
      _HousingAgreementRenewalScreenState();
}

class _HousingAgreementRenewalScreenState
    extends State<HousingAgreementRenewalScreen> {
  bool _working = false;
  int _activeCount = 0;
  List<Participant> _roster = const [];
  String _selfId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.processScope;
    final svc = HousingParticipationChangeService(db);
    final count = await svc.membershipService.activeParticipantCount(
      widget.planId,
    );
    final roster = await svc.membershipService.activeParticipantsForPlan(
      widget.planId,
    );
    if (!mounted) return;
    setState(() {
      _activeCount = count;
      _roster = roster;
      _selfId = selfParticipantIdForPlan(widget.planId);
    });
  }

  Future<void> _proposeAndBroadcast(
    Future<HousingParticipationChange> Function() propose, {
    required bool useNotifyKind,
  }) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final change = await propose();
      final orch = HandshakeOrchestrator.maybeInstance;
      if (orch != null) {
        if (useNotifyKind) {
          await orch.sendParticipationChangeNotify(changeId: change.id);
        } else {
          await orch.sendParticipationChangePropose(changeId: change.id);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirmVoluntaryWithdrawal() async {
    final l10n = AppLocalizations.of(context);
    final svc = HousingParticipationChangeService(AppDatabase.processScope);
    final minNotice = await svc.minNoticeDaysForParticipant(
      widget.planId,
      _selfId,
    );
    final defaultDate = DateTime.now().add(Duration(days: minNotice));
    if (!mounted) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: defaultDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null || !mounted) return;

    final penaltyApplies = await svc.shouldApplyEarlyWithdrawalPenalty(
      planId: widget.planId,
      participantId: _selfId,
      departureDate: picked,
    );
    if (!mounted) return;

    var body = l10n.housingParticipationChangeWithdrawalConfirmBody(
      formatPreferenceDate(picked, effectiveDateFormat(widget.prefs)),
    );
    if (penaltyApplies) {
      final penaltyMinor = await HousingWithdrawalPenaltyLedger(
        AppDatabase.processScope,
      ).penaltyMinorFor(planId: widget.planId, participantId: _selfId);
      body =
          '$body\n\n${l10n.housingParticipationChangeWithdrawalPenaltyHint(formatMinorAsMoneyForLocale(widget.prefs.languageCode ?? 'en', penaltyMinor, widget.prefs.currency))}';
    }

    if (!mounted) return;
    final ok = await showAppDialog<bool>(
      context: context,
      guardKey: 'housingAgreementRenewal.withdrawalConfirm',
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.housingParticipationChangeWithdrawalConfirmTitle),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.housingParticipationChangeConfirmAction),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;

    await _proposeAndBroadcast(
      () => svc.proposeVoluntaryWithdrawal(
        planId: widget.planId,
        initiatorParticipantId: _selfId,
        departureDate: picked,
      ),
      useNotifyKind: false,
    );
  }

  Future<void> _showInviteParticipantInfo() async {
    final l10n = AppLocalizations.of(context);
    await showAppDialog<void>(
      context: context,
      guardKey: 'housingAgreementRenewal.inviteParticipantInfo',
      builder: (ctx) => AlertDialog(
        title: Text(l10n.housingParticipationChangeInviteParticipantTitle),
        content: Text(l10n.housingParticipationChangeInviteParticipantBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonDone),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openHelpFaq(
                context,
                anchor: HelpFaqAnchors.housingInviteParticipant,
              );
            },
            child: Text(l10n.housingParticipationChangeInviteParticipantFaqLink),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEjection() async {
    final l10n = AppLocalizations.of(context);
    final candidates =
        _roster.where((p) => p.id != _selfId).toList(growable: false);
    if (candidates.isEmpty) return;

    String? selectedId = candidates.first.id;
    final ok = await showAppDialog<bool>(
      context: context,
      guardKey: 'housingAgreementRenewal.replaceParticipant',
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(l10n.housingParticipationChangeEjectionConfirmTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.housingParticipationChangeEjectionConfirmBody),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedId,
                    items: [
                      for (final p in candidates)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(p.displayName),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => selectedId = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed:
                      selectedId == null ? null : () => Navigator.pop(ctx, true),
                  child: Text(l10n.housingParticipationChangeConfirmAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || selectedId == null || !mounted) return;

    if (_working) return;
    setState(() => _working = true);
    try {
      final change = await HousingParticipationChangeService(
        AppDatabase.processScope,
      ).proposeEjection(
        planId: widget.planId,
        initiatorParticipantId: _selfId,
        targetParticipantId: selectedId!,
      );
      final orch = HandshakeOrchestrator.maybeInstance;
      if (orch != null) {
        await orch.sendParticipationChangePropose(changeId: change.id);
        await orch.sendParticipationChangeNotify(changeId: change.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canUseWithdrawal = _activeCount >= 2;
    final canUseEjection = _activeCount > 2;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingAmendmentRosterChangeTitle)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          Text(l10n.housingParticipationChangeIntroLine1),
          const SizedBox(height: 8),
          Text(l10n.housingParticipationChangeIntroLine2),
          const SizedBox(height: 24),
          FilledButton(
            onPressed:
                _working || !canUseWithdrawal ? null : _confirmVoluntaryWithdrawal,
            child: Text(l10n.housingParticipationChangeWithdrawalAction),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                _working || !canUseEjection ? null : _confirmEjection,
            child: Text(l10n.housingParticipationChangeEjectionAction),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _working ? null : _showInviteParticipantInfo,
            child: Text(l10n.housingParticipationChangeInviteParticipantAction),
          ),
        ],
      ),
    );
  }
}
