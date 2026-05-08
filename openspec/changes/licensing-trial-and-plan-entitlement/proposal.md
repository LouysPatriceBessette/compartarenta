## Why

The product is free and unlimited until a shared expense plan is **actively in use**. Once a plan is in active use, a 6-week trial begins, followed by individual paid licenses per participant. The rules around trial start, payment responsibility, delinquency, and dispute handling must be specified so implementation, UX, and public “privacy-first” claims stay aligned.

## What Changes

- Define when the app is free/unlimited vs when a plan enters “active use”.
- Define the 6-week trial behavior and notification schedule.
- Define license model: individual licenses, plan-level requirement that **all participants** are licensed, and plan-aligned monthly renewal date.
- Define delinquency behavior: grace period notifications, read-only mode, and data export availability in read-only mode.
- Define “forced participant removal due to non-payment” behavior, including a plan diff artifact suitable for reference in disputes, and the product’s explicit limits (not legal advice).

## Capabilities

### New Capabilities

- `free-until-active-plan-use`: Rules that govern free usage and the trigger for trial start.
- `trial-notifications-and-timeline`: Trial length, notification schedule, and required UX.
- `per-participant-licenses-and-plan-renewal`: Individual license requirement, collective responsibility, and shared renewal date.
- `delinquency-grace-readonly-and-export`: Non-payment flows, grace period, read-only mode, and always-available export in read-only mode.
- `plan-change-on-participant-removal-and-diff`: Required plan modifications and differential impact reporting when removing a participant due to payment failure.
- `legal-disclosures-and-product-limits`: Documentation requirements for legal-related behavior and explicit product scope.

### Modified Capabilities

- None.

## Impact

- Introduces plan-level entitlement logic distinct from subscription receipt validation.
- Requires local state machine for plan lifecycle and trial timeline.
- Requires messaging/notification UX and (optionally) OS-level notification permissions and scheduling.
- Requires well-defined export behavior when features are gated.

