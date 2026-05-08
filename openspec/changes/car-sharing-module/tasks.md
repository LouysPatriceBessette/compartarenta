## 1. Domain model & storage

- [ ] 1.1 Define car-sharing entities (Vehicle, Participant, CarUse, Reservation, CarExpense, Violation) and their identifiers
- [ ] 1.2 Implement local persistence for entities (create/update/delete, list queries by vehicle and date window)
- [ ] 1.3 Implement audit-friendly editing for odometer corrections (correction flag + note)

## 2. Odometer logging & distance derivation

- [ ] 2.1 Build UI flow to create a car use (select participant, start time, before odometer)
- [ ] 2.2 Build UI flow to complete a car use (end time, after odometer)
- [ ] 2.3 Enforce monotonic odometer validation per vehicle; add “mark as correction” override
- [ ] 2.4 Compute and display distance per car use as \(after - before\)

## 3. Fuel purchases

- [ ] 3.1 Build UI to record fuel purchase (date/time, cost, volume, odometer, full-tank boolean, vehicle)
- [ ] 3.2 Implement fuel purchase listing and filtering by date window
- [ ] 3.3 Implement “included in window” selection logic for consumption calculations (timestamp-based)

## 4. Metrics (consumption & usage)

- [ ] 4.1 Implement total distance per participant and total distance per window
- [ ] 4.2 Compute usage ratios per participant for a selected window
- [ ] 4.3 Compute and display consumption per km between the last two full-tank fuel entries (and show last full-tank anchor date)
- [ ] 4.4 Add “insufficient data” handling (zero distance, missing purchases, missing full-tank anchors) and show methodology/explainability
- [ ] 4.5 If last full-tank anchor date is older than one month, notify after non-full fuel entry to suggest doing a full tank next time

## 5. Expense sharing & allocations

- [ ] 5.1 Implement allocation engine interface (inputs: participants, expenses, rule selection, window metrics)
- [ ] 5.2 Implement equal split allocation for shared car expenses
- [ ] 5.3 Implement usage-weighted allocation using computed usage ratios
- [ ] 5.4 Implement fixed ratios per participant and divergence threshold for adjustment suggestions
- [ ] 5.5 Build allocation review UI with explainable breakdown (included expenses + rule inputs)

## 6. Maintenance and repairs log

- [ ] 6.1 Build UI to record maintenance event (date, category, cost, notes, optional attachment metadata)
- [ ] 6.2 Implement maintenance listing and inclusion in allocation windows

## 7. Traffic violations log

- [ ] 7.1 Build UI to record a violation (date, type, amount, optional responsible participant)
- [ ] 7.2 Implement responsibility resolution and allocation behavior: 100% only when responsibility is finalized; otherwise use group allocation rule

## 8. Reservations

- [ ] 8.1 Build UI to create/edit reservation (start/end, participant, optional note)
- [ ] 8.2 Implement overlap detection and blocking with conflict display
- [ ] 8.3 Build reservations schedule view (upcoming list or calendar) per vehicle

## 9. Navigation & module integration

- [ ] 9.1 Add navigation entry points for car-sharing module (vehicles, uses, expenses, metrics, reservations)
- [ ] 9.2 Ensure car-sharing data is scoped by group and not mixed across groups
