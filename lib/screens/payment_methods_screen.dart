import 'package:flutter/material.dart';
import 'package:omar_pos/db_helper.dart';
import 'dart:convert'; // نحتاجه لتحويل القائمة إلى نص لتخزينها في قاعدة البيانات

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // الطرق الأساسية والمضافة وحالتها (مفعلة أو غير مفعلة)
  Map<String, bool> _methods = {
    'نقدي': true,
    'أجل': true,
  };

  // قائمة الطرق الأساسية التي لا يمكن حذفها
  final List<String> _defaultMethods = ['نقدي', 'أجل'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  // جلب طرق الدفع المخزنة من قاعدة البيانات
  Future<void> _loadPaymentMethods() async {
    final savedMethodsJson = await DBHelper.getSetting('payment_methods');
    
    if (savedMethodsJson != null && savedMethodsJson.isNotEmpty) {
      try {
        // فك تشفير البيانات المخزنة كـ Map
        final Map<String, dynamic> decoded = jsonDecode(savedMethodsJson);
        setState(() {
          _methods = decoded.map((key, value) => MapEntry(key, value as bool));
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  // حفظ طرق الدفع وحالاتها في قاعدة البيانات
  Future<void> _savePaymentMethods() async {
    // تحويل الـ Map إلى نص (JSON) لتخزينه في جدول الإعدادات
    final encodedMethods = jsonEncode(_methods);
    await DBHelper.saveSetting('payment_methods', encodedMethods);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ طرق الدفع بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

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
                  _methods[newMethod] = true; // تفعيلها افتراضياً عند الإضافة
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
      appBar: AppBar(
        title: const Text('طرق الدفع'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // زر حفظ علوي سريع
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'حفظ التغييرات',
            onPressed: _savePaymentMethods,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: _addPaymentMethod,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ..._methods.keys.map((key) {
                  final isDefault = _defaultMethods.contains(key);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
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
                const SizedBox(height: 20),
                // زر الحفظ الرئيسي في أسفل الصفحة
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _savePaymentMethods,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ طرق الدفع', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
    );
  }
}
