## Context

The product began as a single shared-housing experience. The roadmap now defines clearly separate functional modules (housing, `vehicle`, `vehicle-sharing`, future), and users will be able to subscribe to any subset subject to `module-subscription-dependencies`. The existing change `licensing-trial-and-plan-entitlement` already specifies a detailed entitlement lifecycle (free → trial → active-paid → grace → read-only) but is scoped to a single "plan" notion that effectively maps to housing. Rather than retrofit that change, this design introduces a **module-aware** entitlement layer that the housing rules become one instance of, and that future modules (starting with vehicle) will adopt as their own instance.

The platform stores impose specific constraints that drive the design:

- **Apple App Store**: subscriptions belong to **subscription groups**, and a user may hold at most one active subscription **per group at a time** (an in-group purchase auto-terminates the previous one). Subscriptions cannot move between groups after creation, so the group layout is a one-way decision.
- **Google Play**: a subscription product can expose **multiple base plans** (e.g., monthly vs prepaid vs annual) and **offers**. Bundling multiple subscriptions in a single purchase is supported via **Subscription with add-ons**, but only across products with the **same recurring billing period**, only for **auto-renewing** base plans, capped at 50 items per purchase, and not available in IN/KR.

These two store models do not natively converge on a "feature toggles inside one subscription" pattern; both work cleanly with "one product per module".

## Goals / Non-Goals

**Goals:**

- Specify that each module is independently purchasable on both stores.
- Specify how the housing module's existing licensing change (`licensing-trial-and-plan-entitlement`) plugs into the per-module model without modification.
- Specify per-module trial start, renewal anchor, grace, read-only, and export semantics that **mirror** housing's lifecycle but are scoped per module.
- Specify how a future combined bundle is added as its own platform product without invalidating per-module subscriptions.
- Specify the on-device entitlement view (one effective state per module) and the rules for how a bundle receipt grants effective per-module entitlement.

**Non-Goals:**

- Pricing decisions (numeric prices and currency tiers are commercial, not specification).
- Defining vehicle-specific licensing rules in this change (detailed triggers live in `vehicle-module` / `vehicle-sharing-module` when those modules ship).
- Cross-platform price parity rules beyond what each store enforces.
- Refund mechanics beyond what the stores expose.
- Server-side entitlement verification beyond what `subscription-entitlement-minimal-server-state` already permits.

## Decisions

### Decision: One module ⇔ one Apple subscription group ⇔ one Play subscription product

Each module (`housing`, `vehicle`, …) maps to **its own App Store subscription group** and **its own Google Play subscription product**.

Rationale:

- App Store's "one active per group" rule makes a single shared group across modules user-hostile (subscribing to vehicle would terminate housing). One group per module sidesteps this.
- On Play, the same separation keeps the store-side mapping symmetric across platforms, which simplifies receipt validation and entitlement code paths.
- Adding a future module becomes "create a new group + new product"; it does not migrate any existing subscription, which would be impossible on Apple anyway.

Alternatives considered:

- **Single subscription with feature flags per module**: rejected because Apple's group rule makes this practically equivalent to "all or nothing" or to "downgrade-from-housing-to-vehicle is destructive", and because feature flags inside one subscription scale poorly when offering selective trials per module.
- **Single subscription group on Apple with multiple products inside**: rejected for the same reason; users could not be active on housing and vehicle simultaneously.

### Decision: Bundles are a separate product, not a discount on existing per-module subscriptions

Combined offers (e.g., "Housing + Vehicle") are modeled as a **distinct subscription product** in **its own dedicated subscription group on Apple** and **its own Play subscription product**. Owning the bundle product grants effective entitlement to every module the bundle includes.

Rationale:

- Apple does not let a single subscription "live in" multiple groups. A bundle that grants two-module entitlement must therefore be a separate product on Apple.
- Google's "Subscription with add-ons" is an additive purchase flow (multiple existing products bought together) rather than a single bundle product with a fused price; for the simplest cross-platform parity, we model the bundle itself as a single subscription on both sides. Play's add-ons remain an option later, but is not the primary bundle path.
- This design supports adding a third or fourth module without re-issuing every existing bundle: a new bundle SKU is added for the desired combination.

Alternatives considered:

- **Play "Subscription with add-ons" as the cross-platform bundle**: rejected as primary because it has no clean Apple equivalent, has billing-period/region restrictions, and only auto-renewing base plans qualify.
- **Discount codes on per-module subscriptions**: rejected because cross-platform parity for codes is uneven and complicates receipt validation.

### Decision: Per-module entitlement state is evaluated independently, using housing's lifecycle as the template

Each module has its **own** instance of the state machine specified in `licensing-trial-and-plan-entitlement` (`free / linked-not-active / active-trial / active-paid / delinquent-grace / delinquent-readonly`). The events that transition the housing module are the housing-specific events already defined in that change; equivalent events for other modules are defined when those modules add their own licensing change. Until a module defines its specific lifecycle rules, **this change requires only that the machine exists per module** and that entitlement on one module never blocks another module's lifecycle.

