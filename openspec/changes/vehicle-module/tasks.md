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
- [ ] 7.3 Migrate legacy app-private odometer photos; enforce `user-owned-media-storage` on all new writes

## 8. Consumption estimate validation & correction (fuel purchase anchors)

Deferred implementation — validate partial-tank fuel purchases against the consumption estimate from full-tank anchors.

**Product rules (confirmed):**

- **Correction + journal entry (immediate on save)** when the user’s declared **after-fill** level implies `before_fill + volume_purchased > tank_capacity` (physical overflow / impossible fill).
- **Owner notification (to implement)** when estimated remaining volume before purchase vs. user-implied before-fill differs by **more than 10 L** — without necessarily triggering a consumption correction (e.g. close match like 22.5 L estimated vs. 20 L implied stays silent).
- **Journal placement:** merged **Odomètre et carburant** list (same sort-by-date stream as fuel purchases and meter readings).

- [ ] 8.1 **Detection on fuel purchase save**: compute estimated remaining before purchase; derive `before_fill_declared` from post-fill tank state (`isFullTank`, `tankFillFraction`, `volumeLiters`, `fuelTankCapacityLiters`). **Overflow** → correction path; **|estimate − before_fill_declared| > 10 L** → schedule owner notification only (no correction unless overflow).
- [ ] 8.2 **Odometer declaration**: use fuel purchase `meterReadingValue` and latest canonical odometer for distance since last anchor when estimating remaining fuel.
- [ ] 8.3 **Tank state declaration**: partial fill is **after** refill; `before_fill_declared = level_after − volume_added`.
- [ ] 8.4 **Consumption recalculation**: on overflow correction, re-anchor using corrected purchase for subsequent `VehicleConsumptionMetrics`.
- [ ] 8.5 **Journal entry** in **Odomètre et carburant**: card line 1 « Estimation de la consommation corrigée », line 2 date/time; detail with before/after narrative (distance window, total fuel in window, estimated vs. declared improbability, corrected consumption).
- [ ] 8.6 **Schema & persistence**: table or typed record for consumption correction events (vehicle id, purchase id, anchors, volumes, rates before/after).
- [ ] 8.7 **Owner notification**: push/local when gap > 10 L (Propriétaire only); wire after notification infrastructure for vehicle module.
- [ ] 8.8 **Tests**: overflow → correction + journal; 22.5 L vs 20 L implied (¾ on 80 L after 40 L) → no correction; >10 L gap without overflow → notification only (mock).

## 9. Oil change interval (vehicle-specific)

- [x] 9.1 Add-vehicle form: ×1000 km/miles (or 50–500 h boat), blur validation, store as interval tenths on `oil` maintenance rule only (`other_fluids` journal-only).
