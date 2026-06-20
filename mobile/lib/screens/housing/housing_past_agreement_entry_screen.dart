import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/housing_module_exit.dart';
import '../../housing/housing_navigation_intent.dart';
import '../../housing/participation/housing_participation_membership_service.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../widgets/screen_body_padding.dart';
import 'housing_active_plan_screen.dart';
import 'housing_plan_screen.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

/// Entry screen when the local user has departed but the housing plan remains
/// in force on this device (past agreement hub + new plan).
class HousingPastAgreementEntryScreen extends StatelessWidget {
  const HousingPastAgreementEntryScreen({
    super.key,
    required this.planId,
    required this.packageId,
    required this.prefs,
  });

  final String planId;
  final String packageId;
  final AppPreferences prefs;

  Future<void> _openPastAgreementHub(BuildContext context) async {
    await navigateToRoute<void>(context, 
      MaterialPageRoute<void>(
        builder:
            (_) => HousingActivePlanScreen(
              planId: planId,
              packageId: packageId,
              prefs: prefs,
            ),
      ),
    );
  }

  Future<void> _createNewPlan(BuildContext context) async {
    final id = 'housing:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    await HousingNavigationIntent.navigateToPlanScreenRootOverlay<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => HousingPlanScreen(
              prefs: prefs,
              planId: id,
              openEditorInitially: true,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = effectiveDateFormat(prefs);
    final db = AppDatabase.processScope;
    final selfId = '$planId:self';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) exitHousingModule(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => exitHousingModule(context)),
          title: Text(l10n.homeModuleHousing),
        ),
        body: FutureBuilder<({String titlePrefix, String periodRange})>(
          future: HousingParticipationMembershipService(db).hubTitleParts(
            planId: planId,
            selfParticipantId: selfId,
            activeHubTitleL10n: l10n.housingActiveHubTitle,
            pastHubTitleL10n: l10n.housingPastHubTitle,
            formatDate: (d) => formatPreferenceDate(d, dateFmt),
          ),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final parts = snap.data;
            final periodRange = parts?.periodRange.trim() ?? '';
            final pastLabel =
                periodRange.isEmpty
                    ? l10n.housingPastHubTitle
                    : '${l10n.housingPastHubTitle} $periodRange';

            return ListView(
              padding: screenBodyScrollPadding(context),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(pastLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openPastAgreementHub(context),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _createNewPlan(context),
                  child: Text(l10n.housingArchiveCreateNewPlan),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
