## Implementation status (2026-07-01)

Owner-side **`vehicle`** module: **substantially implemented** on-device (local persistence, hubs, quick actions, consumption metrics, Maestro E2E on Android debug). Remaining gaps: full positive-gap **participant** attribution UI, export/import, consumption-overflow correction (§8), notifications (§11), real entitlement (debug stub today), legacy odometer-photo migration, boat consumption model.

See `vehicle-sharing-module` for collaboration, relay sync, borrower metrics, expense sharing, and **`vehicle-usage-role-separation`** (owner vs borrower path; forbid self-borrow).

## 1. Domain model & storage

- [x] 1.1 Define Vehicle, VehicleUse, FuelPurchase, MaintenanceEvent, TrafficViolation entities with fixed owner
- [x] 1.2 Support vehicle kinds (car, truck, motorcycle, boat) as metadata
- [x] 1.3 Implement local persistence scoped by owner; multi-vehicle per owner
- [x] 1.4 Implement audit-friendly odometer correction (flag + note)

## 2. Odometer & distance

- [x] 2.1 Owner use flow: start/end odometer with required photo, distance derivation
- [x] 2.2 Monotonic / negative-gap flow per `vehicle-odometer-gap-attribution`
- [x] 2.3 Attribute uses to Propriétaire or Emprunteur Contact (sharing path)
- [x] 2.4a Positive gap detection, confirm dialog, correction journal entry, and default `unknown` gap record at session start / standalone (`vehicle-odometer-gap-attribution` partial)
- [ ] 2.4b Participant attribution dialog (Self / approved Emprunteur / Unknown) before finalizing positive gaps
- [ ] 2.4c Propriétaire notification when gap is attributed to Unknown; Emprunteur negative-gap path notifies Propriétaire (strings exist; not wired)

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
- [x] 7.3a Enforce `user-owned-media-storage` on all new odometer and gallery writes (`storeVehicleMeterPhotoFromSource`, `storeVehicleGalleryPhotoFromSource` → public `Documents/Compartarenta/Car/…`)
- [ ] 7.3b Migrate legacy app-private `vehicle_meter_photos/` references to public storage keys (read fallback remains)

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

## 10. Driving-condition consumption (road vehicles)

- [x] 10.1 End-of-use session form: route / city / traffic integer percents (sum = 100) under odometer photo; persist on `VehicleUses`
- [x] 10.2 Tank-to-tank NNLS fit for per-condition L/100 km (minimum two full-tank intervals with session mix data)
- [x] 10.3 Rolling window of five plein→plein intervals; reliability gradation (none / preliminary / reliable / very reliable) with user-facing messages
- [x] 10.4 Persist reliable+ estimate history (`VehicleConsumptionEstimateHistory`); show on statistics screen
- [ ] 10.5 Boat-specific operating-condition mix and consumption model (horometer / marine use patterns — separate from road route/city/traffic)

## 11. Vehicle notifications (deferred)

- [ ] 11.1 **Suspicious session-end tank (borrower)**: when an Emprunteur ends a session with the highest declared tank level after high mileage since the last fuel purchase and confirms the declaration anyway, notify the Propriétaire (relay/push when vehicle notification infrastructure ships).
- [ ] 11.2 **Negative-gap reading maintained**: when a user confirms a lower odometer reading (**Maintain reading, investigate later** on the negative-gap dialog), notify the **Propriétaire** so they can verify the prior reading and correct it in the journal (Emprunteur path is specified in `vehicle-odometer-gap-attribution`; Propriétaire self-maintain still needs an in-app/reminder path to review earlier readings — wire when vehicle notification infrastructure ships).

## 12. Session-end distance plausibility guard

- [x] 12.0 **Session-end distance guard**: on session **end** reading, compare `end − start` to `(tankCapacity + fuelPurchasedDuringSession) × 100 / guardConsumption`; guard consumption = max(route, city, traffic) known values or 7.5 L/100 km; confirmation dialog before save when exceeded (`vehicle_odometer_gap_plausibility`, `confirmSuspiciousSessionEndDistanceBeforeSave`). Not applied at session start or standalone gap attribution.

## 13. Consumption estimation mode

- [x] 13.1 Vehicle setting: simple vs detailed consumption estimation mode (add vehicle + edit details); default detailed
- [x] 13.2 Simple mode: single L/100 km on hub card; reliability from same-mode plein→plein periods only
- [x] 13.3 Detailed mode: route / city / traffic breakdown when enough same-mode detailed sessions; borrower mix optional unless owner requires it (owner must use detailed)
- [x] 13.4 Mode transitions: carry reliable detailed average into simple; show simple estimate with insufficient-data message when switching to detailed
- [x] 13.5 FAQ: estimation limitations when not all users declare detailed driving mix (`helpFaqVehicleConsumptionEstimation`)
- [ ] 13.6 **Per-borrower detailed mix** (vehicle sharing module): switch to require route / city / traffic per emprunteur per vehicle; wire `shouldCollectDetailedDrivingMix` to sharing link instead of vehicle-level `requireDetailedDrivingMixForBorrowers`

## 14. Android E2E QA (Maestro, debug Android)

Single-device scenarios after programmatic seed + clock push (`docs/qa-android-e2e.md`). Multi-device sharing and relay flows remain manual or future scenarios.

- [x] 14.1 Scenario manifests + flows: `vehicle_add`, `vehicle_fuel_purchase`, `vehicle_use_session`, `vehicle_session_start_gap`, `vehicle_standalone_meter_gap`, `vehicle_consumption` (`qa/scenarios/`, `qa/flows/`).
- [x] 14.2 Vehicle seed helpers + postconditions (`qa_vehicle_seed_helpers.dart`, `qa_vehicle_consumption_seed.dart`, `qa_scenario_seed.dart`, matching tests).
- [x] 14.3 Hub semantics for consumption reliability and per-condition breakdown (`qa_vehicle_semantics.dart`, `vehicle_module_hub_screen.dart`).
- [ ] 14.4 Sharing-hub and multi-role scenarios (invite, accept, borrower session, gap notify).
