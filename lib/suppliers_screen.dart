import 'package:flutter/material.dart';
import 'db_helper.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(Key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier> _allSuppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final list = await DBHelper.getAllSuppliers();
    setState(() {
      _allSuppliers = list;
      _filteredSuppliers = list;
      _isLoading = false;
    });
  }

  void _filterSuppliers(String query) {
    final filtered = _allSuppliers.where((s) {
      final nameMatches = s.name.toLowerCase().contains(query.toLowerCase());
      final phoneMatches = s.phone.contains(query);
      return nameMatches || phoneMatches;
    }).toList();

    setState(() {
      _filteredSuppliers = filtered;
    });
  }

  // إضافة أو تعديل مورد
  void _showSupplierDialog([Supplier? supplier]) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final notesController = TextEditingController(text: supplier?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplier == null ? 'إضافة مورد جديد' : 'تعديل بيانات المورد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم المورد *', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'مورد ماذا؟ (ملاحظات/نوع البضاعة)',
                  hintText: 'مثال: مورد بهارات، مورد أكياس وتغليف...',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final newSupplier = Supplier(
                id: supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                notes: notesController.text.trim(),
                balance: supplier?.balance ?? 0.0,
              );

              await DBHelper.saveSupplier(newSupplier);
              Navigator.pop(ctx);
              _loadSuppliers();
            },
            child: Text(supplier == null ? 'إضافة' : 'حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  // تسديد مبلغ لمورد
  void _showPaySupplierDialog(Supplier supplier) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسديد حساب لمورد: ${supplier.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الرصيد المستحق الحالي: ${supplier.balance.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ المسدد *',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات / رقم السند',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;

              final now = DateTime.now().toString().split('.')[0];
              await DBHelper.addSupplierTransaction(
                supplierId: supplier.id,
                type: 'payment',
                debit: amount,
                credit: 0.0,
                date: now,
                notes: notesController.text.trim(),
              );

              Navigator.pop(ctx);
              _loadSuppliers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تسجيل دفعة التسديد بنجاح'), backgroundColor: Colors.green),
              );
            },
            child: const Text('تسجيل السداد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // نافذة كشف حساب المورد
  void _showSupplierStatement(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper.getSupplierStatement(supplier.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final statementTransactions = snapshot.data ?? [];

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كشف حساب المورد: ${supplier.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  'المبلغ المستحق له: ${supplier.balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: supplier.balance > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: statementTransactions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('لا توجد حركات مسجلة لهذا المورد حتى الآن', textAlign: TextAlign.center),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey.shade300,
                          child: const Row(
                            children: [
                              Expanded(flex: 2, child: Text('التاريخ / الحركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(child: Text('له (دائن)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red))),
                              Expanded(child: Text('عليه/مسدد (مدين)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green))),
                              Expanded(child: Text('الرصيد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: statementTransactions.length,
                            itemBuilder: (ctx, index) {
                              final item = statementTransactions[index];
                              final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;
                              final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
                              final runningBalance = (item['runningBalance'] as num?)?.toDouble() ?? 0.0;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text(item['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        credit > 0 ? '${credit.toStringAsFixed(2)}' : '-',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        debit > 0 ? '${debit.toStringAsFixed(2)}' : '-',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        runningBalance.toStringAsFixed(2),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      ),
    );
  }

  // حذف مورد
  void _confirmDeleteSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت أؤكد من حذف المورد "${supplier.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DBHelper.deleteSupplier(supplier.id);
              Navigator.pop(ctx);
              _loadSuppliers();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموردين'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSuppliers,
              decoration: InputDecoration(
                hintText: 'بحث باسم المورد أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSuppliers.isEmpty
                    ? const Center(child: Text('لا يوجد موردين حالياً'))
                    : ListView.builder(
                        itemCount: _filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final sup = _filteredSuppliers[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sup.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (sup.phone.isNotEmpty)
                                          Text(
                                            'هاتف: ${sup.phone}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        if (sup.notes.isNotEmpty)
                                          Text(
                                            sup.notes,
                                            style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontStyle: FontStyle.italic),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('له:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text(
                                          sup.balance.toStringAsFixed(2),
                                          style: TextStyle(
                                            color: sup.balance > 0 ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.monetization_on, size: 20, color: Colors.green),
                                    tooltip: 'تسديد حساب',
                                    onPressed: () => _showPaySupplierDialog(sup),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.receipt_long, size: 20, color: Colors.teal),
                                    tooltip: 'كشف حساب',
                                    onPressed: () => _showSupplierStatement(sup),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                                    tooltip: 'تعديل',
                                    onPressed: () => _showSupplierDialog(sup),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    tooltip: 'حذف',
                                    onPressed: () => _confirmDeleteSupplier(sup),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
