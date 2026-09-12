import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final Map<String, bool> _methods = {
    'كاش (نقدي)': true,
    'شبكة (بطاقة)': true,
    'آجل (حساب زبون)': true,
    'تحويل بنكي': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طرق الدفع')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: _methods.keys.map((key) {
          return SwitchListTile(
            title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
            value: _methods[key]!,
            onChanged: (val) => setState(() => _methods[key] = val),
          );
        }).toList(),
      ),
    );
  }
}

