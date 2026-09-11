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
  final List<PurchaseItem> _purchaseItems = [];

  final TextEditingController _supplierController = TextEditingController(text: 'مورد عام');
  final TextEditingController _invoiceDiscountController = TextEditingController(text: '0.0');

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final prods = await DBHelper.getAllProducts();
    setState(() {
      _allProducts = prods;
      _isLoading = false;
    });
  }

  double get _subTotal => _purchaseItems.fold(0.0, (sum, item) => sum + item.total);
  double get _invoiceDiscount => double.tryParse(_invoiceDiscountController.text.trim()) ?? 0.0;
  double get _finalTotal => (_subTotal - _invoiceDiscount) < 0 ? 0.0 : (_subTotal - _invoiceDiscount);

  void _resetInvoice() {
    setState(() {
      _purchaseItems.clear();
      _supplierController.text = 'مورد عام';
      _invoiceDiscountController.text = '0.0';
    });
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
          title: const Text('إضافة صنف للفاتورة'),
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
                  decoration: const InputDecoration(labelText: 'الكمية المشتراة *'),
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
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchaseInvoice() async {
    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة أصناف أولاً قبل الحفظ')),
      );
      return;
    }

    // زيادة كميات الأصناف في قاعدة البيانات + تحديث سعر الشراء الجديد
    for (var item in _purchaseItems) {
      await DBHelper.updateProductStock(item.product.id, item.quantity);

      // تحديث سعر الشراء للصنف إذا تغير
      if (item.purchasePrice != item.product.purchasePrice) {
        item.product.purchasePrice = item.purchasePrice;
        await DBHelper.saveProduct(item.product);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ فاتورة المشتريات وتحديث كميات المخزن بنجاح! الإجمالي: $_finalTotal')),
      );
      _resetInvoice();
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة المشتريات'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // رأس الفاتورة: المورد والخصم
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _supplierController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المورد',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

                // جدول الأصناف المضافة
                Expanded(
                  child: _purchaseItems.isEmpty
                      ? Center(
                          child: ElevatedButton.icon(
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('اضغط هنا لإضافة أصناف للفاتورة'),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
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

                // المجموع والشريط السفلي
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
                          const Text('الصافي النهائي:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '${_finalTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
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
                              label: const Text('فاتورة جديدة'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('إضافة صنف'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _savePurchaseInvoice,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text('حفظ الفاتورة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
