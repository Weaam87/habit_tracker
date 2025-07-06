import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'country_list.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedCountry = countryList.first;

  final Map<String, bool> _habitToggles = {
    'Exercise': false,
    'Read': false,
    'Meditate': false,
    'Study': false,
    'Sleep Early': false,
  };

  final Map<String, String> _habitColors = {
    'Exercise': 'FF5733',
    'Read': '33FF57',
    'Meditate': '3357FF',
    'Study': 'FF33A1',
    'Sleep Early': 'FFC300',
  };

  bool validateForm() {
    return usernameController.text.isNotEmpty &&
        nameController.text.isNotEmpty &&
        ageController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  Future<void> saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', usernameController.text);
    await prefs.setString('name', nameController.text);
    await prefs.setString('age', ageController.text);
    await prefs.setString('country', selectedCountry);
    await prefs.setString('email', emailController.text);
    await prefs.setString('password', passwordController.text);

    Map<String, String> selectedHabits = {};
    _habitToggles.forEach((habit, selected) {
      if (selected) {
        selectedHabits[habit] = _habitColors[habit]!;
      }
    });
    await prefs.setString('habits', jsonEncode(selectedHabits));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: selectedCountry,
                decoration: InputDecoration(labelText: 'Country'),
                items: countryList
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCountry = val!;
                  });
                },
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select Habits'),
              ),
              Column(
                children: _habitToggles.keys.map((habit) {
                  return SwitchListTile(
                    title: Text(habit),
                    value: _habitToggles[habit]!,
                    onChanged: (val) {
                      setState(() {
                        _habitToggles[habit] = val;
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (validateForm()) {
                  await saveUserData();
                  Navigator.pushNamed(context, '/login');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All fields are required')),
                  );
                }
              },
              child: Text('Sign Up'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  );
  }
}
