import 'package:flutter/material.dart';
import 'db_helper.dart';

class PurchaseItem {
  final Product product;
  double quantity;
  double purchasePrice;
  double discount;

  PurchaseItem({
    required this.product,
    required this.quantity,
    required this.purchasePrice,
    this.discount = 0.0,
  });

  double get total => (quantity * purchasePrice) - discount;
}

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<Product> _allProducts = [];
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;

  bool _isReturnMode = false; // true = مرتجع مشتريات, false = فاتورة مشتريات

  final List<PurchaseItem> _purchaseItems = [];

  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _invoiceDiscountController = TextEditingController(text: '0.0');

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prods = await DBHelper.getAllProducts();
    final sups = await DBHelper.getAllSuppliers();
    setState(() {
      _allProducts = prods;
      _suppliers = sups;
      _isLoading = false;
    });
  }

  double get _subTotal => _purchaseItems.fold(0.0, (sum, item) => sum + item.total);
  double get _invoiceDiscount => double.tryParse(_invoiceDiscountController.text.trim()) ?? 0.0;
  double get _finalTotal => (_subTotal - _invoiceDiscount) < 0 ? 0.0 : (_subTotal - _invoiceDiscount);

  void _resetInvoice() {
    setState(() {
      _purchaseItems.clear();
      _selectedSupplier = null;
      _supplierController.clear();
      _invoiceDiscountController.text = '0.0';
    });
  }

  void _showSelectSupplierDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isReturnMode ? 'اختر المورد للمرتجع' : 'اختيار مورد *'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (_suppliers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('لا يوجد موردين مسجلين حالياً. أضف مورداً أولاً', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
              ..._suppliers.map((sup) => ListTile(
                leading: Icon(Icons.business, color: theme.colorScheme.primary),
                title: Text(sup.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('الرصيد الحالي: ${sup.balance.toStringAsFixed(2)}'),
                onTap: () {
                  setState(() {
                    _selectedSupplier = sup;
                    _supplierController.text = sup.name;
                  });
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.disabledColor),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    if (_allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أصناف بالمخزن. أضف أصنافاً أولاً')),
      );
      return;
    }

    final theme = Theme.of(context);
    Product selectedProduct = _allProducts.first;
    final quantityController = TextEditingController(text: '1.0');
    final priceController = TextEditingController(text: selectedProduct.purchasePrice.toString());
    final discountController = TextEditingController(text: '0.0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_isReturnMode ? 'إضافة صنف للمرتجع' : 'إضافة صنف للفاتورة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  decoration: const InputDecoration(labelText: 'اختر الصنف *', border: OutlineInputBorder()),
                  items: _allProducts.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedProduct = val;
                        priceController.text = val.purchasePrice.toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _isReturnMode ? 'الكمية المرجعة *' : 'الكمية المشتراة *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر الشراء *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'خصم الصنف (إن وجد)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.disabledColor),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isReturnMode ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              onPressed: () {
                final qty = double.tryParse(quantityController.text.trim()) ?? 0.0;
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final disc = double.tryParse(discountController.text.trim()) ?? 0.0;

                if (qty <= 0) return;

                setState(() {
                  _purchaseItems.add(PurchaseItem(
                    product: selectedProduct,
                    quantity: qty,
                    purchasePrice: price,
                    discount: disc,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('إضافة الصنف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _generateSequentialId(bool isReturn) async {
    final db = await DBHelper.database;
    final tableName = isReturn ? 'purchase_return_invoices' : 'purchase_invoices';
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    int count = 0;
    if (result.isNotEmpty) {
      count = (result.first['count'] as num?)?.toInt() ?? 0;
    }
    int nextSeq = count + 1;
    return isReturn ? 'return_$nextSeq' : 'pur_$nextSeq';
  }

  Future<void> _savePurchaseProcess() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار المورد أولاً لإتمام الحفظ'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة أصناف أولاً قبل الحفظ')),
      );
      return;
    }

    try {
      final String currentDate = DateTime.now().toString().split('.')[0];
      final int currentShift = await DBHelper.getCurrentShiftId();
      final db = await DBHelper.database;
      final String supplierNameText = _selectedSupplier!.name;

      if (_isReturnMode) {
        final String invoiceId = await _generateSequentialId(true);

        await db.insert('purchase_return_invoices', {
          'id': invoiceId,
          'invoiceType': 'purchase_return',
          'paymentType': 'credit',
          'totalAmount': _finalTotal,
          'date': currentDate,
          'supplierId': _selectedSupplier!.id,
          'supplierName': supplierNameText,
          'notes': 'مرتجع مشتريات - خصم: $_invoiceDiscount',
          'shiftId': currentShift,
          'isClosed': 0,
        });

        for (var item in _purchaseItems) {
          InvoiceItem invItem = InvoiceItem(
            id: '${invoiceId}_${item.product.id}',
            invoiceId: invoiceId,
            productId: item.product.id,
            productName: item.product.name,
            quantity: item.quantity,
            price: item.purchasePrice,
            total: item.total,
          );
          await DBHelper.savePurchaseReturnInvoiceItem(invItem);
          await DBHelper.updateProductStock(item.product.id, -item.quantity);
        }

        await DBHelper.addSupplierTransaction(
          supplierId: _selectedSupplier!.id,
          type: 'مرتجع مشتريات',
          credit: 0.0,
          debit: _finalTotal,
          date: currentDate,
          notes: 'مرتجع مشتريات رقم: $invoiceId',
        );

        _finishInvoiceProcess('تم حفظ مرتجع المشتريات برقم ($invoiceId) للمورد $supplierNameText بنجاح');
      } else {
        final String invoiceId = await _generateSequentialId(false);

        await db.insert('purchase_invoices', {
          'id': invoiceId,
          'invoiceType': 'purchase',
          'paymentType': 'credit',
          'totalAmount': _finalTotal,
          'date': currentDate,
          'supplierId': _selectedSupplier!.id,
          'supplierName': supplierNameText,
          'notes': 'فاتورة مشتريات - خصم: $_invoiceDiscount',
          'shiftId': currentShift,
          'isClosed': 0,
        });

        for (var item in _purchaseItems) {
          InvoiceItem invItem = InvoiceItem(
            id: '${invoiceId}_${item.product.id}',
            invoiceId: invoiceId,
            productId: item.product.id,
            productName: item.product.name,
            quantity: item.quantity,
            price: item.purchasePrice,
            total: item.total,
          );
          await DBHelper.savePurchaseInvoiceItem(invItem);
          
          await DBHelper.updateProductPriceAndStock(
            item.product.id,
            item.quantity,
            item.purchasePrice,
            item.product.sellPrice,
          );
        }

        await DBHelper.addSupplierTransaction(
          supplierId: _selectedSupplier!.id,
          type: 'فاتورة مشتريات',
          credit: _finalTotal,
          debit: 0.0,
          date: currentDate,
          notes: 'فاتورة مشتريات رقم: $invoiceId',
        );

        _finishInvoiceProcess('تم حفظ فاتورة المشتريات برقم ($invoiceId) للمورد $supplierNameText بنجاح');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _finishInvoiceProcess(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _isReturnMode ? theme.colorScheme.error : Colors.green.shade700,
      ),
    );
    _resetInvoice();
    if (_isReturnMode) {
      setState(() => _isReturnMode = false);
    }
    _loadData();
  }

  void _openInvoicesLog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocalPurchaseInvoicesLogScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isReturnMode ? theme.colorScheme.error : theme.colorScheme.primary,
        title: Text(
          _isReturnMode ? 'مرتجع مشتريات' : 'فاتورة المشتريات',
          style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: 'سجل الفواتير',
            onPressed: _openInvoicesLog,
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: Icon(_isReturnMode ? Icons.shopping_bag : Icons.assignment_return, color: Colors.white),
            label: Text(
              _isReturnMode ? 'فاتورة شراء' : 'مرتجع',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              setState(() {
                _isReturnMode = !_isReturnMode;
                _resetInvoice();
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _supplierController,
                          readOnly: true,
                          onTap: _showSelectSupplierDialog,
                          decoration: InputDecoration(
                            hintText: 'اختر المورد (إجباري)...',
                            labelText: _isReturnMode ? 'المورد المرجّع له *' : 'المورد *',
                            prefixIcon: IconButton(
                              icon: Icon(Icons.search, color: theme.colorScheme.primary, size: 28),
                              onPressed: _showSelectSupplierDialog,
                              tooltip: 'بحث عن مورد',
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _invoiceDiscountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'خصم الفاتورة',
                            prefixIcon: Icon(Icons.discount, color: theme.colorScheme.secondary),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _purchaseItems.isEmpty
                      ? Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isReturnMode ? theme.colorScheme.error : theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(
                              _isReturnMode ? 'اضغط لإضافة أصناف مرجعة' : 'اضغط لإضافة أصناف للفاتورة',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _purchaseItems.length,
                          itemBuilder: (ctx, index) {
                            final item = _purchaseItems[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: ListTile(
                                title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (item.quantity > 1) {
                                          setState(() => item.quantity--);
                                        }
                                      },
                                      child: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 20),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() => item.quantity++);
                                      },
                                      child: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('السعر: ${item.purchasePrice}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.total.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _isReturnMode ? theme.colorScheme.error : theme.colorScheme.primary,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                                      onPressed: () {
                                        setState(() => _purchaseItems.removeAt(index));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Container(
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المجموع الفرعي: ${_subTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('خصم الفاتورة: ${_invoiceDiscount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isReturnMode ? 'صافي المرتجع:' : 'الإجمالي النهائي:',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _finalTotal.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _isReturnMode ? theme.colorScheme.error : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _resetInvoice,
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: Text(
                                _isReturnMode ? 'تفريغ' : 'جديدة',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                            label: const Text('إضافة صنف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isReturnMode ? theme.colorScheme.error : theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _savePurchaseProcess,
                              icon: Icon(_isReturnMode ? Icons.assignment_return : Icons.save, color: Colors.white),
                              label: Text(
                                _isReturnMode ? 'حفظ المرتجع' : 'حفظ الفاتورة',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class LocalPurchaseInvoicesLogScreen extends StatefulWidget {
  const LocalPurchaseInvoicesLogScreen({Key? key}) : super(key: key);

  @override
  State<LocalPurchaseInvoicesLogScreen> createState() => _LocalPurchaseInvoicesLogScreenState();
}

class _LocalPurchaseInvoicesLogScreenState extends State<LocalPurchaseInvoicesLogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Invoice> _purchaseInvoices = [];
  List<Invoice> _returnInvoices = [];
  bool _isLoading = true;

  // متحكمات وحقول البحث والفلترة الزمنية
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // أنواع الفلاتر الزمنية: 'today', 'yesterday', 'week', 'month', 'year', 'custom'
  String _dateFilterType = 'today';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final purchases = await DBHelper.getAllPurchaseInvoices();
    final returns = await DBHelper.getAllPurchaseReturnInvoices();
    setState(() {
      _purchaseInvoices = purchases;
      _returnInvoices = returns;
      _isLoading = false;
    });
  }

  void _openInvoiceDetailsScreen(Invoice invoice, bool isReturn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseInvoiceDetailsScreen(
          invoice: invoice,
          isReturn: isReturn,
        ),
      ),
    );
  }

  // دالة التحقق من مطابقة تاريخ الفاتورة للفلتر الزمني المختار
  bool _isDateMatching(String dateStr) {
    try {
      final invoiceDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final invDay = DateTime(invoiceDate.year, invoiceDate.month, invoiceDate.day);

      if (_dateFilterType == 'today') {
        return invDay.isAtSameMomentAs(today);
      } else if (_dateFilterType == 'yesterday') {
        final yesterday = today.subtract(const Duration(days: 1));
        return invDay.isAtSameMomentAs(yesterday);
      } else if (_dateFilterType == 'week') {
        final weekAgo = today.subtract(const Duration(days: 7));
        return invDay.isAfter(weekAgo.subtract(const Duration(days: 1))) && invDay.isBefore(today.add(const Duration(days: 1)));
      } else if (_dateFilterType == 'month') {
        final monthAgo = today.subtract(const Duration(days: 30));
        return invDay.isAfter(monthAgo.subtract(const Duration(days: 1))) && invDay.isBefore(today.add(const Duration(days: 1)));
      } else if (_dateFilterType == 'year') {
        final yearAgo = today.subtract(const Duration(days: 365));
        return invDay.isAfter(yearAgo.subtract(const Duration(days: 1))) && invDay.isBefore(today.add(const Duration(days: 1)));
      } else if (_dateFilterType == 'custom' && _customDateRange != null) {
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day);
        return invDay.isAfter(start.subtract(const Duration(days: 1))) && invDay.isBefore(end.add(const Duration(days: 1)));
      }
      return true;
    } catch (e) {
      return true; // في حال كان تنسيق التاريخ مختلفاً يتم عرضه لتجنب إخفائه
    }
  }

  String _getFilterLabel() {
    switch (_dateFilterType) {
      case 'today': return 'اليوم';
      case 'yesterday': return 'أمس';
      case 'week': return 'خلال أسبوع';
      case 'month': return 'خلال شهر';
      case 'year': return 'خلال سنة';
      case 'custom': 
        if (_customDateRange != null) {
          return '${_customDateRange!.start.toString().split(' ')[0]} إلى ${_customDateRange!.end.toString().split(' ')[0]}';
        }
        return 'فترة مخصصة';
      default: return 'فلترة الوقت';
    }
  }

  @override
  Widget build(BuildContext context) {
    // تصفية قوائم المشتريات والمرتجعات بناءً على البحث والفلتر الزمني
    final filteredPurchases = _purchaseInvoices.where((inv) {
      final query = _searchQuery.toLowerCase();
      final idMatch = inv.id.toLowerCase().contains(query);
      final supplierMatch = (inv.customerName ?? '').toLowerCase().contains(query);
      final dateMatch = inv.date.toLowerCase().contains(query);
      
      final matchesSearch = idMatch || supplierMatch || dateMatch;
      final matchesDate = _isDateMatching(inv.date);

      return matchesSearch && matchesDate;
    }).toList();

    final filteredReturns = _returnInvoices.where((inv) {
      final query = _searchQuery.toLowerCase();
      final idMatch = inv.id.toLowerCase().contains(query);
      final supplierMatch = (inv.customerName ?? '').toLowerCase().contains(query);
      final dateMatch = inv.date.toLowerCase().contains(query);

      final matchesSearch = idMatch || supplierMatch || dateMatch;
      final matchesDate = _isDateMatching(inv.date);

      return matchesSearch && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل فواتير المشتريات والمرتجعات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المشتريات'),
            Tab(text: 'مرتجعات المشتريات'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // شريط البحث والفلترة الزمنية
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            labelText: 'بحث برقم الفاتورة، اسم المورد، أو التاريخ...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر قائمة الفلاتر الزمنية
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list, size: 28),
                        tooltip: 'فلترة حسب الوقت',
                        onSelected: (value) async {
                          if (value == 'custom') {
                            final pickedRange = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDateRange: _customDateRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now()),
                            );
                            if (pickedRange != null) {
                              setState(() {
                                _dateFilterType = 'custom';
                                _customDateRange = pickedRange;
                              });
                            }
                          } else {
                            setState(() {
                              _dateFilterType = value;
                              _customDateRange = null;
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'today',
                            child: Row(
                              children: [
                                Icon(Icons.today, color: _dateFilterType == 'today' ? Colors.blue : Colors.grey),
                                const SizedBox(width: 8),
                                const Text('اليوم'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'yesterday',
                            child: Row(
                              children: [
                                Icon(Icons.history, color: _dateFilterType == 'yesterday' ? Colors.blue : Colors.grey),
                                const SizedBox(width: 8),
                                const Text('أمس'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'week',
                            child: Row(
                              children: [
                                Icon(Icons.date_range, color: _dateFilterType == 'week' ? Colors.blue : Colors.grey),
                                const SizedBox(width: 8),
                                const Text('خلال أسبوع'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'month',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, color: _dateFilterType == 'month' ? Colors.blue : Colors.grey),
                                const SizedBox(width: 8),
                                const Text('خلال شهر'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'year',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_view_year, color: _dateFilterType == 'year' ? Colors.blue : Colors.grey),
                                const SizedBox(width: 8),
                                const Text('خلال سنة'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'custom',
                            child: Row(
                              children: [
                                Icon(Icons.edit_calendar, color: _dateFilterType == 'custom' ? Colors.blue : Colors.grey),
                                const SizedBox(width: 8),
                                const Text('فترة مخصصة...'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // مؤشر يوضح الفلتر الزمني الحالي النشط
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                  child: Row(
                    children: [
                      const Text('فلتر الوقت النشط: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Chip(
                        label: Text(_getFilterLabel(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.blue.shade50,
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() {
                            _dateFilterType = 'today';
                            _customDateRange = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      filteredPurchases.isEmpty
                          ? const Center(child: Text('لا توجد فواتير مشتريات مطابقة للبحث والفلتر الزمني'))
                          : ListView.builder(
                              itemCount: filteredPurchases.length,
                              itemBuilder: (ctx, index) {
                                final inv = filteredPurchases[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: ListTile(
                                    leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                                    title: Text('مورد: ${inv.customerName ?? "غير محدد"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('رقم الفاتورة: ${inv.id}\nالتاريخ: ${inv.date}\nالمبلغ: ${inv.totalAmount.toStringAsFixed(2)}'),
                                    isThreeLine: true,
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () => _openInvoiceDetailsScreen(inv, false),
                                  ),
                                );
                              },
                            ),
                      
                      filteredReturns.isEmpty
                          ? const Center(child: Text('لا توجد مرتجعات مشتريات مطابقة للبحث والفلتر الزمني'))
                          : ListView.builder(
                              itemCount: filteredReturns.length,
                              itemBuilder: (ctx, index) {
                                final inv = filteredReturns[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: ListTile(
                                    leading: const Icon(Icons.assignment_return, color: Colors.red),
                                    title: Text('مورد: ${inv.customerName ?? "غير محدد"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('رقم الفاتورة: ${inv.id}\nالتاريخ: ${inv.date}\nالمبلغ: ${inv.totalAmount.toStringAsFixed(2)}'),
                                    isThreeLine: true,
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () => _openInvoiceDetailsScreen(inv, true),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class PurchaseInvoiceDetailsScreen extends StatefulWidget {
  final Invoice invoice;
  final bool isReturn;

  const PurchaseInvoiceDetailsScreen({
    Key? key,
    required this.invoice,
    required this.isReturn,
  }) : super(key: key);

  @override
  State<PurchaseInvoiceDetailsScreen> createState() => _PurchaseInvoiceDetailsScreenState();
}

class _PurchaseInvoiceDetailsScreenState extends State<PurchaseInvoiceDetailsScreen> {
  List<InvoiceItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final fetchedItems = widget.isReturn
        ? await DBHelper.getPurchaseReturnInvoiceItems(widget.invoice.id)
        : await DBHelper.getPurchaseInvoiceItems(widget.invoice.id);
    setState(() {
      _items = fetchedItems;
      _isLoading = false;
    });
  }

  void _printInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري إرسال الفاتورة للطابعة الحرارية...')),
    );
  }

  void _shareInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري مشاركة تفاصيل الفاتورة...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReturn = widget.isReturn;
    final invoice = widget.invoice;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isReturn ? 'تفاصيل مرتجع المشتريات' : 'تفاصيل فاتورة المشتريات',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isReturn ? theme.colorScheme.error : theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'طباعة الفاتورة',
            onPressed: _printInvoice,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'مشاركة الفاتورة',
            onPressed: _shareInvoice,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('رقم الفاتورة: ${invoice.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('التاريخ: ${invoice.date}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('المورد: ${invoice.customerName ?? "غير محدد"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.primary)),
                      const SizedBox(height: 4),
                      Text('نوع الدفع: ${invoice.paymentType}', style: const TextStyle(fontSize: 14)),
                      if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('ملاحظات: ${invoice.notes}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('لا توجد أصناف مسجلة في هذه الفاتورة'))
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (ctx, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('الكمية: ${item.quantity} | سعر الوحدة: ${item.price}'),
                                trailing: Text(
                                  item.total.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isReturn ? theme.colorScheme.error : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي النهائي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        invoice.totalAmount.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: isReturn ? theme.colorScheme.error : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
