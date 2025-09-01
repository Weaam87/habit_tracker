import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _notificationsEnabled = false;
  Map<String, String> _habitsMap = {};
  Set<String> _selectedTasks = {};
  TimeOfDay? _selectedTime;
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _setup();
    _loadHabits();
  }

  Future<void> _setup() async {
    await _loadSettings();
    await _initNotifications();
    await _updateScheduledNotifications();
    setState(() {
      _settingsLoaded = true;
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(settings);

    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsStr = prefs.getString('habits');
    if (habitsStr != null) {
      setState(() {
        _habitsMap = Map<String, String>.from(jsonDecode(habitsStr));
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('notification_time');
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _selectedTasks = prefs.getStringList('notification_tasks')?.toSet() ?? {};
      if (timeStr != null) {
        final parts = timeStr.split(':');
        _selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setStringList('notification_tasks', _selectedTasks.toList());
    if (_selectedTime != null) {
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      await prefs.setString('notification_time', timeStr);
    } else {
      await prefs.remove('notification_time');
    }
  }

  Future<void> _updateScheduledNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    if (!_notificationsEnabled ||
        _selectedTime == null ||
        _selectedTasks.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'habit_channel',
      'Habit Reminders',
      channelDescription: 'Daily habit reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    final schedule = _nextInstanceOfTime(_selectedTime!);

    var id = 0;
    for (final habit in _selectedTasks) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id++,
        'Reminder',
        'Time to work on $habit',
        schedule,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  @override
  void dispose() {
    _saveSettings();
    super.dispose();
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Reminder',
      'This is a test notification',
      details,
    );
  }

  void _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      await _saveSettings();
      await _updateScheduledNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_settingsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (val) async {
                setState(() {
                  _notificationsEnabled = val;
                });
                await _saveSettings();
                await _updateScheduledNotifications();
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView(
                children: _habitsMap.keys.map((habit) {
                  return CheckboxListTile(
                    title: Text(habit),
                    value: _selectedTasks.contains(habit),
                    onChanged: (checked) async {
                      setState(() {
                        if (checked ?? false) {
                          _selectedTasks.add(habit);
                        } else {
                          _selectedTasks.remove(habit);
                        }
                      });
                      await _saveSettings();
                      await _updateScheduledNotifications();
                    },
                  );
                }).toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                _selectedTime == null
                    ? 'Pick Time'
                    : 'Time: ${_selectedTime!.format(context)}',
              ),
              onTap: _pickTime,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _notificationsEnabled ? _showTestNotification : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                child: const Text('Test Notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
