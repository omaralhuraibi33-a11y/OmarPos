import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: const Center(child: Text('شاشة إدارة المستخدمين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }
}
