import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'habit_tracker_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupFakeUser();
  }

  Future<void> _setupFakeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('email')) {
      await prefs.setString('username', 'demo');
      await prefs.setString('name', 'Demo User');
      await prefs.setString('email', 'demo@example.com');
      await prefs.setString('password', 'password');
    }
  }

  bool validateForm() {
    return emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  Future<bool> authenticateUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');

    if (emailController.text == savedEmail &&
        passwordController.text == savedPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Successful')),
      );
      return true; // ✅ return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials')),
      );
      return false; // ❌ invalid login
    }
  }

  void handleLogin() async {
    if (validateForm()) {
      bool success = await authenticateUser();
      if (success) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? name = prefs.getString('name');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitTrackerScreen(username: name ?? ''),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Enter your email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Enter your password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleLogin,
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
