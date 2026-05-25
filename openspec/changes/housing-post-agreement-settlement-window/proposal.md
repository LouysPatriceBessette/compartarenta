## Why

Housing currently treats `periodEnd` as a hard stop for realized-expense entry. In practice, final settlements can happen shortly after the agreement ends, and the group may need to start the next agreement before the previous one has fully netted to zero.

## What Changes

- Allow a limited **post-agreement settlement window** for realized-expense entry when the ended agreement still has non-zero participant balances.
- Bound monthly expense navigation to the agreement months, with a small end-of-month extension when the agreement ends very close to month end.
- Allow users to prepare and manage a **new agreement in parallel** while the previous agreement remains open only for limited settlement activity.
- Keep the post-end exception narrow: it is for closing balances, not for turning an ended agreement back into a normal in-force agreement.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `housing-agreement-amendment-and-closure`: change the end-of-agreement rule so an ended agreement may remain settlement-open for a short, balance-driven window, while a new agreement can coexist operationally.
- `housing-realized-expense-entry`: change realized-expense entry rules to define when post-end entry is allowed, which dates remain selectable, and when the settlement window closes.
- `housing-realized-expense-ledger`: change monthly navigation and ledger visibility rules so accessible months match the agreement window plus the documented settlement exception.

## Impact

- `mobile/lib/screens/housing/housing_realized_expense_form_screen.dart`
- `mobile/lib/screens/housing/housing_monthly_expenses_screen.dart`
- `mobile/lib/screens/housing/housing_active_plan_screen.dart`
- Housing agreement-status helpers and routing that decide whether expense entry is still allowed
- OpenSpec housing agreement / expense-entry / ledger behavior
