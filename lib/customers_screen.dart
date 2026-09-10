import 'package/flutter/material.dart'; // تم تصحيحها لـ package:flutter
import 'package:flutter/material.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العملاء'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: const Center(child: Text('شاشة العملاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }
}
