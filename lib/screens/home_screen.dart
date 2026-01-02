import 'package:flutter/material.dart';
import 'services_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: const Center(
        child: Text("Welcome to Dummy App"),
      ),
    );
  }
}
Text(
  "Welcome to Dummy App",
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
),
CustomButton(
  text: "Get Started",
  onPressed: () {},
),
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServicesScreen(),
      ),
    );
  },
  child: const Text("View Services"),
  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ProfileScreen(),
    ),
  );
},

),
