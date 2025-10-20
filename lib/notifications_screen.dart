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
  bool _isScheduling = false;
  int _scheduledCount = 0;

  @override
  void initState() {
    super.initState();
    _setup();
    _loadHabits();
  }

  Future<void> _setup() async {
    await _loadSettings();
    await _initNotifications();
    final scheduled = await _updateScheduledNotifications();
    setState(() {
      _settingsLoaded = true;
      _scheduledCount = scheduled;
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
    if (androidPlugin != null) {
      const habitChannel = AndroidNotificationChannel(
        'habit_channel',
        'Habit Reminders',
        description: 'Daily habit reminder notifications',
        importance: Importance.high,
      );
      const testChannel = AndroidNotificationChannel(
        'test_channel',
        'Test Notifications',
        description: 'One-off test notifications from the settings screen',
        importance: Importance.high,
      );
      await androidPlugin.createNotificationChannel(habitChannel);
      await androidPlugin.createNotificationChannel(testChannel);
      final notificationsEnabled =
          await androidPlugin.areNotificationsEnabled() ?? true;
      if (!notificationsEnabled) {
        await androidPlugin.requestNotificationsPermission();
      }
      final canScheduleExact =
          await androidPlugin.canScheduleExactAlarms() ?? true;
      if (!canScheduleExact) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    }

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

  Future<int> _updateScheduledNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    if (!_notificationsEnabled ||
        _selectedTime == null ||
        _selectedTasks.isEmpty) {
      return 0;
    }

    const androidDetails = AndroidNotificationDetails(
      'habit_channel',
      'Habit Reminders',
      channelDescription: 'Daily habit reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    final schedule = _nextInstanceOfTime(_selectedTime!);

    var scheduled = 0;
    for (final habit in _selectedTasks) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _notificationIdForHabit(habit),
        'Reminder',
        'Time to work on $habit',
        schedule,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: habit,
      );
      scheduled++;
    }
    return scheduled;
  }

  @override
  void dispose() {
    _saveSettings();
    super.dispose();
  }

  int _notificationIdForHabit(String habit) {
    return habit.hashCode & 0x7fffffff;
  }

  Future<bool> _ensureAndroidPermissions() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return true;
    }
    final notificationsEnabled =
        await androidPlugin.areNotificationsEnabled() ?? true;
    bool granted = notificationsEnabled;
    if (!notificationsEnabled) {
      granted = await androidPlugin.requestNotificationsPermission() ?? false;
    }
    if (!granted) {
      return false;
    }
    final canScheduleExact =
        await androidPlugin.canScheduleExactAlarms() ?? true;
    if (!canScheduleExact) {
      final requested =
          await androidPlugin.requestExactAlarmsPermission() ?? false;
      if (!requested) {
        return false;
      }
    }
    return true;
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
        _scheduledCount = 0;
      });
      await _saveSettings();
    }
  }

  Future<void> _scheduleNotifications() async {
    if (_isScheduling) return;
    setState(() {
      _isScheduling = true;
    });
    try {
      await _saveSettings();
      if (!_notificationsEnabled ||
          _selectedTime == null ||
          _selectedTasks.isEmpty) {
        await _flutterLocalNotificationsPlugin.cancelAll();
        if (!mounted) return;
        setState(() {
          _scheduledCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Select at least one task and a time while notifications are enabled.',
            ),
          ),
        );
        return;
      }
      final permissionsGranted = await _ensureAndroidPermissions();
      if (!permissionsGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enable notifications and alarm permissions in system settings to schedule reminders.',
            ),
          ),
        );
        return;
      }
      final scheduled = await _updateScheduledNotifications();
      if (!mounted) return;
      setState(() {
        _scheduledCount = scheduled;
      });
      final formattedTime = _selectedTime!.format(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scheduled $scheduled reminder${scheduled == 1 ? '' : 's'} for $formattedTime',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule notifications: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScheduling = false;
        });
      }
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
                  if (!val) {
                    _scheduledCount = 0;
                  }
                });
                await _saveSettings();
                if (!val) {
                  await _flutterLocalNotificationsPlugin.cancelAll();
                }
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
                        _scheduledCount = 0;
                      });
                      await _saveSettings();
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
            if (_scheduledCount > 0 &&
                _notificationsEnabled &&
                _selectedTime != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Currently scheduled $_scheduledCount reminder${_scheduledCount == 1 ? '' : 's'} for ${_selectedTime!.format(context)}.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _notificationsEnabled &&
                        _selectedTime != null &&
                        _selectedTasks.isNotEmpty &&
                        !_isScheduling
                    ? _scheduleNotifications
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                child: _isScheduling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Set Notification'),
              ),
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
