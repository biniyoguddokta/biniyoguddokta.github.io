# Batch 6 — Notifications & Automation (Local Reminder Foundation)

## Included cumulative source
This ZIP is cumulative from Batch 5 and retains Batch 1–5 source, permanent Android folder, PDF/pledge documents, search and reports.

## Implemented locally
- Flutter local notification scheduling with a dedicated notification channel.
- Permission request flow for Android 13+ and a test notification action.
- Create, edit, enable/disable and delete reminders.
- One-time, daily and weekly reminders.
- Persistent reminder definitions in SharedPreferences.
- Timezone initialization from the device timezone; Asia/Dhaka fallback if timezone lookup fails.
- Inexact allow-while-idle scheduling to avoid demanding exact-alarm special access.
- Android notification and reboot/package-replacement receivers.
- Startup initialization is isolated in try/catch so notification errors do not block app startup.
- Reminder IDs map to stable notification IDs; editing cancels the previous scheduled instance before scheduling the replacement.

## Important platform limitations
- Android battery optimization / vendor background restrictions can delay notifications.
- The app does not silently request exact-alarm access or disable battery optimization.
- If notification permission is denied or notifications are disabled in system settings, scheduled notifications may not appear.
- Android reboot receiver reschedules plugin-managed alarms; the app also restores saved reminders at startup.
- Weekly reminders repeat on the weekday selected in the original scheduled date.
- Reminder tapping currently opens the app through the OS notification flow; feature-specific deep-link navigation is not yet wired.

## Backend / future integration
- FCM push delivery, server-side due-date detection, automated member-specific installment reminders, delivery receipts, and admin-managed notification campaigns require backend/FCM configuration.
- Existing local reminders are device-local and are not synced to other phones.

## Build validation
The permanent Android folder is included. CI does not run `flutter create .`.
Run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --release` in GitHub Actions. This packaging environment did not have Flutter SDK, so no successful APK build is claimed.
