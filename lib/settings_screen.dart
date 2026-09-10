import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات النظام'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: const Center(child: Text('شاشة إعدادات النظام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }
}
