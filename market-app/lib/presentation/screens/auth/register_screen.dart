import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.register)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.fullName, prefixIcon: Icon(Icons.person_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.email, prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: AppStrings.phoneNumber, prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: AppStrings.password, prefixIcon: Icon(Icons.lock_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: AppStrings.confirmPassword, prefixIcon: Icon(Icons.lock_outlined)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                child: const Text(AppStrings.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
