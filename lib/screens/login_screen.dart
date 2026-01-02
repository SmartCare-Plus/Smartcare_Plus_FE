import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {TextField(
  decoration: const InputDecoration(
    labelText: "Email",
    errorText: null,
  ),
),
TextField(
  decoration: const InputDecoration(
    labelText: "Email",
    errorText: null,
  ),
),

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TextField(
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }
}
const SizedBox(height: 20),
ElevatedButton(
  onPressed: () {
    print("Login clicked");
  },
  child: const Text("Login"),
),
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  },
  child: const Text("Don't have an account? Register"),

  final authService = AuthService();
  print(authService.login("test@test.com", "123456"));

),
