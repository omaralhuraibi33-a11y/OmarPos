import 'package:flutter/material.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.people, size: 36, color: Colors.purple),
                title: const Text('دليل العملاء', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إضافة عملاء الجملة والتجزئة وتتبع حساباتهم'),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('شاشة العملاء جاهزة للتطوير والتعديل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
