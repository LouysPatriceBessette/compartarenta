## REMOVED Requirements

### Requirement: Manual expense category step in housing wizard

**Reason:** Categories are created automatically when a non-equal split is saved; users no longer name categories before expenses.

**Migration:** Existing `PlanGroup` rows remain in DB; wizard skips step. Groups can be edited only indirectly via expense edit or a future maintenance flow.

### Requirement: Separate per-participant split wizard step

**Reason:** Split is edited inline on each expense form.

**Migration:** `PlanRatio` data remains; split step UI removed. Validation runs per line at save and when advancing past expenses step (all lines have ratios summing to 10000).

## MODIFIED Requirements

### Requirement: Ratios stored per line or per group consistently

Ratios SHALL be stored per line for all newly authored housing expenses. Orphan group-level ratio rows on local drafts MAY be migrated or removed in implementation; proposal payload legacy import is not required.

#### Scenario: New expense save

- **WHEN** the user saves an expense from the unified form
- **THEN** `PlanRatio` rows reference `lineId` only for that expense
