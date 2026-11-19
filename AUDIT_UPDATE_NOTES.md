# UI and performance update

Changes in this package:
- Replaced the Home dashboard banner carousel and scrolling notice strip with a compact Recent Investments panel.
- The Recent Investments panel loads the latest three investment records from the existing `getInvestments` API and opens the existing Investment screen through “সব দেখুন”.
- Connected the previously empty “ফান্ড” dashboard module to the existing `InvestmentScreen`.
- Dashboard requests for transactions, members, and investments are started concurrently.
- Removed the fixed two-second wait from the splash/login routing flow.

Preservation notes:
- Existing investment screen, add-investment flow, notice screen/module, transaction flows, and other screens were retained.
- No Google Apps Script or Google Sheet backend files were included in the supplied project ZIP. Backend changes and verification of live API behavior were therefore not possible.
- The separate “মাসিক কিস্তি আদায়-html.zip” is a standalone design mockup for monthly installment collection, not a native Flutter investment page, so it was not embedded into the Flutter app.
- Flutter build/test could not be run in this environment. Please run the existing GitHub Actions workflow after merging.
