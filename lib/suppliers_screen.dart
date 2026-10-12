import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'db_helper.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
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

  // الانتقال إلى شاشة كاملة لعرض كشف حساب المورد وتصدير PDF
  void _openSupplierStatementScreen(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierStatementScreen(supplier: supplier),
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
                                  // تم إلغاء زر وسند التسديد المباشر من هنا
                                  IconButton(
                                    icon: const Icon(Icons.receipt_long, size: 20, color: Colors.teal),
                                    tooltip: 'كشف حساب',
                                    onPressed: () => _openSupplierStatementScreen(sup),
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

/// شاشة كاملة لعرض كشف حساب المورد مع زر تصدير PDF بتصميم أنيق ومبسط
class SupplierStatementScreen extends StatelessWidget {
  final Supplier supplier;

  const SupplierStatementScreen({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('كشف حساب المورد: ${supplier.name}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير PDF',
            onPressed: () async {
              final statementTransactions = await DBHelper.getSupplierStatement(supplier.id);
              final pdf = pw.Document();
              final arabicFont = await PdfGoogleFonts.cairoRegular();
              final arabicBoldFont = await PdfGoogleFonts.cairoBold();

              // حساب إجمالي الدائن والمدين للمورد
              double totalCredit = 0;
              double totalDebit = 0;
              for (var item in statementTransactions) {
                totalCredit += (item['credit'] as num?)?.toDouble() ?? 0.0;
                totalDebit += (item['debit'] as num?)?.toDouble() ?? 0.0;
              }

              pdf.addPage(
                pw.MultiPage(
                  pageFormat: PdfPageFormat.a4,
                  textDirection: pw.TextDirection.rtl,
                  build: (pw.Context context) {
                    return [
                      // 1. ترويسة بسيطة لكشف المورد
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blueGrey50,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('كشف حساب مورد', style: pw.TextStyle(font: arabicBoldFont, fontSize: 16, color: PdfColors.blue900)),
                                pw.SizedBox(height: 4),
                                pw.Text('المورد: ${supplier.name}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                                if (supplier.phone.isNotEmpty)
                                  pw.Text('الهاتف: ${supplier.phone}', style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColors.grey700)),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text('التاريخ: ${DateTime.now().toString().split(' ')[0]}', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                                pw.SizedBox(height: 6),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: pw.BoxDecoration(
                                    color: supplier.balance > 0 ? PdfColors.red100 : PdfColors.green100,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Text(
                                    'المبلغ المستحق له: ${supplier.balance.toStringAsFixed(2)}',
                                    style: pw.TextStyle(font: arabicBoldFont, fontSize: 11, color: supplier.balance > 0 ? PdfColors.red900 : PdfColors.green900),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 15),

                      // 2. جدول الحركات المالي للمورد (مرتب من اليمين: التاريخ، نوع الحركة، له، عليه، الرصيد)
                      pw.Table.fromTextArray(
                        headers: ['التاريخ', 'نوع الحركة', 'له (دائن)', 'عليه/مسدد (مدين)', 'الرصيد'],
                        data: statementTransactions.map((item) {
                          final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;
                          final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
                          final runningBalance = (item['runningBalance'] as num?)?.toDouble() ?? 0.0;
                          return [
                            item['date'] ?? '',
                            item['type'] ?? '',
                            credit > 0 ? credit.toStringAsFixed(2) : '-',
                            debit > 0 ? debit.toStringAsFixed(2) : '-',
                            runningBalance.toStringAsFixed(2),
                          ];
                        }).toList(),
                        headerStyle: pw.TextStyle(font: arabicBoldFont, color: PdfColors.white, fontSize: 10),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                        cellStyle: pw.TextStyle(font: arabicFont, fontSize: 9),
                        cellAlignment: pw.Alignment.center,
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2.5),
                          1: const pw.FlexColumnWidth(2),
                          2: const pw.FlexColumnWidth(1.5),
                          3: const pw.FlexColumnWidth(1.5),
                          4: const pw.FlexColumnWidth(1.5),
                        },
                      ),
                      pw.SizedBox(height: 15),

                      // 3. ملخص الإجماليات والتوقيعات
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('إجمالي الدائن (له): ${totalCredit.toStringAsFixed(2)}', style: pw.TextStyle(font: arabicBoldFont, fontSize: 10, color: PdfColors.red800)),
                          pw.Text('إجمالي المدين (عليه): ${totalDebit.toStringAsFixed(2)}', style: pw.TextStyle(font: arabicBoldFont, fontSize: 10, color: PdfColors.green800)),
                        ],
                      ),
                      pw.SizedBox(height: 30),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('توقيع المحاسب: .....................', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                          pw.Text('توقيع المورد: .....................', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ],
                      )
                    ];
                  },
                ),
              );

              await Printing.sharePdf(bytes: await pdf.save(), filename: 'كشف_حساب_مورد_${supplier.name}.pdf');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper.getSupplierStatement(supplier.id),
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
                    Text('اسم المورد: ${supplier.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'المبلغ المستحق له: ${supplier.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: supplier.balance > 0 ? Colors.red : Colors.green,
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
                    Expanded(child: Text('له (دائن)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red))),
                    Expanded(child: Text('عليه/مسدد (مدين)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green))),
                    Expanded(child: Text('الرصيد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              Expanded(
                child: statementTransactions.isEmpty
                    ? const Center(
                        child: Text('لا توجد حركات مسجلة لهذا المورد حتى الآن', textAlign: TextAlign.center),
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
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    debit > 0 ? debit.toStringAsFixed(2) : '-',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
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
