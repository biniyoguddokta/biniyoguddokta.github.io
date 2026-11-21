# Batch 5 — Advanced Reports & Smart Search

## Included cumulative source
This archive is based on Batch 4 and retains Batch 1–4 source, PDF/pledge document features, and the permanent Android project.

## Batch 5 additions
- Smart Search now loads member, transaction, and investment records from existing API actions.
- Search across returned fields, filter by record type, and apply a date range where record dates are available.
- Advanced financial report date-range and payment-status filters.
- Totals for deposits, income, expenses, and dues based on the filtered transaction records.
- CSV export with UTF-8 BOM for Bengali/Excel compatibility, shared as a `.csv` file.
- PDF report generation through the existing local PDF document service.
- Refresh controls and empty/error states.
- Existing Report screen's detail action now opens the live advanced report instead of doing nothing.

## Backend-dependent / not claimed as complete
- Server-side search indexing, pagination, and date-filter endpoints.
- Role/permission enforcement and server-authoritative financial aggregation.
- Audit-signed/immutable reports and verified official financial statements.
- Excel `.xlsx` workbook generation (CSV is Excel-compatible but is not an XLSX file).

## Build
Permanent `android/` folder is included. `.github/workflows/build.yml` verifies Android files and does not run `flutter create .`.

Run `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter build apk --release` in CI. Flutter SDK was not available in the packaging environment, so a successful APK build is not claimed.
