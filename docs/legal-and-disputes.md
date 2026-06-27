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

If one participant’s unpaid license blocks the group while at least two other licenses remain active, the app supports the group by:

- guiding users to propose a modified plan for the remaining participants, and
- producing a **differential impact report** showing how obligations change between the prior plan and the proposed replacement plan.

## Limits

The application does not:

- adjudicate disputes between participants,
- determine fault or liability,
- enforce collection or penalties beyond what is represented in the agreed plan/contract data model.

