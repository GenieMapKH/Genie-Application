# Incoming calls and listing calls

Deploy the notification-service change before installing the updated Android
app. Incoming and ended Android call pushes must be **high-priority data-only**
messages. An FCM notification payload is displayed by Android itself and can
defer the background handler until the notification is tapped. Chat, iOS, and
web alert payloads keep their existing behavior.

The existing authenticated chat signaling and WebRTC audio remain in use. Both
socket invitations and background FCM invitations produce a ringing Android
notification, with Accept and Decline. Accept opens the app and joins the call;
the background notification's Decline silences this device, while the in-app
Decline tells the server. Ended pushes and socket events stop ringing. Incoming
screens also time out if the connection disappears. Delayed pushes do not get
another full ring duration.

In Notifications settings, tap **Full-screen incoming calls** and allow access
on Android 14+. Notifications and the Calls notification channel must also be
enabled. Android chooses the presentation: a locked phone can show the call
full screen; an unlocked phone normally shows a call banner. The app enables
lock-screen visibility only for the call screen, and asks for device unlock
before minimizing it to browse other app screens.

Swiping the app from Recents can still allow FCM to start its background
handler. Force-stopping it in Android Settings blocks delivery until it is
opened again. Manufacturer battery restrictions can also prevent delivery;
the app cannot guarantee waking on every phone.

**Call Now** on a listing asks every time: **Call in Tilomnov** calls the listing
owner's account; **Use phone dialer** opens the listing's contact number, falling
back to the owner's phone number. These may reach different people if the
listing has a separate contact number. Dismissing the chooser does nothing.
The existing sign-in requirement applies to both choices.

## iPhone

The chooser and incoming-call timeout improvements also apply to iOS. Existing
CallKit support only runs once Flutter receives the call. Reliable background
and terminated-app incoming calls still require a separate PushKit flow:

1. Register and refresh the native VoIP token, associated with the signed-in
   session; remove it on sign-out/revocation.
2. Deliver incoming calls directly through APNs with the VoIP topic and Apple's
   signing credentials; an FCM registration token is not a VoIP token.
3. Report the incoming call to CallKit immediately in native code, then hand
   its state and queued Answer/End actions to Flutter after startup.
4. Handle cancellation, expiration and answering on another device, including
   when Flutter has not started. Verify with a signed build on an iPhone.

That PushKit/APNs implementation is not part of this Android fix.

## Device checks before release

Use the staging app with two signed-in accounts. No device was connected during
implementation, so these checks remain required:

- Foreground, background while unlocked, screen locked, and app removed from
  Recents: call, answer, hear audio both ways, hang up, and confirm ringing stops.
- Reject from the in-app screen and silence from the notification; check the
  caller's result and that a subsequent call rings normally.
- Cancel before answering, and answer on another device; check the original
  device's notification and screen disappear without waiting for app reopening.
- Disable full-screen access: confirm the actionable notification still works.
  Enable it from the new settings row and repeat the locked-screen call.
- While a call is above a secure lock screen, cancel the unlock prompt when
  minimizing: other app screens must remain inaccessible. Then unlock and retry.
- Stop the network during ringing: verify the screen and ringtone expire.
- In Call Now, test both choices, dismissal, missing phone, missing owner, and
  guest sign-in. An in-app call must work even if no phone number is published.

References: [FCM message delivery](https://firebase.google.com/docs/cloud-messaging/android/receive),
[Android urgent notifications](https://developer.android.com/develop/ui/compose/notifications/create-notification),
[Android full-screen access](https://source.android.com/docs/core/permissions/fsi-limits),
[Apple VoIP pushes](https://developer.apple.com/documentation/pushkit/responding-to-voip-notifications-from-pushkit).
