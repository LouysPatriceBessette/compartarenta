## 1. Domain model & storage

- [ ] 1.1 Define Vehicle, VehicleUse, FuelPurchase, MaintenanceEvent, TrafficViolation entities with fixed owner
- [ ] 1.2 Support vehicle kinds (car, truck, motorcycle, boat) as metadata
- [ ] 1.3 Implement local persistence scoped by owner; multi-vehicle per owner
- [ ] 1.4 Implement audit-friendly odometer correction (flag + note)

## 2. Odometer & distance

- [ ] 2.1 Owner use flow: before/after odometer, distance derivation
- [ ] 2.2 Monotonic odometer validation per vehicle
- [ ] 2.3 Attribute uses to owner or borrower Contact (borrower path wired with sharing module)

## 3. Fuel & owner metrics

- [ ] 3.1 Owner fuel purchase UI (full-tank flag, volume, odometer)
- [ ] 3.2 Owner lifetime and windowed consumption per km (full-tank anchors)
- [ ] 3.3 Owner-only stale full-tank suggestion notification

## 4. Maintenance & violations

- [ ] 4.1 Owner maintenance log UI
- [ ] 4.2 Owner-only distance/time maintenance reminders
- [ ] 4.3 Violations log with responsibility state

## 5. Data portability

- [ ] 5.1 Single-vehicle export (factual snapshot, module manifest)
- [ ] 5.2 Import as new owned vehicle on buyer device

## 6. Navigation & licensing

- [ ] 6.1 Vehicle module shell (owned vehicles list, owner metrics)
- [ ] 6.2 Gate owner features on effective `vehicle` entitlement
