## 1. Domain model & storage

- [x] 1.1 Define Vehicle, VehicleUse, FuelPurchase, MaintenanceEvent, TrafficViolation entities with fixed owner
- [x] 1.2 Support vehicle kinds (car, truck, motorcycle, boat) as metadata
- [x] 1.3 Implement local persistence scoped by owner; multi-vehicle per owner
- [x] 1.4 Implement audit-friendly odometer correction (flag + note)

## 2. Odometer & distance

- [x] 2.1 Owner use flow: start/end odometer with required photo, distance derivation
- [x] 2.2 Monotonic / negative-gap flow per `vehicle-odometer-gap-attribution`
- [x] 2.3 Attribute uses to Propriétaire or Emprunteur Contact (sharing path)
- [x] 2.4 Gap attribution at session start (`vehicle-odometer-gap-attribution`)

## 3. Fuel & owner metrics

- [x] 3.1 Owner fuel purchase UI (full-tank flag, volume, odometer)
- [x] 3.2 Owner lifetime and windowed consumption per km (full-tank anchors)
- [ ] 3.3 Owner-only stale full-tank suggestion notification

## 4. Maintenance & violations

- [x] 4.1 Owner maintenance log UI
- [x] 4.2 Owner-only distance/time maintenance reminders (hub alert tiles; push notifications deferred)
- [x] 4.3 Violations log with responsibility state

## 5. Data portability

- [ ] 5.1 Single-vehicle export (factual snapshot, module manifest)
- [ ] 5.2 Import as new owned vehicle on buyer device

## 6. Navigation, hubs & licensing

- [x] 6.1 Wire existing home tiles (`homeModuleVehicle`, `homeModuleVehicleSharing`) to hubs; replace coming-soon stub (`vehicle-app-home-navigation`)
- [x] 6.2 Vehicle module hub (`vehicle-hub-ui`): My vehicles cards, statistics entry, quick actions
- [x] 6.3 Maintenance alert tiles on owned vehicle cards (`vehicle-maintenance-alert-tiles`)
- [x] 6.4 Shared quick-action forms with local persist (`vehicle-quick-actions-ui`)
- [ ] 6.5 Gate owner features on effective `vehicle` entitlement (debug-only stub; store licensing deferred)

## 7. Vehicle sharing hub & legacy cleanup

- [x] 7.1 Vehicle sharing hub shell (`vehicle-sharing-hub-ui`) wired to same quick-action forms (forward routing)
- [x] 7.2 Remove prototype: `/car` route, `CarSharingPlanScreen`, `CarSharingPlanDraft` prefs (`vehicle-legacy-code-removal`)
