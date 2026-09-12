import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // الطرق الأساسية والمضافة
  final Map<String, bool> _methods = {
    'نقدي': true,
    'أجل': true,
  };

  // قائمة الطرق الأساسية التي لا يمكن حذفها
  final List<String> _defaultMethods = ['نقدي', 'أجل'];

  void _addPaymentMethod() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة طريقة دفع جديدة'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'اسم طريقة الدفع (مثال: شبكة، تحويل بنكي)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newMethod = ctrl.text.trim();
              if (newMethod.isNotEmpty && !_methods.containsKey(newMethod)) {
                setState(() {
                  _methods[newMethod] = true;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طرق الدفع')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPaymentMethod,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: _methods.keys.map((key) {
          final isDefault = _defaultMethods.contains(key);
          return Card(
            child: SwitchListTile(
              title: Text(
                key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _methods[key]!,
              onChanged: (val) => setState(() => _methods[key] = val),
              secondary: !isDefault
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _methods.remove(key);
                        });
                      },
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
