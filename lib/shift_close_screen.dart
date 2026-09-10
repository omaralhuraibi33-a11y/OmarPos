import 'package:flutter/material.dart';

class ShiftCloseScreen extends StatelessWidget {
  const ShiftCloseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إغلاق الصندوق / الوردية'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: const Center(child: Text('شاشة إغلاق الصندوق / الوردية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }
}
