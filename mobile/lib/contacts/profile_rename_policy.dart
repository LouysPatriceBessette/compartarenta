import 'dart:convert';

import '../db/app_database.dart';
import '../housing/participation/housing_participation_change_service.dart';
import '../housing/proposals/housing_proposal_revision_state.dart';

/// Why the local user cannot change their own display name right now.
enum ProfileRenameBlockKind {
  openProposalVote,
  pendingParticipationChange,
}

/// A housing plan that blocks renaming the local user's display name.
class ProfileRenameBlock {
  const ProfileRenameBlock({
    required this.kind,
    required this.planId,
    required this.planTitle,
  });

  final ProfileRenameBlockKind kind;
  final String planId;
  final String planTitle;
}

/// Plans where the local user is on roster and an open vote is in progress.
///
/// Blocks self display-name changes during open proposal/amendment votes and
/// pending participation-change votes (including voluntary withdrawal).
Future<List<ProfileRenameBlock>> listProfileRenameBlocks(
  AppDatabase db,
) async {
  final blocks = <ProfileRenameBlock>[];
  final changeSvc = HousingParticipationChangeService(db);
  final housingPlans = await (db.select(db.plans)
        ..where((t) => t.type.equals('housing')))
      .get();

  for (final plan in housingPlans) {
    final selfPid = '${plan.id}:self';
    final selfRow = await (db.select(db.participants)
          ..where((t) => t.id.equals(selfPid)))
        .getSingleOrNull();
    if (selfRow == null) continue;

    final title = plan.title.trim().isEmpty ? plan.id : plan.title.trim();
    var blocked = false;

    final pendingChange = await changeSvc.pendingForPlan(plan.id);
    if (pendingChange != null) {
      blocks.add(
        ProfileRenameBlock(
          kind: ProfileRenameBlockKind.pendingParticipationChange,
          planId: plan.id,
          planTitle: title,
        ),
      );
      blocked = true;
    }

    if (!blocked) {
      final packages = await (db.select(db.proposalPackages)
            ..where((t) => t.planId.equals(plan.id)))
          .get();
      for (final pkg in packages) {
        final pendingRevisionId = pkg.pendingRevisionId;
        if (pendingRevisionId == null || pendingRevisionId.isEmpty) continue;

        final rev = await (db.select(db.proposalRevisions)
              ..where((t) => t.id.equals(pendingRevisionId)))
            .getSingleOrNull();
        if (rev == null) continue;

        try {
          final payload = jsonDecode(rev.payloadJson) as Map<String, dynamic>;
          final state = HousingProposalRevisionState.fromPayload(payload);
          if (state.isOpen && !state.isExpiredByClock) {
            blocks.add(
              ProfileRenameBlock(
                kind: ProfileRenameBlockKind.openProposalVote,
                planId: plan.id,
                planTitle: title,
              ),
            );
            break;
          }
        } catch (_) {
          // Ignore unparsable revision payloads.
        }
      }
    }
  }

  return blocks;
}

/// Whether a display-name change should be blocked and relay-broadcast skipped.
Future<bool> profileDisplayNameChangeBlocked(AppDatabase db) async {
  final blocks = await listProfileRenameBlocks(db);
  return blocks.isNotEmpty;
}