Rationale:

- Reuses an already-reviewed lifecycle instead of inventing a parallel one.
- Keeps the door open for module-specific rules (e.g., vehicle may have different "active use" triggers than housing).
- Cleanly separates "what makes a module become active" (module-specific) from "what happens to a module once active" (shared template).

### Decision: Bundle receipt projects per-module entitlement; per-module receipts also project

The in-app entitlement layer keeps **one effective state per module**. It is computed by taking the **most favorable** active source among: a valid receipt for the module's own product, a valid receipt for any bundle that includes that module, and the user's local trial / linked-not-active state.

Rationale:

- A bundle purchaser must not be downgraded to "delinquent" on a module just because they never bought that module's standalone product.
- "Most favorable" preserves trial fairness: a user mid-trial on housing who then buys a bundle gets immediate housing entitlement without forfeiting time.
- Independent evaluation means delinquency on housing does not corrupt vehicle's state.

### Decision: Disabling a module retains data and stops sync for that module; entitlement state continues to evolve

A user-facing toggle exists per module. **Disabling** a module:

- Hides the module's UI in the shell.
- Stops outbound relay traffic associated with that module (proposals, accept/reject acknowledgements).
- Retains all on-device data for that module unchanged.
- Does **not** cancel the subscription on the store (cancellation is a store operation).
- Does **not** freeze the module's entitlement state machine, because the state machine is still driven by external events (renewal, expiration). It only freezes the module's local "active use" triggers.

Rationale:

- Users frequently confuse "disable in app" with "cancel". The product handles this gap with explicit, in-app copy and links to the store cancellation flow.
- Retaining data preserves the user's right to re-enable the module without loss.
- Keeping the state machine running on external events avoids surprises like "I disabled the app's module so I thought I would not be charged" — that path requires a store cancellation.

### Decision: Per-module export is independent of cross-module entitlement state

Export of a module's data is always available when entitlement allows export for **that** module (per the read-only-export rule in `licensing-trial-and-plan-entitlement`). It is never gated by entitlement on a different module.

Rationale:

- A user delinquent on vehicle but current on housing must still be able to export housing data and act on housing.
- Mirrors `data-locality-and-client-storage`'s position that data is owned per module and per user, not pooled.

## Risks / Trade-offs

- **Apple group layout is permanent** → choose the per-module group layout once. Mitigation: ship housing first in its own group; create vehicle's group only when vehicle ships; never reuse groups.
- **Bundle SKU proliferation as modules grow** → with N modules, there are 2^N − N − 1 possible non-trivial combinations. Mitigation: define an explicit policy (e.g., "we only sell the all-modules bundle plus per-module products") rather than every combination. The spec keeps this decision open but requires it to be documented before each module ships.
- **Trial-stacking abuse** (start a trial on each module to extend free use) → mitigation: trial start uses the same "active use" trigger semantics as housing, which already ties trial start to real activity; this is module-specific and is enforced when each module defines its own licensing change.
- **Store-side cancellation vs in-app disable confusion** → mitigation: explicit in-app copy on the disable toggle pointing to the store cancellation, plus a banner when a disabled module still has an active subscription.
- **Cross-store price perception** → bundles on Play can be implemented either as a true bundle product or via add-ons; users may compare and complain. Mitigation: documented decision that the bundle product is the canonical bundle path on both platforms.
- **Receipt projection ambiguity** ("most favorable" source) → mitigation: this design names the rule; the spec defines a deterministic evaluation order and tie-breaker so two valid sources cannot disagree on which one is effective.

## Migration Plan

This change is **additive** at the spec level and does not modify any existing capability. There is no migration of already-shipped paying users because no paying users exist yet (the housing licensing change has not been implemented at the time this design lands). When the housing licensing change is implemented, the per-module model defined here becomes its container.

When vehicle modules ship (deferred per roadmap), the steps are:

1. Author module-specific licensing changes if needed for "active use" triggers on `vehicle` and `vehicle-sharing`.
2. Provision Apple subscription groups and Google Play products for **`vehicle`** and **`vehicle-sharing`** (separate groups/products).
3. Provision bundle SKUs documented in the bundle policy (e.g., "Vehicle + Vehicle sharing", "Housing + Vehicle + Vehicle sharing").
4. Add both modules to the on-device entitlement view, enforcing `module-subscription-dependencies` for owners who share out.

## Open Questions

- Are bundle offers enabled at launch or only after the second module ships? The spec allows either; the product decides at launch time.
- Are per-module subscriptions paused/grace-mirrored across platforms (e.g., is a "Family Sharing" path planned)? Out of scope here; flagged for a future change if relevant.
- Whether a sub-launch promotional offer (Play introductory price, Apple introductory offer) is exposed per module or only on the bundle — pricing/commercial decision, not specification.
