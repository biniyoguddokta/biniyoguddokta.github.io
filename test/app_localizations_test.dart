import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somiti_app/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('provides Bengali labels', () {
      const l = AppLocalizations(Locale('bn'));
      expect(l.home, 'হোম');
      expect(l.members, 'সদস্য');
      expect(l.appSettings, 'অ্যাপ সেটিংস');
    });

    test('provides English labels', () {
      const l = AppLocalizations(Locale('en'));
      expect(l.home, 'Home');
      expect(l.members, 'Members');
      expect(l.appSettings, 'App settings');
    });
  });
}
