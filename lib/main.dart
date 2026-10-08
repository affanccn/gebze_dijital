import 'package:flutter/material.dart';
import 'screens/guest_home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gebze Dijital',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0B5FA5)),
      home: const GuestHomeScreen(),
    );
  }
}