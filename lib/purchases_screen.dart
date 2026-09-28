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
        title: Text(_isReturnMode ? 'اختر المورد للمرتجع' : 'اختيار مورد'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: Icon(Icons.person, color: theme.colorScheme.secondary),
                title: const Text('مشتريات نقدية / عامة', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('بدون تحديد حساب مورد معين'),
                onTap: () {
                  setState(() {
                    _selectedSupplier = null;
                    _supplierController.text = 'مشتريات نقدية / عامة';
                  });
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              if (_suppliers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('لا يوجد موردين مسجلين حالياً', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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

  // توليد رقم تسلسلي مستقل يبدأ من 1 (تم تصحيح طريقة الاستعلام لتتطابق مع الـ SQLite بدون أخطاء)
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

      if (_isReturnMode) {
        final String invoiceId = await _generateSequentialId(true);
        final supplierNameText = _selectedSupplier?.name ?? 'مشتريات نقدية / عامة';

        await db.insert('purchase_return_invoices', {
          'id': invoiceId,
          'invoiceType': 'purchase_return',
          'paymentType': _selectedSupplier == null ? 'cash' : 'credit',
          'totalAmount': _finalTotal,
          'date': currentDate,
          'supplierId': _selectedSupplier?.id,
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

        if (_selectedSupplier != null) {
          await DBHelper.addSupplierTransaction(
            supplierId: _selectedSupplier!.id,
            type: 'مرتجع مشتريات',
            credit: 0.0,
            debit: _finalTotal,
            date: currentDate,
            notes: 'مرتجع مشتريات رقم: $invoiceId',
          );
        }

        _finishInvoiceProcess('تم حفظ مرتجع المشتريات برقم ($invoiceId) بنجاح');
      } else {
        final String invoiceId = await _generateSequentialId(false);
        final supplierNameText = _selectedSupplier?.name ?? 'مشتريات نقدية / عامة';

        await db.insert('purchase_invoices', {
          'id': invoiceId,
          'invoiceType': 'purchase',
          'paymentType': _selectedSupplier == null ? 'cash' : 'credit',
          'totalAmount': _finalTotal,
          'date': currentDate,
          'supplierId': _selectedSupplier?.id,
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

        if (_selectedSupplier != null) {
          await DBHelper.addSupplierTransaction(
            supplierId: _selectedSupplier!.id,
            type: 'فاتورة مشتريات',
            credit: _finalTotal,
            debit: 0.0,
            date: currentDate,
            notes: 'فاتورة مشتريات رقم: $invoiceId',
          );
        }

        _finishInvoiceProcess('تم حفظ فاتورة المشتريات برقم ($invoiceId) بنجاح');
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
                            hintText: 'اضغط للبحث عن مورد...',
                            labelText: _isReturnMode ? 'المورد المرجّع له' : 'المورد',
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

  void _showInvoiceDetails(Invoice invoice, bool isReturn) async {
    final items = isReturn 
        ? await DBHelper.getPurchaseReturnInvoiceItems(invoice.id)
        : await DBHelper.getPurchaseInvoiceItems(invoice.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isReturn ? 'تفاصيل مرتجع المشتريات' : 'تفاصيل فاتورة المشتريات'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('رقم الفاتورة: ${invoice.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('التاريخ: ${invoice.date}'),
                const SizedBox(height: 4),
                Text('المورد: ${invoice.customerName ?? "مشتريات نقدية / عامة"}'),
                const SizedBox(height: 4),
                Text('نوع الدفع: ${invoice.paymentType}'),
                const SizedBox(height: 4),
                Text('ملاحظات: ${invoice.notes}'),
                const Divider(height: 20, thickness: 2),
                const Text('الأصناف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                
                ...items.map((item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الكمية: ${item.quantity} | السعر: ${item.price}'),
                    trailing: Text('${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
                
                const Divider(height: 20, thickness: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإجمالي النهائي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${invoice.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          : TabBarView(
              controller: _tabController,
              children: [
                _purchaseInvoices.isEmpty
                    ? const Center(child: Text('لا توجد فواتير مشتريات مسجلة'))
                    : ListView.builder(
                        itemCount: _purchaseInvoices.length,
                        itemBuilder: (ctx, index) {
                          final inv = _purchaseInvoices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                              title: Text('مورد: ${inv.customerName ?? "مشتريات نقدية / عامة"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('رقم الفاتورة: ${inv.id}\nالتاريخ: ${inv.date}\nالمبلغ: ${inv.totalAmount.toStringAsFixed(2)}'),
                              isThreeLine: true,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _showInvoiceDetails(inv, false),
                            ),
                          );
                        },
                      ),
                
                _returnInvoices.isEmpty
                    ? const Center(child: Text('لا توجد مرتجعات مشتريات مسجلة'))
                    : ListView.builder(
                        itemCount: _returnInvoices.length,
                        itemBuilder: (ctx, index) {
                          final inv = _returnInvoices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.assignment_return, color: Colors.red),
                              title: Text('مورد: ${inv.customerName ?? "مشتريات نقدية / عامة"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('رقم الفاتورة: ${inv.id}\nالتاريخ: ${inv.date}\nالمبلغ: ${inv.totalAmount.toStringAsFixed(2)}'),
                              isThreeLine: true,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _showInvoiceDetails(inv, true),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
