# Batch 8 — Premium UI & Localization

## Included
- Material 3-based shared light/dark theme tokens and component styling.
- Consistent card, input, button, AppBar, divider and SnackBar presentation.
- Refined five-destination Material 3 NavigationBar; tab pages remain in IndexedStack.
- Persisted light/dark mode and persisted Bengali/English language selection.
- Localization delegate and bilingual strings for the primary bottom navigation and App Settings screen.
- Settings screen reorganized into appearance, notifications, language/region and app information sections.
- Permanent Android project and GitHub Actions workflow retained from Batch 7.

## Localization coverage — important
The Bengali/English selector is functional for the primary navigation and App Settings screen. Many legacy screens still contain hard-coded Bengali text and are not fully translated in this batch. Batch 9 integration should complete the remaining screen-by-screen localization before describing the entire app as fully bilingual.

## Preserved features
This is cumulative from Batch 7 and retains the existing member, collection, transaction, investment, installment product, reports, reminders, local backup/restore, audit log, Firebase bootstrap and existing API integration code. No Apps Script backend or Firestore security policy was changed.

## Validation
- Source archive integrity and required-file presence checked.
- Flutter SDK was not available in the packaging environment; `flutter pub get`, `flutter analyze`, tests and APK build were not executed.
- Run the existing GitHub Actions workflow before installing the APK. If it fails, provide the complete first-error section of the build log for correction.
