import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/signup',
      routes: {
        '/signup': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
