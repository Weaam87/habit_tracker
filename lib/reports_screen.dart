import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, String> _pendingHabits = {};
  Map<String, String> _completedHabits = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingStr = prefs.getString('habits');
    final completedStr = prefs.getString('completedHabits');
    setState(() {
      if (pendingStr != null) {
        _pendingHabits = Map<String, String>.from(jsonDecode(pendingStr));
      }
      if (completedStr != null) {
        _completedHabits =
            Map<String, String>.from(jsonDecode(completedStr));
      }
    });
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To Do',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _pendingHabits.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No pending habits'),
                  )
                : Expanded(
                    child: ListView(
                      children: _pendingHabits.entries.map((entry) {
                        final color = _getColorFromHex(entry.value);
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: color),
                          title: Text(entry.key),
                        );
                      }).toList(),
                    ),
                  ),
            const SizedBox(height: 16),
            const Text(
              'Completed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _completedHabits.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No completed habits'),
                  )
                : Expanded(
                    child: ListView(
                      children: _completedHabits.entries.map((entry) {
                        final color = _getColorFromHex(entry.value);
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: color),
                          title: Text(entry.key),
                          trailing: const Icon(Icons.check, color: Colors.green),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

