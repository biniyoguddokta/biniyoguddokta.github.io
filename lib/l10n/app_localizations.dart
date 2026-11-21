import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static const supportedLocales = [Locale('bn'), Locale('en')];
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  bool get isEnglish => locale.languageCode == 'en';
  String get home => isEnglish ? 'Home' : 'হোম';
  String get members => isEnglish ? 'Members' : 'সদস্য';
  String get collection => isEnglish ? 'Collection' : 'কালেকশন';
  String get reports => isEnglish ? 'Reports' : 'রিপোর্ট';
  String get more => isEnglish ? 'More' : 'আরও';
  String get appSettings => isEnglish ? 'App settings' : 'অ্যাপ সেটিংস';
  String get appearance => isEnglish ? 'Appearance' : 'দেখার পছন্দ';
  String get darkMode => isEnglish ? 'Dark mode' : 'ডার্ক মোড';
  String get darkModeSubtitle => isEnglish ? 'Switch between light and dark theme' : 'অ্যাপের আলো ও অন্ধকার থিম পরিবর্তন করুন';
  String get notifications => isEnglish ? 'Notifications' : 'নোটিফিকেশন';
  String get notificationPreference => isEnglish ? 'Notification preference' : 'নোটিফিকেশন পছন্দ';
  String get reminderManagement => isEnglish ? 'Manage reminders' : 'রিমাইন্ডার পরিচালনা';
  String get languageRegion => isEnglish ? 'Language & region' : 'ভাষা ও অঞ্চল';
  String get language => isEnglish ? 'Language' : 'ভাষা';
  String get bengali => isEnglish ? 'Bengali' : 'বাংলা';
  String get english => isEnglish ? 'English' : 'ইংরেজি';
  String get appInformation => isEnglish ? 'App information' : 'অ্যাপের তথ্য';
  String get notificationSubtitle => isEnglish ? 'Save your notification preference' : 'অ্যাপের নোটিফিকেশন পছন্দ সংরক্ষণ করুন';
  String get reminderSubtitle => isEnglish ? 'One-time, daily and weekly reminders' : 'এককালীন, দৈনিক ও সাপ্তাহিক রিমাইন্ডার';
  String get appDescription => isEnglish ? 'Cooperative management and accounts' : 'সমিতির ব্যবস্থাপনা ও হিসাব';
  String get notificationOn => isEnglish ? 'Notification preference enabled' : 'নোটিফিকেশন পছন্দ চালু হয়েছে';
  String get notificationOff => isEnglish ? 'Notification preference disabled' : 'নোটিফিকেশন পছন্দ বন্ধ হয়েছে';
  String get appName => isEnglish ? 'Investment Entrepreneur' : 'বিনিয়োগ উদ্যোক্তা';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['bn', 'en'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(AppLocalizations(locale));
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
