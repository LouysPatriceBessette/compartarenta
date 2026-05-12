## Why

Currently the app assumes a single, monolithic subscription that gates "the plan". The product is evolving to support **multiple independent modules** (housing, vehicle, and others later). Users will want to subscribe to just one module, or to several, and may eventually be offered a combined bundle at a reduced price. The existing change `licensing-trial-and-plan-entitlement` covers the housing-plan licensing rules and stays scoped to housing. We need a **separate, module-aware licensing capability** that defines how per-module subscriptions are modeled in the platform stores (Google Play, Apple App Store), how the app enforces per-module entitlement on-device, and how future combined bundle offers can be introduced without re-architecting.

## What Changes

- Introduce a **module entitlement model**: each functional module (`housing`, `vehicle`, future modules) is gated by its own independently-purchasable subscription.
- Define **store product mapping**:
  - **Apple App Store**: one **subscription group per module** (so users can hold simultaneous active subscriptions across modules; App Store enforces "one active per group" within each group).
  - **Google Play**: one **subscription product per module**, optionally exposing multiple base plans per module (e.g., monthly, prepaid, annual). Combined offers MAY later use Play's "Subscription with add-ons" capability (auto-renewing only, same billing period, regional limits).
- Define **bundle product mapping** as a separate, optional product per platform (e.g., "Housing + Vehicle bundle"), with cross-module entitlement granted by the bundle receipt without requiring per-module individual subscriptions.
- Define a **module entitlement state machine** per module that mirrors the housing lifecycle defined in `licensing-trial-and-plan-entitlement` (free / linked-not-active / active-trial / active-paid / delinquent-grace / delinquent-readonly) but is **evaluated independently per module**.
- Define **module-scoped data isolation and export**: data created in one module is owned by that module, exportable per module, and never blocked by the entitlement state of another module.
- Define **enable/disable UX**: users can independently turn a module on or off; disabling a module retains its local data but pauses module-specific UI and stops module-related sync.
- Define **per-module trial rules** so each module starts its own trial timeline on its first "active use", independent from any other module's timeline.
- Define **interaction rules** with the existing housing licensing change: `licensing-trial-and-plan-entitlement` becomes one **instance** of the per-module licensing model applied to the housing module; it is not removed or renumbered.

## Capabilities

### New Capabilities

- `module-entitlement-model`: Define what a "module" is in the product, how entitlement is represented in-app, and how modules are isolated from one another.
- `store-product-mapping-per-module`: Define how each module maps to a Google Play subscription product and an Apple App Store subscription group, including constraints from each platform.
- `bundle-product-mapping`: Define how optional combined offers (e.g., "Housing + Vehicle") are modeled on each platform without preventing future modules from being added.
- `module-enable-disable-and-data-isolation`: Define enable/disable behavior, per-module data isolation, and per-module export independent from other modules' entitlement state.
- `per-module-trial-and-renewal`: Define how trial start, renewal anchor date, and delinquency timeline apply **per module**, mirroring `licensing-trial-and-plan-entitlement` semantics but scoped to a single module.

### Modified Capabilities

<!-- None. `licensing-trial-and-plan-entitlement` remains the source of truth for housing-specific licensing rules and is intentionally not modified by this change. -->

## Impact

- Establishes a product contract that the app is **multi-module** at the platform-store level, not just internally.
- Requires the in-app entitlement layer to evaluate state **per module**, not globally.
- Influences settings UI (per-module toggles), navigation (module picker / shell), and onboarding (which modules to set up first).
- Future modules can be added by following this contract without re-defining store-mapping rules.
- Sets the foundation that future combined bundles can be introduced as their own store product without invalidating existing per-module subscriptions.
