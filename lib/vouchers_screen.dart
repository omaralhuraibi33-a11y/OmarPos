import 'package:flutter/material.dart';
import 'db_helper.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({Key? key}) : super(key: key);

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  List<Voucher> _vouchersList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    final data = await DBHelper.getAllVouchers();
    setState(() {
      _vouchersList = data;
      _isLoading = false;
    });
  }

  void _showAddVoucherDialog() {
    String voucherType = 'receipt'; // 'receipt' (قبض), 'payment' (صرف), 'expense' (مصروف)
    String targetType = 'customer';  // 'customer', 'supplier', 'general'
    
    Customer? selectedCustomer;
    Supplier? selectedSupplier;
    
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final expenseNameController = TextEditingController();

    List<Customer> customersList = [];
    List<Supplier> suppliersList = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // تحميل البيانات لأول مرة داخل الحوار
            if (customersList.isEmpty && suppliersList.isEmpty) {
              DBHelper.getAllCustomers().then((c) {
                setDialogState(() => customersList = c);
              });
              DBHelper.getAllSuppliers().then((s) {
                setDialogState(() => suppliersList = s);
              });
            }

            // حساب الرصيد الظاهر
            double currentBalance = 0.0;
            if (targetType == 'customer' && selectedCustomer != null) {
              currentBalance = selectedCustomer!.balance;
            } else if (targetType == 'supplier' && selectedSupplier != null) {
              currentBalance = selectedSupplier!.balance;
            }

            return AlertDialog(
              title: const Text('إضافة سند جديد', textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. اختيار نوع السند
                    const Text('نوع السند:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: voucherType,
                      items: const [
                        DropdownMenuItem(value: 'receipt', child: Text('سند قبض (استلام أموال)')),
                        DropdownMenuItem(value: 'payment', child: Text('سند صرف (دفع أموال)')),
                        DropdownMenuItem(value: 'expense', child: Text('سند مصروفات')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            voucherType = val;
                            if (voucherType == 'expense') {
                              targetType = 'general';
                            } else if (targetType == 'general') {
                              targetType = 'customer';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // 2. تحديد الجهة (عميل / مورد) إذا لم يكن مصروفاً
                    if (voucherType != 'expense') ...[
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('عميل', style: TextStyle(fontSize: 14)),
                              value: 'customer',
                              groupValue: targetType,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setDialogState(() {
                                targetType = val!;
                                selectedSupplier = null;
                              }),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('مورد', style: TextStyle(fontSize: 14)),
                              value: 'supplier',
                              groupValue: targetType,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setDialogState(() {
                                targetType = val!;
                                selectedCustomer = null;
                              }),
                            ),
                          ),
                        ],
                      ),

                      // قائمة اختيار العميل
                      if (targetType == 'customer')
                        DropdownButton<Customer>(
                          isExpanded: true,
                          hint: const Text('اختر العميل *'),
                          value: selectedCustomer,
                          items: customersList.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(() => selectedCustomer = val),
                        ),

                      // قائمة اختيار المورد
                      if (targetType == 'supplier')
                        DropdownButton<Supplier>(
                          isExpanded: true,
                          hint: const Text('اختر المورد *'),
                          value: selectedSupplier,
                          items: suppliersList.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(() => selectedSupplier = val),
                        ),
                    ],

                    // كتابة اسم المصروف في حال اختيار "مصروفات"
                    if (voucherType == 'expense')
                      TextField(
                        controller: expenseNameController,
                        decoration: const InputDecoration(
                          labelText: 'بند المصروف (مثال: كهرباء / إيجار / ضيافة) *',
                        ),
                      ),

                    // 3. عرض الرصيد المالي الحالي فور الاختيار
                    if (voucherType != 'expense' && (selectedCustomer != null || selectedSupplier != null)) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentBalance > 0 ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: currentBalance > 0 ? Colors.red.shade300 : Colors.green.shade300,
                          ),
                        ),
                        child: Text(
                          'الرصيد الحالي: ${currentBalance.toStringAsFixed(2)} ${currentBalance > 0 ? "(عليه دين)" : "(له رصيد)"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentBalance > 0 ? Colors.red.shade900 : Colors.green.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // 4. المبلغ والملاحظات
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'المبلغ *'),
                    ),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'ملاحظات / بيان السند'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
                      );
                      return;
                    }

                    String? targetId;
                    String? targetName;

                    if (voucherType == 'expense') {
                      if (expenseNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى تحديد بند المصروف')),
                        );
                        return;
                      }
                      targetName = expenseNameController.text.trim();
                    } else if (targetType == 'customer') {
                      if (selectedCustomer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى اختيار العميل')),
                        );
                        return;
                      }
                      targetId = selectedCustomer!.id;
                      targetName = selectedCustomer!.name;
                    } else if (targetType == 'supplier') {
                      if (selectedSupplier == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى اختيار المورد')),
                        );
                        return;
                      }
                      targetId = selectedSupplier!.id;
                      targetName = selectedSupplier!.name;
                    }

                    final newVoucher = Voucher(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      voucherType: voucherType,
                      targetType: targetType,
                      targetId: targetId,
                      targetName: targetName,
                      amount: amount,
                      date: DateTime.now().toString().split('.')[0],
                      notes: notesController.text.trim(),
                    );

                    await DBHelper.addVoucher(newVoucher);

                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadVouchers();
                    }
                  },
                  child: const Text('حفظ السند'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السندات والمصروفات'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vouchersList.isEmpty
              ? const Center(child: Text('لا توجد سندات مسجلة حالياً'))
              : ListView.builder(
                  itemCount: _vouchersList.length,
                  itemBuilder: (context, index) {
                    final v = _vouchersList[index];

                    String typeTitle = 'سند قبض';
                    Color typeColor = Colors.green;
                    IconData icon = Icons.arrow_downward;

                    if (v.voucherType == 'payment') {
                      typeTitle = 'سند صرف';
                      typeColor = Colors.orange.shade800;
                      icon = Icons.arrow_upward;
                    } else if (v.voucherType == 'expense') {
                      typeTitle = 'مصروفات';
                      typeColor = Colors.red;
                      icon = Icons.money_off;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withOpacity(0.2),
                          child: Icon(icon, color: typeColor),
                        ),
                        title: Text(
                          '$typeTitle - ${v.targetName ?? 'عام'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${v.date}\n${v.notes}'),
                        isThreeLine: v.notes.isNotEmpty,
                        trailing: Text(
                          '${v.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVoucherDialog,
        icon: const Icon(Icons.add),
        label: const Text('سند جديد'),
      ),
    );
  }
}
