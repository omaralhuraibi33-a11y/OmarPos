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
  final TextEditingController _notesController = TextEditingController();

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
      _notesController.clear();
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

  // ==================== حفظ فاتورة المشتريات أو المرتجع في الجداول المستقلة ====================
  Future<void> _savePurchaseProcess() async {
    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة أصناف أولاً قبل الحفظ')),
      );
      return;
    }

    final invoiceId = 'PUR_${DateTime.now().millisecondsSinceEpoch}';
    final nowStr = DateTime.now().toString().split('.')[0];
    final shiftId = await DBHelper.getCurrentShiftId();

    if (_isReturnMode) {
      // 1. حفظ فاتورة مرتجع المشتريات الأساسية في جدول purchase_return_invoices
      final returnInvoice = Invoice(
        id: invoiceId,
        invoiceType: 'purchase_return',
        paymentType: _selectedSupplier != null ? 'credit' : 'cash',
        totalAmount: _finalTotal,
        date: nowStr,
        supplierId: _selectedSupplier?.id,
        supplierName: _selectedSupplier?.name ?? 'مورد نقدي / عام',
        notes: _notesController.text,
        shiftId: shiftId,
      );

      await DBHelper.savePurchaseReturnInvoice(returnInvoice);

      // 2. حفظ الأصناف وتخفيض المخزون
      for (var item in _purchaseItems) {
        final retItem = InvoiceItem(
          id: '${invoiceId}_${item.product.id}',
          invoiceId: invoiceId,
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          price: item.purchasePrice,
          total: item.total,
        );
        await DBHelper.savePurchaseReturnInvoiceItem(retItem);
        await DBHelper.updateProductStock(item.product.id, -item.quantity);
      }

      _finishInvoiceProcess('تم حفظ وطباعة مرتجع المشتريات وتقييده بنجاح');
    } else {
      // 1. حفظ فاتورة المشتريات الأساسية في جدول purchase_invoices
      final purchaseInvoice = Invoice(
        id: invoiceId,
        invoiceType: 'purchase',
        paymentType: _selectedSupplier != null ? 'credit' : 'cash',
        totalAmount: _finalTotal,
        date: nowStr,
        supplierId: _selectedSupplier?.id,
        supplierName: _selectedSupplier?.name ?? 'مشتريات نقدية / عامة',
        notes: _notesController.text,
        shiftId: shiftId,
      );

      await DBHelper.savePurchaseInvoice(purchaseInvoice);

      // 2. حفظ الأصناف، زيادة المخزون، وتحديث سعر الشراء إن تغير
      for (var item in _purchaseItems) {
        final purItem = InvoiceItem(
          id: '${invoiceId}_${item.product.id}',
          invoiceId: invoiceId,
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          price: item.purchasePrice,
          total: item.total,
        );
        await DBHelper.savePurchaseInvoiceItem(purItem);
        
        await DBHelper.updateProductStock(item.product.id, item.quantity);

        if (item.purchasePrice != item.product.purchasePrice) {
          item.product.purchasePrice = item.purchasePrice;
          await DBHelper.saveProduct(item.product);
        }
      }

      _finishInvoiceProcess('تم حفظ فاتورة المشتريات وتحديث المخزون بنجاح');
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
    _loadData();
  }

  // ==================== شاشة سجل الفواتير (مثل سجل المبيعات) ====================
  void _openPurchasesHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PurchasesHistoryScreen(),
      ),
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
          // زر الانتقال لسجل المشتريات
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'سجل الفواتير',
            onPressed: _openPurchasesHistory,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isReturnMode ? theme.colorScheme.primary : theme.colorScheme.error,
              elevation: 0,
            ),
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

// ==================== شاشة سجل المشتريات والمرتجعات ====================
class PurchasesHistoryScreen extends StatefulWidget {
  const PurchasesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesHistoryScreen> createState() => _PurchasesHistoryScreenState();
}

class _PurchasesHistoryScreenState extends State<PurchasesHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Invoice> _purchaseInvoices = [];
  List<Invoice> _returnInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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
        title: Text(isReturn ? 'تفاصيل مرتجع مشتريات #${invoice.id}' : 'تفاصيل فاتورة مشتريات #${invoice.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('التاريخ: ${invoice.date}'),
              Text('المورد: ${invoice.supplierName ?? "غير محدد"}'),
              Text('نوع الدفع: ${invoice.paymentType}'),
              const Divider(),
              const Text('الأصناف:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      dense: true,
                      title: Text(item.productName),
                      subtitle: Text('الكمية: ${item.quantity} × السعر: ${item.price}'),
                      trailing: Text('${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي النهائي:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${invoice.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                ],
              ),
            ],
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
        title: const Text('سجل المشتريات والمرتجعات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'فواتير المشتريات'),
            Tab(text: 'مرتجعات المشتريات'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // فواتير الشراء
                _purchaseInvoices.isEmpty
                    ? const Center(child: Text('لا توجد فواتير مشتريات مسجلة'))
                    : ListView.builder(
                        itemCount: _purchaseInvoices.length,
                        itemBuilder: (context, index) {
                          final inv = _purchaseInvoices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const Icon(Icons.receipt_long, color: Colors.blue),
                              title: Text('المورد: ${inv.supplierName ?? "نقدي"}'),
                              subtitle: Text('التاريخ: ${inv.date}\nالمبلغ: ${inv.totalAmount.toStringAsFixed(2)}'),
                              isThreeLine: true,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _showInvoiceDetails(inv, false),
                            ),
                          );
                        },
                      ),
                // مرتجعات الشراء
                _returnInvoices.isEmpty
                    ? const Center(child: Text('لا توجد مرتجعات مشتريات مسجلة'))
                    : ListView.builder(
                        itemCount: _returnInvoices.length,
                        itemBuilder: (context, index) {
                          final inv = _returnInvoices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const Icon(Icons.assignment_return, color: Colors.red),
                              title: Text('المورد: ${inv.supplierName ?? "نقدي"}'),
                              subtitle: Text('التاريخ: ${inv.date}\nالمبلغ: ${inv.totalAmount.toStringAsFixed(2)}'),
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
