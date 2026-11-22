# Update Notes — Member Photos, Pledge Documents & Premium UI

## Included
- Added **অঙ্গীকারনামা** as a single entry in the Home page drawer.
- Removed the duplicate pledge entry from Advanced Features.
- Added gallery image attachment to pledge creation; the selected image is embedded into the generated PDF.
- Added a pledge-only saved-document list; existing digital receipt saved-document behavior remains unchanged.
- Added each member's `ProfilePicUrl` to the Members list and Member 360° avatar.
- Added member-photo replacement from Member 360°. The logged-in member can edit their own photo; an Admin can edit member photos.
- Reuses the existing `updateProfilePic` API endpoint already used by the app's own profile screen.
- Added Smart Search icon immediately before the home profile avatar; equal 48px control slots are used for menu/search/profile controls.
- Home profile avatar reads the logged-in member's `ProfilePicUrl` from `getAllMembers()` and refreshes after returning from the profile page.
- Removed language selectors from App Settings and Advanced Features. The only visible selector is at the bottom of the Home page and now updates `localeNotifier` plus the saved `app_language` value (`bn` / `en`).
- Applied the navy/gold premium design language across shared theme and app screens. The reference `installment_product_screen.dart` was not modified.

## Important integration notes
- Profile-photo synchronization depends on the existing backend `getAllMembers` response returning `ProfilePicUrl` and `updateProfilePic` accepting the member phone plus base64 image. The Flutter ZIP does not contain `Code.gs`, so backend behavior could not be independently verified here.
- Pledge PDFs and attached images are stored locally on the device. Server/cloud upload and cross-device sync are not implemented in this Flutter-only update.
- The language selector now changes the app-wide locale. However, many existing screens still contain hard-coded Bengali strings; complete English coverage requires a separate localization pass over those screens. This update does not claim every label is translated.
- Flutter/Dart SDK is not installed in this packaging environment. ZIP integrity and source-level checks were performed, but `flutter analyze` and an APK build must be run by GitHub Actions/Codemagic.

## Protected reference
- `lib/screens/installment_product_screen.dart` SHA-256 remains:
  `6b2d50969db8f8594767ffaf3b6180e2021bcaf13167fc7c6331e6998916e1e4`


## Update: Social Contact Links, Loss Project and Total Assets (2026-11-22)
- Added WhatsApp and Facebook Messenger link fields to Member 360°; the member can edit their own links and Admin can edit any member's links. Links open externally.
- Renamed the home module tile from “খতিয়ান” to “লস প্রজেক্ট” and added the Loss Project dashboard, records, recovery tracking, category analytics, reports, evidence attachments, and Admin-only create/edit/delete.
- Loss records and their evidence are stored locally on the current phone. Loss record metadata and social links are included in local JSON backup; attached evidence files themselves are not embedded in the JSON backup.
- Home Total Assets now adds the installment module's net expected profit (contract gross profit less installment business expenses) and subtracts Loss Project net loss (total loss less recovered amount).
- Social links are currently stored in SharedPreferences on the current phone. Cross-device member sync and shared Loss Project records require Google Apps Script / Google Sheets backend endpoints and are not enabled by this Flutter-only update.
- Added `url_launcher: ^6.3.2` dependency for opening WhatsApp and Messenger links.
