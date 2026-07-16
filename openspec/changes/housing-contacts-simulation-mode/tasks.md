## 1. Sandbox prefs and bootstrap

- [x] 1.1 Add `sandboxMode` and `sandboxEnteredAt` preference accessors that survive DB wipe
- [x] 1.2 Branch `bootstrap.dart` to attach FakeRelay + start PeerSimulator when `sandboxMode` is true; keep HttpRelay otherwise
- [x] 1.3 Stub/disable entitlement active-use reporting and push/wake registration while sandbox is active
- [x] 1.4 Add release-visible, tappable Simulation ribbon overlay (do not rely on `debugShowCheckedModeBanner`)
- [x] 1.5 When ribbon is visible, reserve 40 px trailing AppBar clearance after the settings gear (home and any other top-right settings control that would collide)

## 2. PeerSimulator and FakeRelay runtime

- [x] 2.1 Promote/reuse `FakeRelayClient` for runtime sandbox (shared with tests or thin wrapper)
- [x] 2.2 Implement PeerSimulator with bot keypair store and auto-ack/auto-accept handlers for in-scope envelope kinds
- [x] 2.3 Ensure simulator posts via orchestrator/FakeRelay paths (no Drift-only accept shortcuts)

## 3. Enter / exit lifecycle and checkpoint

- [x] 3.1 Implement dual-verify checkpoint service (export → verify → fixed private copy → verify → wipe only if both OK)
- [x] 3.2 Implement enter-simulation orchestration (set prefs before wipe, then full restart / reopen instruction)
- [x] 3.3 Implement exit-simulation orchestration (wipe sim → import checkpoint if present → clear prefs → restart)
- [x] 3.4 Wire Simulation ribbon tap → exit dialog (« Sortir du mode simulation? », Annuler / Oui) → exit protocol on Oui
- [x] 3.5 Add ≥8h reopen nudge (dialog/notification; snackbar/dialog fallback if notifications denied) that can invoke exit
- [x] 3.6 Do not add a Settings-only “Exit simulation” row (ribbon + 8h nudge are the product exits)

## 4. Housing wizard entry UI

- [x] 4.1 Add ARB strings (FR/EN/ES) for Mode simulation, dialog body, Annuler/Simuler, Simulation ribbon, exit dialog (« Sortir du mode simulation? » / Oui), 8h nudge, bot expense tile, exhausted-catalog dialog
- [x] 4.2 Add orange Mode simulation button on `housing_plan_screen` step 1 same row as Next; gate on no real draft/active plan
- [x] 4.3 Wire dialog → enter-simulation orchestration

## 5. Sandbox Contacts invite

- [x] 5.1 Define ordered 7-bot catalog (Louys → Youkie) with random avatars from product pool
- [x] 5.2 Replace invite-code UI in sandbox with “add next bot” connected via PeerSimulator
- [x] 5.3 Show Ok-only exhausted-catalog dialog when all seven bots are present
- [x] 5.4 Gate external code generate/redeem paths with sandbox hard checks

## 6. Sandbox Housing hub and modules

- [x] 6.1 Disable (visible) major-change hub tile and block deep links into major-change flows in sandbox
- [x] 6.2 Keep minor “Modify the plan” enabled; rely on PeerSimulator auto-accept
- [x] 6.3 Add orange bot-expense tile above Submit expense (after section divider); one-shot B1 into review queue + local notification; amount = share × {1.0, 0.5, 1.5}; no photo
- [x] 6.4 Disable Vehicle and Vehicle sharing module-home tiles while sandbox (visible)
- [x] 6.5 Block Settings device export/import UI in sandbox (lifecycle checkpoint remains internal-only)

## 7. Tests and verification

- [x] 7.1 Unit/widget tests: prefs survive wipe mock; catalog order; exhausted dialog; entry gate with draft/active plan
- [x] 7.2 Harness tests: FakeRelay + PeerSimulator auto-accept proposal; bot expense appears in review queue
- [x] 7.3 Tests: checkpoint dual-verify refuses wipe on bad copy; exit restores checkpoint
- [x] 7.4 Run `cd mobile && ./tool/flutterw analyze --fatal-infos .` and `./tool/flutterw test` until green
- [x] 7.5 Manual QA PASSED (2026-07-16, Android): add sandbox bot contacts (catalog invite) through connected peers
- [x] 7.6 Manual QA PASSED (2026-07-16, Android): housing plan submit through unanimous acceptance (OS notifications: 3× #7 + 1× #9 in causal order; simulation exit without crash)
