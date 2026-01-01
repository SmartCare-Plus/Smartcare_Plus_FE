import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Services")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text("Service One"),
            subtitle: Text("Fall detection and prevention"),
          ),
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text("Service Two"),
            subtitle: Text("Meal generator"),
          ),
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text("Service Three"),
            subtitle: Text("Exercise generator and Monitoring "),
          ),
        ],
      ),
    );
  }
}
