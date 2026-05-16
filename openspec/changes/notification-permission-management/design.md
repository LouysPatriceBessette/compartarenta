## Context

The app now initializes push notification support during bootstrap, which can request browser or platform permission during the first app load. This happens before onboarding is complete and before the user has a concrete reason to allow notifications. The desired model is explicit: permissions are requested from meaningful flows, such as inviting a contact or inviting plan participants, and remain manageable from Settings.

The permission model has multiple layers:

- Platform/system notification permission: browser, Android, iOS.
- App-level master switch and notification categories: Contacts and Housing event types.
- Notification sound preference: global enablement first; built-in app sound selection can be considered later, but arbitrary device sound selection is not portable across Android and iOS.

This change must keep the app lightweight and extensible. More notification entry points and categories are expected.

## Goals / Non-Goals

**Goals:**

- Delay notification permission prompts until after initial setup and after a user action that benefits from notifications.
- Provide a reusable permission prompt boundary that can be invoked from multiple flows.
- Add Settings navigation for Notifications, Units, and About so users can manage notification preferences outside a specific flow.
- Keep the app-level master notification switch off by default and make turning it on request system permission.
- Detect stale app-level notification enablement when the Notifications settings page loads and the system permission has been revoked outside the app.
- Define initial notification categories for Contacts and Housing.
- Provide a developer-only test notification path that validates effective notification delivery without depending on FCM or peer events.
- Preserve the product rule that peer-triggered events generally get notifications while local-only actions do not.

**Non-Goals:**

- Implement server-side push delivery, FCM token persistence, or relay payload dispatch in this change.
- Implement final custom notification sound picking if it requires additional platform permissions or native integration.
- Decide every future notification category up front.
- Change relay protocol or relay binary behavior.

## Decisions

1. Use Settings as the durable management surface.

Users can change notification settings at any time without entering an invitation or proposal flow. The main Settings page groups notification preferences under a dedicated Notifications page, while Units and About move existing settings into clearer subpages.

Alternative considered: only ask inline in flows. That would satisfy first-use prompts but would not provide ongoing management.

2. Use a reusable flow gate for permission prompts.

Invitation flows should call a shared notification permission gate after the user clicks an intent-bearing button. The gate checks platform permission and app-level preferences, requests system permission only when needed, and then returns to the original flow.

Alternative considered: each flow directly calls Firebase/browser permission APIs. That would duplicate behavior and make future categories inconsistent.

3. Keep category preferences app-level and stored locally first.

The initial category switches can be local app preferences. Backend delivery can later use those preferences if/when token registration and server push dispatch are introduced.

Alternative considered: server-authoritative category preferences from day one. That would add backend scope before the UX and permission semantics are validated.

4. Make the app-level master switch explicit and conservative.

The master notification switch is an app preference, not the platform permission itself. On fresh installs it defaults to off, so the app does not behave as opted in before the user has made an explicit choice.

When the user turns the switch on, the app requests system notification permission if needed. If the platform grants or provisionally grants permission, the app-level switch remains on and notification infrastructure can initialize. If the platform denies or cannot grant permission, the app-level switch remains off and the UI explains that system permission is missing.

When the user turns the switch off, the app only disables its own notification preference. It does not attempt to revoke browser, Android, or iOS permission because those permissions belong to the system/browser settings surface.

When the Notifications settings page opens and the app-level switch is already on, the app verifies that system permission is still valid. If the user revoked system permission outside the app, the app-level switch is reconciled back to off. The page does not perform this system permission check when the app-level switch is already off, avoiding unnecessary platform queries and keeping the initial off state quiet.

Alternative considered: treat the app-level switch as purely local and never request system permission from it. That made the UI confusing because users could turn notifications on while the platform still blocked delivery.

5. Provide a developer-only test notification action.

Developer builds expose a `Send test notification` action under Developer tools. The action sends title/body `TEST` through the platform's effective local-notification path:

- Web uses the browser `Notification` API directly.
- Android/iOS use local notifications.

The action reports whether delivery was blocked by the app-level switch, by system permission, by platform support, or by an unexpected failure. This helps verify permission semantics without waiting for peer-triggered traffic or FCM delivery.

Alternative considered: rely only on real peer events. That slows debugging and conflates permission state with transport or event-delivery issues.

6. Treat sound as default/silent first, not as an arbitrary device sound picker.

A sound enabled/disabled switch is straightforward. Full device sound selection is not a safe cross-platform baseline:

- Android 8+ sound is channel behavior. It can be set with `NotificationChannel.setSound(Uri, AudioAttributes)` before the channel is registered, but channel behavior cannot be changed programmatically after `createNotificationChannel`; the user controls it in system settings. The sound URI must be stable for the lifetime of the install/backup restore.
- iOS requires notification sounds to already be local to the device and discoverable by the app: bundled in the app, stored in the app container `Library/Sounds`, or supplied by a notification service extension. Apple supports limited formats (`aiff`, `wav`, `caf` containing Linear PCM, IMA4/MA4, uLaw, or aLaw) and files under 30 seconds; otherwise the default sound plays.
- Browser notification sound is not a reliable standard notification feature; web apps should treat sound as unavailable unless they play in-app audio while foregrounded.

The portable product model is:

1. `Sound on/off` controls whether the app asks notification APIs to include a sound.
2. `Default sound` is the only cross-platform default choice.
3. `App-provided sounds` may be added later as a finite bundled set, with Android channel versioning.
4. `Use a sound from this device` is out of scope until a platform-specific design proves it can work without surprising media permissions or brittle URI handling.

Alternative considered: implement a full sound picker now. That adds platform complexity and may conflict with notification channel immutability.

## Risks / Trade-offs

- Delayed permission prompts may reduce early opt-in rate -> prompt at high-intent moments and explain the benefit clearly.
- App-level switches cannot guarantee server-side suppression until backend delivery exists -> keep UI wording scoped to app preferences and wire server behavior in a later task.
- Android notification channel sound changes can be sticky once a channel exists -> version channels when sound behavior changes.
- iOS custom sounds must be bundled or stored in the app container before notification delivery -> do not promise selection from arbitrary user media in the shared UI.
- Web, Android, and iOS permission states differ -> expose a normalized status in UI while still allowing platform-specific copy where needed.
