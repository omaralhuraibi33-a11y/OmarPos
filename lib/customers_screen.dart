import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'db_helper.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshCustomers();
  }

  /// التحقق من وجود "عميل نقدي" افتراضي إضافة إلى باقي العملاء
  Future<void> _refreshCustomers() async {
    setState(() => _isLoading = true);
    final data = await DBHelper.getAllCustomers();

    // التحقق من وجود العميل النقدي الافتراضي في القائمة
    bool hasDefaultCashCustomer = data.any((c) => c.id == 'cash_customer' || c.name == 'عميل نقدي');
    if (!hasDefaultCashCustomer) {
      final defaultCashCustomer = Customer(
        id: 'cash_customer',
        name: 'عميل نقدي',
        phone: '000000000',
        address: 'افتراضي',
        balance: 0.0,
        notes: 'عميل افتراضي للمبيعات النقدية (غير قابل للحذف أو التعديل)',
      );
      await DBHelper.saveCustomer(defaultCashCustomer);
      data.insert(0, defaultCashCustomer);
    }

    setState(() {
      _allCustomers = data;
      _filteredCustomers = data;
      _isLoading = false;
    });
  }

  void _filterCustomers(String query) {
    final filtered = _allCustomers.where((c) {
      final nameMatches = c.name.toLowerCase().contains(query.toLowerCase());
      final phoneMatches = c.phone.contains(query);
      return nameMatches || phoneMatches;
    }).toList();

    setState(() {
      _filteredCustomers = filtered;
    });
  }

  /// الانتقال إلى شاشة كاملة لعرض كشف حساب العميل وتصدير PDF
  void _openCustomerStatementScreen(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerStatementScreen(customer: customer),
      ),
    );
  }

  void _showCustomerDialog({Customer? customer}) {
    if (customer != null && (customer.id == 'cash_customer' || customer.name == 'عميل نقدي')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('العميل النقدي افتراضي ولا يمكن تعديله')),
      );
      return;
    }

    final isEditing = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    final balanceController = TextEditingController(
      text: customer != null ? customer.balance.toString() : '0.0',
    );
    final notesController = TextEditingController(text: customer?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'تعديل بيانات عميل' : 'إضافة عميل جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم العميل *'),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف *'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'الرصيد المالي (موجب = عليه دين)',
                ),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى كتابة الاسم ورقم الهاتف')),
                );
                return;
              }

              final newCustomer = Customer(
                id: isEditing ? customer.id : DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
                balance: double.tryParse(balanceController.text.trim()) ?? 0.0,
                notes: notesController.text.trim(),
              );

              await DBHelper.saveCustomer(newCustomer);
              if (mounted) {
                Navigator.pop(ctx);
                _refreshCustomers();
              }
            },
            child: Text(isEditing ? 'تحديث' : 'حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer(Customer customer) {
    if (customer.id == 'cash_customer' || customer.name == 'عميل نقدي') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حذف العميل النقدي الافتراضي للنظام')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العميل ${customer.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DBHelper.deleteCustomer(customer.id);
              if (mounted) {
                Navigator.pop(ctx);
                _refreshCustomers();
              }
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
        title: const Text('إدارة العملاء'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCustomers,
              decoration: InputDecoration(
                hintText: 'بحث باسم العميل أو رقم الهاتف...',
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
                : _filteredCustomers.isEmpty
                    ? const Center(child: Text('لا يوجد عملاء حالياً'))
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final c = _filteredCustomers[index];
                          final isDefaultCash = c.id == 'cash_customer' || c.name == 'عميل نقدي';
                          final hasDebt = c.balance > 0;

                          return Card(
                            color: isDefaultCash ? Colors.amber.shade50 : null,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDefaultCash
                                    ? Colors.amber.shade200
                                    : (hasDebt ? Colors.red.shade100 : Colors.green.shade100),
                                child: Icon(
                                  isDefaultCash ? Icons.point_of_sale : Icons.person,
                                  color: isDefaultCash
                                      ? Colors.orange.shade900
                                      : (hasDebt ? Colors.red : Colors.green),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (isDefaultCash) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'افتراضي',
                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                              subtitle: Text(
                                isDefaultCash
                                    ? 'عميل المبيعات النقدية المباشرة'
                                    : 'هاتف: ${c.phone}${c.address.isNotEmpty ? ' | ${c.address}' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      c.balance.toStringAsFixed(2),
                                      style: TextStyle(
                                        color: hasDebt ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.receipt_long,
                                        size: 20, color: Colors.teal),
                                    tooltip: 'كشف حساب',
                                    onPressed: () => _openCustomerStatementScreen(c),
                                  ),
                                  if (!isDefaultCash) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 20, color: Colors.blue),
                                      onPressed: () =>
                                          _showCustomerDialog(customer: c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 20, color: Colors.red),
                                      onPressed: () => _deleteCustomer(c),
                                    ),
                                  ],
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
        onPressed: () => _showCustomerDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// شاشة كاملة لعرض كشف حساب العميل مع زر تصدير PDF
class CustomerStatementScreen extends StatelessWidget {
  final Customer customer;

  const CustomerStatementScreen({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('كشف حساب: ${customer.name}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير PDF',
            onPressed: () async {
              final statementTransactions = await DBHelper.getCustomerStatement(customer.id);
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async {
                  final pdf = pw.Document();
                  pdf.addPage(
                    pw.Page(
                      pageFormat: format,
                      build: (pw.Context context) {
                        return pw.Directionality(
                          textDirection: pw.TextDirection.rtl,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('كشف حساب العميل: ${customer.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 6),
                              pw.Text('الرصيد الحالي: ${customer.balance.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                              pw.SizedBox(height: 10),
                              pw.Divider(),
                              pw.Row(
                                children: [
                                  pw.Expanded(flex: 2, child: pw.Text('التاريخ / الحركة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                                  pw.Expanded(child: pw.Text('دائن (له)', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                                  pw.Expanded(child: pw.Text('مدين (عليه)', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                                  pw.Expanded(child: pw.Text('الرصيد', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                                ],
                              ),
                              pw.Divider(),
                              ...statementTransactions.map((item) {
                                final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;
                                final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
                                final runningBalance = (item['runningBalance'] as num?)?.toDouble() ?? 0.0;
                                return pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                  child: pw.Row(
                                    children: [
                                      pw.Expanded(
                                        flex: 2,
                                        child: pw.Column(
                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                          children: [
                                            pw.Text(item['type'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                            pw.Text(item['date'] ?? '', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                                          ],
                                        ),
                                      ),
                                      pw.Expanded(child: pw.Text(credit > 0 ? credit.toStringAsFixed(2) : '-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                                      pw.Expanded(child: pw.Text(debit > 0 ? debit.toStringAsFixed(2) : '-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                                      pw.Expanded(child: pw.Text(runningBalance.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                  return pdf.save();
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper.getCustomerStatement(customer.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final statementTransactions = snapshot.data ?? [];

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('اسم العميل: ${customer.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'الرصيد الحالي: ${customer.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: customer.balance > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey.shade300,
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('التاريخ / الحركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(child: Text('دائن (له)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green))),
                    Expanded(child: Text('مدين (عليه)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red))),
                    Expanded(child: Text('الرصيد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              Expanded(
                child: statementTransactions.isEmpty
                    ? const Center(
                        child: Text('لا توجد حركات مسجلة لهذا العميل حتى الآن', textAlign: TextAlign.center),
                      )
                    : ListView.builder(
                        itemCount: statementTransactions.length,
                        itemBuilder: (ctx, index) {
                          final item = statementTransactions[index];
                          final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;
                          final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
                          final runningBalance = (item['runningBalance'] as num?)?.toDouble() ?? 0.0;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                                    credit > 0 ? credit.toStringAsFixed(2) : '-',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    debit > 0 ? debit.toStringAsFixed(2) : '-',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    runningBalance.toStringAsFixed(2),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
