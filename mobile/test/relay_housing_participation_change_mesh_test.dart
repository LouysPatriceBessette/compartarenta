import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_test/flutter_test.dart';

import 'housing_participation_change_mesh_harness.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  test(
    'voluntary withdrawal propose, peer acks, and due-date settlement reach all three devices',
    () async {
      final ctx = await setUpParticipationChangeMesh(
        authorPlanId: 'housing:pc-withdraw',
        louysPlanId: 'received:pc-withdraw-louys',
        roberrPlanId: 'received:pc-withdraw-roberr',
      );
      addTearDown(ctx.dispose);

      final roberrPlan = ctx.plans.roberrPlanId;
      final roberrSelf = await lookupParticipantId(
        db: ctx.roberr.db,
        planId: roberrPlan,
        displayName: 'Roberr',
      );
      final departure = DateUtils.dateOnly(DateTime.now());

      final change = await HousingParticipationChangeService(ctx.roberr.db)
          .proposeVoluntaryWithdrawal(
        planId: roberrPlan,
        initiatorParticipantId: roberrSelf,
        departureDate: departure,
      );
      await ctx.roberr.orchestrator.sendParticipationChangePropose(
        changeId: change.id,
      );
      await ctx.pollAll();

      await expectChangeStatusOnAllSides(
        ctx: ctx,
        changeId: change.id,
        status: HousingParticipationChangeStatus.pending,
      );

      final monicaPlan = ctx.plans.authorPlanId;
      final monicaSelf = '$monicaPlan:self';
      await ctx.monica.orchestrator.sendParticipationChangeDecision(
        changeId: change.id,
        participantId: monicaSelf,
        accepted: true,
      );
      await ctx.pollAll();

      final louysPlan = ctx.plans.louysPlanId;
      final louysSelf = await lookupParticipantId(
        db: ctx.louys.db,
        planId: louysPlan,
        displayName: 'Louys',
      );
      await ctx.louys.orchestrator.sendParticipationChangeDecision(
        changeId: change.id,
        participantId: louysSelf,
        accepted: true,
      );
      await ctx.pollAll();

      await expectChangeStatusOnAllSides(
        ctx: ctx,
        changeId: change.id,
        status: HousingParticipationChangeStatus.effective,
      );

      await ctx.pollAll();
      await expectParticipantDepartedOnAllSides(
        ctx: ctx,
        displayName: 'Roberr',
      );
      await expectInactiveParticipantOnAllSides(
        ctx: ctx,
        displayName: 'Roberr',
      );
      await expectTwoWayRatioSplit(
        ctx: ctx,
        remainingA: 'Monica',
        remainingB: 'Louys',
      );

      for (final side in ctx.allSides) {
        final planId = ctx.plans.planIdOn(side, ctx);
        expect(
          await HousingParticipationMembershipService(side.db)
              .activeParticipantCount(planId),
          2,
        );
      }
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'ejection unanimous accept departs target on all three devices',
    () async {
      final ctx = await setUpParticipationChangeMesh(
        authorPlanId: 'housing:pc-eject',
        louysPlanId: 'received:pc-eject-louys',
        roberrPlanId: 'received:pc-eject-roberr',
      );
      addTearDown(ctx.dispose);

      final louysPlan = ctx.plans.louysPlanId;
      final louysSelf = await lookupParticipantId(
        db: ctx.louys.db,
        planId: louysPlan,
        displayName: 'Louys',
      );
      final roberrOnLouys = await lookupParticipantId(
        db: ctx.louys.db,
        planId: louysPlan,
        displayName: 'Roberr',
      );

      final change = await HousingParticipationChangeService(ctx.louys.db)
          .proposeEjection(
        planId: louysPlan,
        initiatorParticipantId: louysSelf,
        targetParticipantId: roberrOnLouys,
      );
      await ctx.louys.orchestrator.sendParticipationChangePropose(
        changeId: change.id,
      );
      await ctx.louys.orchestrator.sendParticipationChangeNotify(
        changeId: change.id,
      );
      await ctx.pollAll();

      await expectChangeStatusOnAllSides(
        ctx: ctx,
        changeId: change.id,
        status: HousingParticipationChangeStatus.pending,
      );

      final monicaPlan = ctx.plans.authorPlanId;
      final monicaSelf = await lookupParticipantId(
        db: ctx.monica.db,
        planId: monicaPlan,
        displayName: 'Monica',
      );
      await ctx.monica.orchestrator.sendParticipationChangeDecision(
        changeId: change.id,
        participantId: monicaSelf,
        accepted: true,
      );
      await ctx.pollAll();

      await expectChangeStatusOnAllSides(
        ctx: ctx,
        changeId: change.id,
        status: HousingParticipationChangeStatus.effective,
      );
      await expectParticipantDepartedOnAllSides(
        ctx: ctx,
        displayName: 'Roberr',
      );
      await expectInactiveParticipantOnAllSides(
        ctx: ctx,
        displayName: 'Roberr',
      );
      await expectTwoWayRatioSplit(
        ctx: ctx,
        remainingA: 'Monica',
        remainingB: 'Louys',
      );

      final roberrPlan = ctx.plans.roberrPlanId;
      final roberrSelf = await lookupParticipantId(
        db: ctx.roberr.db,
        planId: roberrPlan,
        displayName: 'Roberr',
      );
      expect(
        await HousingParticipationMembershipService(ctx.roberr.db)
            .isActiveMember(roberrPlan, roberrSelf),
        isFalse,
      );
      expect(
        await HousingParticipationMembershipService(ctx.monica.db)
            .activeParticipantCount(monicaPlan),
        2,
      );
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
