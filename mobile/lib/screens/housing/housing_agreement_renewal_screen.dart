import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_active_agreement_service.dart';
import '../../housing/proposals/housing_proposal_transport_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import 'housing_plan_screen.dart';

/// End agreement or fork a new term (roster changes require a new negotiation).
class HousingAgreementRenewalScreen extends StatefulWidget {
  const HousingAgreementRenewalScreen({
    super.key,
    required this.planId,
    required this.prefs,
    this.rosterChangeOnly = false,
  });

  final String planId;
  final AppPreferences prefs;
  final bool rosterChangeOnly;

  @override
  State<HousingAgreementRenewalScreen> createState() =>
      _HousingAgreementRenewalScreenState();
}

class _HousingAgreementRenewalScreenState extends State<HousingAgreementRenewalScreen> {
  bool _working = false;

  Future<void> _forkNewTerm() async {
    if (_working) return;
    setState(() => _working = true);
    final db = AppDatabase.processScope;
    final draftId = 'housing:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await HousingProposalTransportService(db).createForkDraftFromActiveRevision(
        listPlanId: widget.planId,
        draftPlanId: draftId,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => HousingPlanScreen(
            prefs: widget.prefs,
            planId: draftId,
            openEditorInitially: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).housingPlanCouldNotContinue('$e')),
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _endAgreementNow() async {
    if (_working) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.housingAgreementEndConfirmTitle),
        content: Text(l10n.housingAgreementEndConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.housingAgreementEndConfirmAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _working = true);
    try {
      await HousingActiveAgreementService(
        AppDatabase.processScope,
      ).closeAgreementAtToday(widget.planId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingAgreementEndedSnackbar)),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final intro = widget.rosterChangeOnly
        ? l10n.housingAmendmentRosterChangeBody
        : l10n.housingAgreementRenewalIntro;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.rosterChangeOnly
              ? l10n.housingAmendmentRosterChangeTitle
              : l10n.housingAgreementRenewalTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(intro),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _working ? null : _forkNewTerm,
            child: Text(l10n.housingAgreementRenewalFork),
          ),
          const SizedBox(height: 12),
          if (!widget.rosterChangeOnly)
            OutlinedButton(
              onPressed: _working ? null : _endAgreementNow,
              child: Text(l10n.housingAgreementEndNow),
            ),
        ],
      ),
    );
  }
}
