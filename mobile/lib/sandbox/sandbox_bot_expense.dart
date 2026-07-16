import 'dart:math';

import 'package:flutter/foundation.dart';

import '../housing/realized_expense/realized_expense_line_snapshot.dart';
import '../housing/realized_expense/realized_expense_repository.dart';
import '../housing/realized_expense/realized_expense_status.dart';
import '../housing/split_minor_by_weights.dart';
import '../notifications/push_notification_service.dart';
import '../prefs/app_preferences.dart';
import '../relay/handshake_orchestrator.dart';
import 'peer_simulator.dart';
import 'sandbox_mode.dart';

/// One-shot bot expense for the active housing hub (B1 → human review queue).
abstract final class SandboxBotExpense {
  static final _rng = Random();

  static Future<void> simulateRandomBotExpense({
    required String planId,
    required String packageId,
    required AppPreferences prefs,
  }) async {
    if (!SandboxMode.isActive(prefs)) {
      throw StateError('sandbox bot expense requires sandboxMode');
    }
    final sim = PeerSimulator.maybeInstance;
    if (sim == null || sim.bots.isEmpty) {
      throw StateError('no sandbox bots');
    }
    final bot = sim.bots[_rng.nextInt(sim.bots.length)];
    final lines = await bot.db.listPlanLines(planId);
    if (lines.isEmpty) {
      throw StateError('no plan lines for bot expense');
    }
    final line = lines[_rng.nextInt(lines.length)];
    final amountBase = line.amountMinor ?? line.maxAmountMinor ?? 0;
    if (amountBase <= 0) {
      throw StateError('plan line has no amount');
    }

    final ratios = await currentRatiosForPlanLine(bot.db, planId, line.id);
    final ids = <String>[];
    final weightsBps = <int>[];
    for (final r in ratios) {
      ids.add(r.participantId);
      weightsBps.add(r.weight);
    }
    if (ids.isEmpty) {
      ids.add('$planId:self');
      weightsBps.add(10000);
    }
    final selfId = '$planId:self';
    final selfIndex = ids.indexOf(selfId);
    if (selfIndex < 0) {
      throw StateError('bot self not in line ratios');
    }
    final parts = splitMinorByWeights(amountBase, weightsBps);
    final botShare = parts[selfIndex];
    if (botShare <= 0) {
      throw StateError('bot share is zero');
    }
    final factor = <double>[1.0, 0.5, 1.5][_rng.nextInt(3)];
    final amountMinor = (botShare * factor).round().clamp(1, 1 << 30);

    final planRow =
        await (bot.db.select(bot.db.plans)
              ..where((t) => t.id.equals(planId)))
            .getSingleOrNull();
    final currency =
        (planRow?.currency.trim().isNotEmpty ?? false)
            ? planRow!.currency
            : 'CAD';

    final repo = RealizedExpenseRepository(bot.db);
    final draft = await repo.saveDraft(
      packageId: packageId,
      planId: planId,
      planLineId: line.id,
      amountMinor: amountMinor,
      currency: currency,
      paymentDate: DateTime.now().toUtc(),
      payerParticipantId: selfId,
      kind: RealizedExpenseKind.normal,
      description: 'Sandbox bot expense',
      attachments: const [],
    );
    await repo.proposeLocally(draft.id);
    await bot.orchestrator.sendRealizedExpensePropose(expenseId: draft.id);

    final human = HandshakeOrchestrator.maybeInstance;
    if (human != null) {
      await human.pollSteadyStateInboxes();
    }
    await sim.reactOnce();
    if (human != null) {
      await human.pollSteadyStateInboxes();
    }

    try {
      await PushNotificationService.showLocalHousingRealizedExpenseNotification(
        senderDisplayName: bot.displayName,
        expenseId: draft.id,
      );
    } catch (e, st) {
      debugPrint('sandbox bot expense notification failed: $e\n$st');
    }
  }
}
