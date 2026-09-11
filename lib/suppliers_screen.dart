import 'package:flutter/material.dart';
import 'db_helper.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  int _selectedTab = 0; // 0 = الموردين, 1 = كشف حساب

  List<Supplier> _suppliers = [];
  bool _isLoading = true;

  // متغيرات كشف الحساب
  Supplier? _selectedSupplierForStatement;
  String _searchStatementQuery = '';
  List<Map<String, dynamic>> _statementTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final list = await DBHelper.getAllSuppliers();
    setState(() {
      _suppliers = list;
      _isLoading = false;
      if (_suppliers.isNotEmpty && _selectedSupplierForStatement == null) {
        _selectedSupplierForStatement = _suppliers.first;
        _loadStatementForSupplier(_suppliers.first.id);
      }
    });
  }

  Future<void> _loadStatementForSupplier(String supplierId) async {
    final trans = await DBHelper.getSupplierStatement(supplierId);
    setState(() {
      _statementTransactions = trans;
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

  // حذف مورد
  void _confirmDeleteSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت أيد من حذف المورد "${supplier.name}"؟'),
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
        title: const Text('إدارة الموردين والحسابات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // الأزرار العلوية الصغيرة للتبديل
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 0 ? Colors.blue.shade800 : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => setState(() => _selectedTab = 0),
                    icon: const Icon(Icons.people, size: 18, color: Colors.white),
                    label: const Text('الموردين', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 1 ? Colors.blue.shade800 : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => setState(() => _selectedTab = 1),
                    icon: const Icon(Icons.receipt_long, size: 18, color: Colors.white),
                    label: const Text('كشف حساب', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),

          // المحتوى حسب التبويب
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _buildSuppliersTab()
                    : _buildStatementTab(),
          ),
        ],
      ),
    );
  }

  // التبويب الأول: قائمة الموردين
  Widget _buildSuppliersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي الموردين: ${_suppliers.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _showSupplierDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة مورد', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _suppliers.isEmpty
              ? const Center(child: Text('لا يوجد موردين مسجلين حالياً'))
              : ListView.builder(
                  itemCount: _suppliers.length,
                  itemBuilder: (ctx, index) {
                    final sup = _suppliers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.business, color: Colors.blue),
                        ),
                        title: Row(
                          children: [
                            Text(sup.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            // إجمالي المبلغ الذي له
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: sup.balance > 0 ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: sup.balance > 0 ? Colors.red : Colors.green),
                              ),
                              child: Text(
                                'له: ${sup.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: sup.balance > 0 ? Colors.red.shade900 : Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sup.phone.isNotEmpty) Text('هاتف: ${sup.phone}'),
                            if (sup.notes.isNotEmpty)
                              Text('مورد: ${sup.notes}', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showSupplierDialog(sup),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }

  // التبويب الثاني: كشف الحساب التفصيلي
  Widget _buildStatementTab() {
    final filteredSuppliers = _suppliers.where((s) => s.name.contains(_searchStatementQuery)).toList();

    return Column(
      children: [
        // خيار البحث واختيار المورد
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.blue.shade50,
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _searchStatementQuery = val),
                decoration: InputDecoration(
                  hintText: 'بحث عن مورد...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('عرض كشف: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Supplier>(
                          value: _selectedSupplierForStatement,
                          isExpanded: true,
                          hint: const Text('اختر المورد'),
                          items: filteredSuppliers.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSupplierForStatement = val);
                              _loadStatementForSupplier(val.id);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // رأس التقرير المالي للمورد
        if (_selectedSupplierForStatement != null)
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.blue.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المورد: ${_selectedSupplierForStatement!.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'الرصيد المتبقي له: ${_selectedSupplierForStatement!.balance.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),

        // جدول / قائمة حركة كشف الحساب
        Expanded(
          child: _selectedSupplierForStatement == null
              ? const Center(child: Text('يرجى اختيار مورد لعرض كشف الحساب'))
              : _statementTransactions.isEmpty
                  ? const Center(child: Text('لا توجد عمليات مسجلة لهذا المورد'))
                  : Column(
                      children: [
                        // العناوين
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey.shade300,
                          child: const Row(
                            children: [
                              Expanded(flex: 2, child: Text('التاريخ / الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(child: Text('له (دائن)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                              Expanded(child: Text('عليه (مدين)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                              Expanded(child: Text('الرصيد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        // البيانات
                        Expanded(
                          child: ListView.builder(
                            itemCount: _statementTransactions.length,
                            itemBuilder: (ctx, index) {
                              final item = _statementTransactions[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                                          Text(item['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text(item['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item['credit'] > 0 ? '${item['credit']}' : '-',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item['debit'] > 0 ? '${item['debit']}' : '-',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${item['runningBalance']}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
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
      ],
    );
  }
}
