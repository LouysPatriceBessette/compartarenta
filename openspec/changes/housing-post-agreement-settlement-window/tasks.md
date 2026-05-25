## 1. Settlement window state

- [ ] 1.1 Add a helper that computes whether an ended agreement is `settlement-open` from `periodEnd`, current local date, and current participant balances.
- [ ] 1.2 Keep ended agreements read-only for amendments while allowing settlement-only expense operations during the settlement window.
- [ ] 1.3 Ensure a successor agreement can coexist with a prior settlement-open agreement without merging their operational state.

## 2. Expense entry gating

- [ ] 2.1 Update housing expense-entry gating so ended agreements allow entry only while the settlement window is open.
- [ ] 2.2 Extend the realized-expense date picker to allow dates through the settlement-window end, while keeping entries scoped to the ended agreement.
- [ ] 2.3 Add targeted tests for blocked vs allowed post-end entry dates.

## 3. Ledger and navigation

- [ ] 3.1 Centralize the accessible month-window calculation for the monthly summary screen.
- [ ] 3.2 Support the documented near-end-of-month extension and settlement-month visibility in monthly navigation.
- [ ] 3.3 Add targeted tests for the month-window examples and settlement-month behavior.

## 4. Parallel agreement UX

- [ ] 4.1 Expose enough UI state to distinguish an in-force agreement from a settlement-open ended agreement.
- [ ] 4.2 Verify hub / selector routing can open the prior agreement for settlement while also opening the successor agreement for current operations.
