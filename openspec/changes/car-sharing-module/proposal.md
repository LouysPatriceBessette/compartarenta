## Superseded

This change is **superseded** as of 2026-06-27. Do not implement against these specs.

| Former capability | Successor |
| --- | --- |
| `car-sharing-domain-model` | `vehicle-domain-model` + `vehicle-sharing-domain-model` |
| `odometer-logging` | `vehicle-module` → `odometer-logging` |
| `fuel-purchase-tracking` | `vehicle-module` → `fuel-purchase-tracking` |
| `consumption-and-usage-metrics` | `vehicle-module` → `vehicle-consumption-metrics` + `vehicle-sharing-module` → `vehicle-sharing-usage-metrics` |
| `car-expense-sharing` | `vehicle-sharing-module` → `vehicle-expense-sharing` |
| `maintenance-and-repairs-log` | `vehicle-module` → `maintenance-and-repairs-log` |
| `traffic-violations-log` | `vehicle-module` → `traffic-violations-log` |
| `car-reservations` | **Deferred** — see `dev-ideas/2026-06-27-wish-list.md` § Vehicle reservations |

**New changes:**

- `openspec/changes/vehicle-module/`
- `openspec/changes/vehicle-sharing-module/`

**Licensing:** two modules — `vehicle` (owner) and `vehicle-sharing` (collaboration / borrow). See `per-module-licensing-and-bundles` → `module-subscription-dependencies`.

## Original intent (historical)

The original proposal introduced a monolithic "car sharing" module with reservations. Product direction now splits **owner** (`vehicle`) and **sharing** (`vehicle-sharing`) licenses, defers reservations, and uses "vehicle" terminology for all conveyance kinds (car, truck, motorcycle, boat).

See the superseding proposals for current requirements.
