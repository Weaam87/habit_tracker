import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'habit_tracker_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final loggedIn = prefs.getBool('logged_in') ?? false;
  final name = prefs.getString('name') ?? '';
  runApp(MyApp(loggedIn: loggedIn, username: name));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  final String username;
  const MyApp({super.key, required this.loggedIn, required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: loggedIn
          ? HabitTrackerScreen(username: username)
          : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const RegisterScreen(),
      },
    );
  }
}
