import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import 'advanced_features_screen.dart';
import '../l10n/app_localizations.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});
  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() { _notificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _setTheme(bool enabled) async {
    themeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', enabled);
  }

  Future<void> _setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', enabled);
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enabled ? l.notificationOn : l.notificationOff)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.appSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _sectionTitle(l.appearance),
          Card(child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) => SwitchListTile.adaptive(
              secondary: _leadingIcon(Icons.dark_mode_outlined),
              title: Text(l.darkMode, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l.darkModeSubtitle),
              value: mode == ThemeMode.dark,
              onChanged: _setTheme,
            ),
          )),
          const SizedBox(height: 18),
          _sectionTitle(l.notifications),
          Card(child: Column(children: [
            SwitchListTile.adaptive(
              secondary: _leadingIcon(Icons.notifications_active_outlined),
              title: Text(l.notificationPreference, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l.notificationSubtitle),
              value: _notificationsEnabled,
              onChanged: _loading ? null : _setNotifications,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: _leadingIcon(Icons.alarm_outlined),
              title: Text(l.reminderManagement, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l.reminderSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderPreferencesScreen())),
            ),
          ])),
          const SizedBox(height: 18),
          _sectionTitle(l.appInformation),
          Card(child: ListTile(
            leading: _leadingIcon(Icons.info_outline),
            title: Text(l.appName),
            subtitle: Text(l.appDescription),
            trailing: const Text('v1.0.0'),
          )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
  );

  Widget _leadingIcon(IconData icon) => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.10), borderRadius: BorderRadius.circular(13)),
    child: Icon(icon, color: Theme.of(context).colorScheme.primary),
  );
}
