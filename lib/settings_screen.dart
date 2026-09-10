import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات النظام'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.settings, size: 36, color: Colors.blueGrey),
                title: const Text('إعدادات البرنامج', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('ضبط الطابعة، اسم المحل، والنسخ الاحتياطي'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة الإعدادات جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
