import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/firebase_bootstrap.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional services must never prevent the core app from opening.
  try { await ReminderService.instance.initialize(); } catch (e) { debugPrint('Reminder initialization skipped: $e'); }
  try { await FirebaseBootstrap.initialize(); } catch (e) { debugPrint('Firebase initialization skipped: $e'); }
  try {
    final prefs = await SharedPreferences.getInstance();
    themeNotifier.value = (prefs.getBool('isDarkMode') ?? false) ? ThemeMode.dark : ThemeMode.light;
    localeNotifier.value = Locale(prefs.getString('app_language') == 'en' ? 'en' : 'bn');
  } catch (e) { debugPrint('Preferences initialization skipped: $e'); }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) => ValueListenableBuilder<Locale>(
        valueListenable: localeNotifier,
        builder: (context, locale, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'বিনিয়োগ উদ্যোক্তা',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); _checkLoginStatus(); }

  Future<void> _checkLoginStatus() async {
    bool loggedIn = false;
    try { loggedIn = (await SharedPreferences.getInstance()).getBool('isLoggedIn') ?? false; } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
