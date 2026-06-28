## 1. Sharing domain

- [ ] 1.1 Define VehicleSharingLink (vehicle, owner, borrower, status)
- [ ] 1.2 Owner invite flow (requires `vehicle` + `vehicle-sharing`)
- [ ] 1.3 Borrower accept / owner revoke flows
- [ ] 1.4 Multi-vehicle and multi-borrower list surfaces

## 2. Borrower usage

- [ ] 2.1 Borrower use session UI on shared vehicles (start/end readings)
- [ ] 2.2 Gap attribution notifications to attributed Emprunteur/Propriétaire (`vehicle-odometer-gap-attribution`)
- [ ] 2.3 Quick-action forward path (odometer, fuel, maintenance report, damage/violation) per `vehicle-quick-actions-ui`
- [ ] 2.4 Emprunteur hub does not show Propriétaire-only alert tiles or lifetime owner metrics

## 3. Metrics & reconciliation

- [ ] 3.1 Borrower-scoped distance and fuel statistics
- [ ] 3.2 Reconciliation window per borrower
- [ ] 3.3 Owner aggregate view across all sharers

## 4. Expense sharing

- [ ] 4.1 Category model (Fuel, Maintenance, Violations, Payments)
- [ ] 4.2 Ratio configuration with propose/accept
- [ ] 4.3 Violation responsibility proposals
- [ ] 4.4 Explainable allocation breakdown UI

## 5. Integration

- [ ] 5.1 Contacts picker for invite (connected Contacts only)
- [ ] 5.2 Relay sync for sharing links and usage facts
- [ ] 5.3 Gate borrowing on `vehicle-sharing`; gate sharing out on both modules
- [ ] 5.4 Vehicle sharing hub (`vehicle-sharing-hub-ui`): accessible vehicles, statistics, quick actions
- [ ] 5.5 Remove any sharing-side dependencies on prototype `car_sharing` screens (`vehicle-legacy-code-removal`)
