import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final AuthService _authService = AuthService();

  void signup() async {
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Passwords do not match'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    try {
      await _authService.signUpWithDetails(
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text.trim(),
        userModel: UserModel(
          uid: '',
          isOnline: true,
          name: nameController.text.trim(),
          email: emailController.text.trim().toLowerCase(),
          phone: phoneController.text.trim(),
          address: addressController.text.trim(),
          preferences: {'theme': 'light'},
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Signup Failed'),
              content: Text('Error: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(40.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40.0),
        borderSide: const BorderSide(color: Colors.orange, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40.0),
        borderSide: const BorderSide(color: Colors.orange, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Image.asset('assets/images/logo_trans.png', height: 150),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: inputDecoration('Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: inputDecoration('Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: inputDecoration('Confirm Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: inputDecoration('Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: inputDecoration('Address'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: signup,
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF914D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                  ),
                  fixedSize: const Size(180, 50),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: Color.fromARGB(255, 108, 108, 108),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
