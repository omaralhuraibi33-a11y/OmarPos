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

  final TextEditingController _supplierController = TextEditingController(text: 'اختيار مورد (آجل افتراضياً)');
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
      _supplierController.text = 'اختيار مورد (آجل افتراضياً)';
      _invoiceDiscountController.text = '0.0';
    });
  }

  void _showSelectSupplierDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isReturnMode ? 'اختر المورد المراد إرجاع البضاعة له' : 'اختر المورد (الحساب الآجل)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.person_pin, color: Colors.orange),
                title: const Text('مشتريات نقدية عابرة', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('تسجيل حساب عام للمشتريات السريعة'),
                onTap: () {
                  setState(() {
                    _selectedSupplier = null;
                    _supplierController.text = 'مشتريات نقدية عابرة (آجل)';
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
                leading: const Icon(Icons.business, color: Colors.blue),
                title: Text(sup.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('الرصيد المستحق له: ${sup.balance.toStringAsFixed(2)}'),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    if (_allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أصناف بالمخزن. أضف أصنافاً من شاشة المخزن أولاً')),
      );
      return;
    }

    Product selectedProduct = _allProducts.first;
    final quantityController = TextEditingController(text: '1.0');
    final priceController = TextEditingController(text: selectedProduct.purchasePrice.toString());
    final discountController = TextEditingController(text: '0.0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_isReturnMode ? 'إضافة صنف لإرجاعه للمورد' : 'إضافة صنف للفاتورة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  decoration: const InputDecoration(labelText: 'اختر الصنف *'),
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
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _isReturnMode ? 'الكمية المرجعة *' : 'الكمية المشتراة *',
                  ),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'سعر الشراء الفردي *'),
                ),
                TextField(
                  controller: discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'خصم الصنف (إن وجد)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isReturnMode ? Colors.red.shade800 : Colors.blue,
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
              child: const Text('إضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchaseProcess() async {
    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة أصناف أولاً قبل الحفظ')),
      );
      return;
    }

    if (_isReturnMode) {
      // 1. معالجة مرتجع المشتريات: خصم من كميات المخزن
      for (var item in _purchaseItems) {
        await DBHelper.updateProductStock(item.product.id, -item.quantity);
      }

      // 2. تخصيم المستحق للمورد (مدين لصالح المورد لتقليل دينه)
      if (_selectedSupplier != null) {
        await DBHelper.addSupplierTransaction(
          supplierId: _selectedSupplier!.id,
          type: 'مرتجع مشتريات',
          credit: 0.0,
          debit: _finalTotal,
        );
      }

      if (mounted) {
        _showReceiptVoucherDialog();
      }
    } else {
      // 1. معالجة الفاتورة العادية: إضافة للكميات وتحديث السعر
      for (var item in _purchaseItems) {
        await DBHelper.updateProductStock(item.product.id, item.quantity);

        if (item.purchasePrice != item.product.purchasePrice) {
          item.product.purchasePrice = item.purchasePrice;
          await DBHelper.saveProduct(item.product);
        }
      }

      // 2. إثبات دائن للمورد (استحقاق آجل)
      if (_selectedSupplier != null) {
        await DBHelper.addSupplierTransaction(
          supplierId: _selectedSupplier!.id,
          type: 'فاتورة مشتريات (آجل)',
          credit: _finalTotal,
          debit: 0.0,
        );
      }

      if (mounted) {
        _showPaymentVoucherDialog();
      }
    }
  }

  // نافذة إصدار سند صرف (عند الشراء العادي)
  void _showPaymentVoucherDialog() {
    String paymentSource = 'الصندوق الرئيسي (نقدي)';
    final paidAmountController = TextEditingController(text: _finalTotal.toStringAsFixed(2));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('تم تثبيت الفاتورة (آجل) بنجاح'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('هل تريد تحرير "سند صرف" وسداد المبلغ أو جزء منه الآن؟'),
              const SizedBox(height: 12),
              TextField(
                controller: paidAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع بالسند',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: paymentSource,
                decoration: const InputDecoration(labelText: 'طريقة الصرف / الخزينة', border: OutlineInputBorder()),
                items: ['الصندوق الرئيسي (نقدي)', 'البنك / الحساب البنكي', 'شبكة / محفظة']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setDlgState(() => paymentSource = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _finishInvoiceProcess('تم حفظ الفاتورة كـ (آجل) بدون سداد مقدماً.');
              },
              child: const Text('إبقاء الفاتورة آجل بالكامل'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              label: const Text('إصدار سند الصرف', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final paid = double.tryParse(paidAmountController.text.trim()) ?? 0.0;
                if (paid > 0 && _selectedSupplier != null) {
                  await DBHelper.addSupplierTransaction(
                    supplierId: _selectedSupplier!.id,
                    type: 'سند صرف ($paymentSource)',
                    credit: 0.0,
                    debit: paid,
                  );
                }
                Navigator.pop(ctx);
                _finishInvoiceProcess('تم حفظ الفاتورة وتوليد سند الصرف بقيمة $paid بنجاح!');
              },
            ),
          ],
        ),
      ),
    );
  }

  // نافذة إصدار سند قبض (عند مرتجع المشتريات)
  void _showReceiptVoucherDialog() {
    String receiptSource = 'الصندوق الرئيسي (نقدي)';
    final receivedAmountController = TextEditingController(text: _finalTotal.toStringAsFixed(2));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('تم حفظ مرتجع المشتريات بنجاح'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('هل استلمت المبلغ المرتجع نقدياً/بنكياً وتريد تحرير "سند قبض"؟'),
              const SizedBox(height: 12),
              TextField(
                controller: receivedAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المستلم',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: receiptSource,
                decoration: const InputDecoration(labelText: 'حساب الإيداع / الخزينة', border: OutlineInputBorder()),
                items: ['الصندوق الرئيسي (نقدي)', 'البنك / الحساب البنكي', 'شبكة / محفظة']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setDlgState(() => receiptSource = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _finishInvoiceProcess('تم تقييد المرتجع كـ خصم من حساب المورد الآجل.');
              },
              child: const Text('تخفيض حساب المورد فقط'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
              icon: const Icon(Icons.receipt, color: Colors.white),
              label: const Text('إصدار سند القبض', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final amount = double.tryParse(receivedAmountController.text.trim()) ?? 0.0;
                if (amount > 0 && _selectedSupplier != null) {
                  await DBHelper.addSupplierTransaction(
                    supplierId: _selectedSupplier!.id,
                    type: 'سند قبض ($receiptSource)',
                    credit: amount,
                    debit: 0.0,
                  );
                }
                Navigator.pop(ctx);
                _finishInvoiceProcess('تم حفظ المرتجع وتوليد سند قبض بقيمة $amount بنجاح!');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _finishInvoiceProcess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _isReturnMode ? Colors.red.shade800 : Colors.green,
      ),
    );
    _resetInvoice();
    if (_isReturnMode) {
      setState(() => _isReturnMode = false);
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isReturnMode ? Colors.red.shade900 : null,
        title: Text(_isReturnMode ? 'مرتجع مشتريات' : 'فاتورة المشتريات'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: Icon(_isReturnMode ? Icons.shopping_bag : Icons.assignment_return),
            label: Text(_isReturnMode ? 'فاتورة جديدة' : 'مرتجع'),
            onPressed: () {
              setState(() {
                _isReturnMode = !_isReturnMode;
                _resetInvoice();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: _isReturnMode ? Colors.red.shade50 : Colors.blue.shade50,
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
                            labelText: _isReturnMode ? 'المورد المرجّع له' : 'المورد (آجل تلقائياً)',
                            prefixIcon: Icon(_isReturnMode ? Icons.assignment_return : Icons.business),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.blue),
                              onPressed: _showSelectSupplierDialog,
                              tooltip: 'اختيار مورد',
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
                          decoration: const InputDecoration(
                            labelText: 'خصم الفاتورة',
                            prefixIcon: Icon(Icons.discount),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                              backgroundColor: _isReturnMode ? Colors.red.shade800 : null,
                            ),
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(
                              _isReturnMode ? 'اضغط لإضافة أصناف مرجعة' : 'اضغط هنا لإضافة أصناف للفاتورة',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _purchaseItems.length,
                          itemBuilder: (ctx, index) {
                            final item = _purchaseItems[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: ListTile(
                                title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('الكمية: ${item.quantity} | السعر: ${item.purchasePrice} | خصم الصنف: ${item.discount}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: _isReturnMode ? Colors.red.shade900 : Colors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
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
                  color: Colors.grey.shade200,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المجموع الفرعي: ${_subTotal.toStringAsFixed(2)}'),
                          Text('خصم الفاتورة: ${_invoiceDiscount.toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isReturnMode ? 'صافي المرتجع:' : 'الصافي النهائي:',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_finalTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isReturnMode ? Colors.red.shade900 : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                              onPressed: _resetInvoice,
                              icon: const Icon(Icons.refresh),
                              label: Text(_isReturnMode ? 'تفريغ المرتجع' : 'فاتورة جديدة'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isReturnMode ? Colors.red.shade800 : null,
                            ),
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                            label: const Text('إضافة صنف', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isReturnMode ? Colors.red.shade900 : Colors.green.shade700,
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
