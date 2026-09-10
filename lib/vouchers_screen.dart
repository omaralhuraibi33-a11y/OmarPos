import 'package0/flutter/material.dart';
import 'package:flutter/material.dart';

class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السندات'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: const Center(child: Text('شاشة السندات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }
}
