# Loading and cache update notes

- Main tab pages are now kept alive with IndexedStack, so switching tabs does not dispose and recreate them.
- Removed unconditional Dashboard fetches on every visit and after opening a list page.
- API GET responses are cached in memory and duplicate in-flight GETs are shared.
- Successful API POST operations invalidate cached GET data.
- Dashboard pull-to-refresh explicitly clears cache and fetches fresh data.

Limitations: cache is in-memory for the current app process only. Updates made by another device/user are not automatically detected; use pull-to-refresh to fetch them. Flutter/Dart SDK was not available in the editing environment, so a release build could not be run here.
