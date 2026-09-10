import 'package:flutter/material.dart';

class CashBoxScreen extends StatelessWidget {
  const CashBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصندوق'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: const Center(child: Text('شاشة الصندوق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }
}
