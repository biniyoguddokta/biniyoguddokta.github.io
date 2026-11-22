
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'audit_log_service.dart';

class ReminderItem {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String repeat;
  final bool enabled;

  const ReminderItem({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.repeat = 'none',
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduledAt': scheduledAt.toIso8601String(),
        'repeat': repeat,
        'enabled': enabled,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) =>
      ReminderItem(
        id: json['id'].toString(),
        title: json['title']?.toString() ?? 'Reminder',
        body: json['body']?.toString() ?? '',
        scheduledAt:
            DateTime.parse(json['scheduledAt'].toString()),
        repeat: ['none', 'daily', 'weekly'].contains(json['repeat'])
            ? json['repeat']
            : 'none',
        enabled: json['enabled'] != false,
      );

  ReminderItem copyWith({
    String? title,
    String? body,
    DateTime? scheduledAt,
    String? repeat,
    bool? enabled,
  }) {
    return ReminderItem(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
    );
  }
}

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const _storageKey = 'somiti_local_reminders_v1';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    try {
      final String zone =
          await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(zone));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      debugPrint('Timezone fallback to Asia/Dhaka: $e');
    }

    const android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwin = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;

    await restoreScheduledReminders();
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
      'Reminder opened: ${response.payload ?? ''}',
    );
  }

  Future<bool> requestPermission() async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted =
        await android?.requestNotificationsPermission();

    return granted ?? true;
  }

  Future<bool> areNotificationsEnabled() async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<List<ReminderItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map(
            (e) => ReminderItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList()
        ..sort(
          (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
        );
    } catch (e) {
      debugPrint('Reminder data could not be decoded: $e');
      return [];
    }
  }

  Future<void> _save(List<ReminderItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  int _notificationId(String id) =>
      id.hashCode & 0x7fffffff;

  Future<void> save(ReminderItem item) async {
    await initialize();

    final items = await getAll();

    final index = items.indexWhere((e) => e.id == item.id);

    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }

    await _save(items);

    await _plugin.cancel(_notificationId(item.id));

    if (item.enabled) {
      await _schedule(item);
    }

    await AuditLogService.record(
      action: 'Reminder saved',
      details: item.title,
    );
  }

  Future<void> delete(String id) async {
    await initialize();

    final items = await getAll();

    items.removeWhere((e) => e.id == id);

    await _save(items);

    await _plugin.cancel(_notificationId(id));

    await AuditLogService.record(
      action: 'Reminder deleted',
      details: 'Reminder ID: $id',
    );
  }

  Future<void> setEnabled(
    ReminderItem item,
    bool enabled,
  ) async {
    await save(item.copyWith(enabled: enabled));
  }

  Future<void> restoreScheduledReminders() async {
    final items = await getAll();

    for (final item in items) {
      await _plugin.cancel(_notificationId(item.id));

      if (item.enabled) {
        try {
          await _schedule(item);
        } catch (e) {
          debugPrint(
            'Reminder restore failed (${item.id}): $e',
          );
        }
      }
    }
  }

  Future<void> _schedule(ReminderItem item) async {
    var when = tz.TZDateTime.from(
      item.scheduledAt,
      tz.local,
    );

    final now = tz.TZDateTime.now(tz.local);

    if (item.repeat == 'none' && !when.isAfter(now)) {
      throw StateError(
        'এই সময়টি পেরিয়ে গেছে। ভবিষ্যতের সময় নির্বাচন করুন।',
      );
    }

    if (item.repeat == 'daily' ||
        item.repeat == 'weekly') {
      while (!when.isAfter(now)) {
        when = when.add(
          item.repeat == 'daily'
              ? const Duration(days: 1)
              : const Duration(days: 7),
        );
      }
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'somiti_reminders_v1',
        'সমিতির রিমাইন্ডার',
        channelDescription:
            'জমা, কিস্তি, মিটিং ও ব্যক্তিগত অনুস্মারক',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _notificationId(item.id),
      item.title,
      item.body,
      when,
      details,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: item.repeat == 'daily'
          ? DateTimeComponents.time
          : item.repeat == 'weekly'
              ? DateTimeComponents.dayOfWeekAndTime
              : null,
      payload: item.id,
    );
  }

  Future<void> showTestNotification() async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'somiti_reminders_v1',
        'সমিতির রিমাইন্ডার',
        channelDescription:
            'জমা, কিস্তি, মিটিং ও ব্যক্তিগত অনুস্মারক',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      2147483000,
      'বিনিয়োগ উদ্যোক্তা',
      'নোটিফিকেশন পরীক্ষা সফল হয়েছে।',
      details,
    );
  }
}
