# Spec orchestration (task 1.2)

**Decision (2026-06-21):** **Amend in place** before archival.

The predecessor OpenSpec changes remain active under `openspec/changes/` (not archived):

| Change | Path |
| --- | --- |
| `privacy-first-sync-architecture` | `openspec/changes/privacy-first-sync-architecture/` |
| `relay-sync-no-persistence` (capability spec inside privacy-first) | `openspec/changes/privacy-first-sync-architecture/specs/relay-sync-no-persistence/spec.md` |
| `notification-permission-management` | `openspec/changes/notification-permission-management/` |

**Action:** update their spec deltas now (task 1.3) so they align with `specs/closed-app-push-delivery/spec.md`. No follow-up OpenSpec change is required for this alignment unless a predecessor is archived before the deltas land.

**Rationale:** auditors and developers read the predecessor privacy specs today; leaving them silent on transport routing tokens would contradict shipped relay schema v2 and the product decision recorded in `design.md` § 1.
