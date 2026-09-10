import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, size: 36, color: Colors.deepOrange),
                title: const Text('المستخدمين والصلاحيات', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إضافة كاشير وتحديد صلاحيات الوصول'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة المستخدمين جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
