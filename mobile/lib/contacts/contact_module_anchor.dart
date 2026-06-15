import 'dart:convert';

import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../housing/housing_plan_peer_contacts.dart';
import '../housing/participation/housing_participation_change_kind.dart';
import '../housing/participation/housing_participation_change_service.dart';
import '../housing/proposals/housing_proposal_revision_state.dart';

/// Why a contact cannot be disconnected while still anchoring module work.
enum ContactAnchorBlockKind {
  activeAgreement,
  pendingProposalVote,
  pendingParticipationChange,
}

/// A plan that blocks disconnecting a contact referenced on its roster.
class ContactAnchorBlock {
  const ContactAnchorBlock({
    required this.kind,
    required this.planId,
    required this.planTitle,
  });

  final ContactAnchorBlockKind kind;
  final String planId;
  final String planTitle;
}

/// Returns plans where [contactId] anchors active or vote-pending module work.
///
/// Per product policy: contacts in an in-force agreement or in an open
/// proposal / participation vote MUST NOT be disconnected.
Future<List<ContactAnchorBlock>> listContactDisconnectBlocks(
  AppDatabase db,
  String contactId,
) async {
  final blocks = <ContactAnchorBlock>[];
  final plans = await db.listPlansContainingContact(contactId);
  final changeSvc = HousingParticipationChangeService(db);

  for (final plan in plans) {
    final title = plan.title.trim().isEmpty ? plan.id : plan.title.trim();

    final hasActive = await db.planHasActiveAcceptedProposal(plan.id);
    if (hasActive) {
      blocks.add(
        ContactAnchorBlock(
          kind: ContactAnchorBlockKind.activeAgreement,
          planId: plan.id,
          planTitle: title,
        ),
      );
      continue;
    }

    final pendingChange = await changeSvc.pendingForPlan(plan.id);
    if (pendingChange != null) {
      final kind = HousingParticipationChangeKind.fromWire(pendingChange.kind);
      if (kind != null &&
          kind != HousingParticipationChangeKind.voluntaryWithdrawal) {
        blocks.add(
          ContactAnchorBlock(
            kind: ContactAnchorBlockKind.pendingParticipationChange,
            planId: plan.id,
            planTitle: title,
          ),
        );
        continue;
      }
      if (kind == HousingParticipationChangeKind.voluntaryWithdrawal) {
        blocks.add(
          ContactAnchorBlock(
            kind: ContactAnchorBlockKind.pendingParticipationChange,
            planId: plan.id,
            planTitle: title,
          ),
        );
        continue;
      }
    }

    final pkg = await (db.select(db.proposalPackages)
          ..where((t) => t.planId.equals(plan.id)))
        .getSingleOrNull();
    final pendingRevisionId = pkg?.pendingRevisionId;
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
          ContactAnchorBlock(
            kind: ContactAnchorBlockKind.pendingProposalVote,
            planId: plan.id,
            planTitle: title,
          ),
        );
      }
    } catch (_) {
      // Ignore unparsable revision payloads.
    }
  }

  return blocks;
}

/// Whether every co-participant [contactId] on a housing roster is a connected,
/// relay-reachable contact (never stub / local-only / disconnected).
Future<bool> contactIsEligibleHousingPlanParticipant(
  AppDatabase db,
  String contactId,
) async {
  final contact = await db.getContact(contactId);
  if (contact == null) return false;
  if (contact.deletedAt != null) return false;
  if (contact.isBlocked) return false;
  if (contact.kind != 'connected') return false;
  return isRelayReachableContact(contact);
}

/// Local calendar instant when agreement-end vote expiry begins (midnight after
/// [periodEnd] inclusive).
DateTime agreementVoteExpiryStartsAtLocal(DateTime periodEnd) {
  return DateUtils.dateOnly(periodEnd.toLocal()).add(const Duration(days: 1));
}

/// True when unfinished votes on an agreement SHOULD be treated as refused.
bool agreementVoteExpiryApplies({
  required DateTime periodEnd,
  required DateTime now,
}) {
  final expiryLocal = agreementVoteExpiryStartsAtLocal(periodEnd);
  return !DateUtils.dateOnly(now.toLocal()).isBefore(expiryLocal);
}
