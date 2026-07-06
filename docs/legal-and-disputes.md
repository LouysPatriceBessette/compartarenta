## Legal and disputes (product behavior)

This document describes what the application does and does not do in legal-adjacent situations. It is provided for transparency and product understanding only.

## Not legal advice

The application and its maintainers do not provide legal advice. You are responsible for your agreements with other participants.

## Licensing and payment failure behavior

- **Free until active plan use**: the app remains free and unlimited until a plan is actively in use (see OpenSpec change `licensing-trial-and-plan-entitlement`).
- **Trial**: once a plan becomes actively used, a 2-week trial begins with reminders (1 week remaining, then daily for the last 3 days).
- **Individual licenses**: each participant must have a valid license for the plan to operate fully.
- **Grace period**: if a required license becomes unpaid, the plan enters a 1-week grace period with daily notifications to all participants.
- **Read-only mode**: after grace expiry, the plan is restricted to viewing past data only.
- **Export**: export remains available in read-only mode so participants can always retrieve their history.

## Participant removal due to non-payment

When a required license is unpaid, the app applies grace-period notifications, then read-only mode, while export remains available (see `delinquency-grace-readonly-and-export` in OpenSpec).

If one participant’s unpaid license blocks the group while at least two other licenses remain active, the app guides the group to **adapt the plan** for the remaining participants (ratio redistribution, inactive participant for ledger settlement) via a modified plan proposal subject to unanimous acceptance.

**Future release (planned):** a **differential impact report** showing how projected obligations change between the prior plan and the proposed replacement plan. Tracked in `dev-ideas/2026-06-27-wish-list.md` § 3.

## Voluntary withdrawal and ejection

Plan adaptation on departure (ratio redistribution, early-withdrawal penalty when due, inactive participant) is in scope for the initial release via `housing-participation-change-major-flow`. A formal before/after differential impact report is planned for a future release (same wish list § 3).

## Limits

The application does not:

- adjudicate disputes between participants,
- determine fault or liability,
- enforce collection or penalties beyond what is represented in the agreed plan/contract data model.

