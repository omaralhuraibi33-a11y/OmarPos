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
                leading: const Icon(Icons.person, color: Colors.orange),
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
                leading: const Icon(Icons.business, color: Colors.blue),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isReturnMode ? Colors.red.shade700 : Colors.blue.shade700,
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

  Future<void> _savePurchaseProcess() async {
    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة أصناف أولاً قبل الحفظ')),
      );
      return;
    }

    if (_isReturnMode) {
      // مرتجع مشتريات: خصم من المخزن
      for (var item in _purchaseItems) {
        await DBHelper.updateProductStock(item.product.id, -item.quantity);
      }

      // خصم من مستحقات المورد تلقائياً
      if (_selectedSupplier != null) {
        await DBHelper.addSupplierTransaction(
          supplierId: _selectedSupplier!.id,
          type: 'مرتجع مشتريات',
          credit: 0.0,
          debit: _finalTotal,
        );
      }

      _finishInvoiceProcess('تم حفظ مرتجع المشتريات وتقييده بنجاح');
    } else {
      // فاتورة مشتريات: زيادة المخزن وتحديث سعر الشراء
      for (var item in _purchaseItems) {
        await DBHelper.updateProductStock(item.product.id, item.quantity);

        if (item.purchasePrice != item.product.purchasePrice) {
          item.product.purchasePrice = item.purchasePrice;
          await DBHelper.saveProduct(item.product);
        }
      }

      // إثبات دائن للمورد تلقائياً
      if (_selectedSupplier != null) {
        await DBHelper.addSupplierTransaction(
          supplierId: _selectedSupplier!.id,
          type: 'فاتورة مشتريات',
          credit: _finalTotal,
          debit: 0.0,
        );
      }

      _finishInvoiceProcess('تم حفظ فاتورة المشتريات وتحديث المخزون بنجاح');
    }
  }

  void _finishInvoiceProcess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _isReturnMode ? Colors.red.shade800 : Colors.green.shade700,
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
        backgroundColor: _isReturnMode ? Colors.red.shade800 : Colors.blue.shade800,
        title: Text(
          _isReturnMode ? 'مرتجع مشتريات' : 'فاتورة المشتريات',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isReturnMode ? Colors.blue.shade700 : Colors.red.shade700,
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
                  color: Colors.grey.shade100,
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
                              icon: const Icon(Icons.search, color: Colors.blue, size: 28),
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
                          decoration: const InputDecoration(
                            labelText: 'خصم الفاتورة',
                            prefixIcon: Icon(Icons.discount, color: Colors.orange),
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
                              backgroundColor: _isReturnMode ? Colors.red.shade700 : Colors.blue.shade700,
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
                                subtitle: Text('الكمية: ${item.quantity} | السعر: ${item.purchasePrice} | الخصم: ${item.discount}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _isReturnMode ? Colors.red.shade900 : Colors.blue.shade900,
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
                            '${_finalTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _isReturnMode ? Colors.red.shade800 : Colors.green.shade800,
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
                                backgroundColor: Colors.orange.shade800,
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
                              backgroundColor: Colors.blue.shade700,
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
                                backgroundColor: _isReturnMode ? Colors.red.shade800 : Colors.green.shade700,
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
