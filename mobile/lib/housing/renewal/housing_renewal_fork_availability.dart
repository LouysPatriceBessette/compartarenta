import '../../db/app_database.dart';
import '../amendment/housing_active_agreement_service.dart';

/// Whether the hub may offer « new term from current plan » (fork active revision).
Future<bool> hubRenewalForkAvailable(AppDatabase db, String planId) async {
  final agreement = await db.getAgreementForPlan(planId);
  if (agreement == null) return false;
  if (HousingActiveAgreementService(db).isAgreementPeriodOpen(agreement)) {
    return false;
  }
  final pkg = await (db.select(db.proposalPackages)
        ..where((t) => t.planId.equals(planId)))
      .getSingleOrNull();
  return pkg?.activeRevisionId != null;
}
