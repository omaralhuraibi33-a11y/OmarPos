import 'package:flutter/material.dart';
import 'db_helper.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;

  // ألوان جاهزة لاختيار لون المجموعة
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await DBHelper.getAllCategories();
    final prods = await DBHelper.getAllProducts();
    setState(() {
      _categories = cats;
      _products = prods;
      _isLoading = false;
    });
  }

  // ==================== 1. إدارة المجموعات ====================
  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedColorHex = category?.colorHex ?? '0xFF2196F3';
    bool isKitchenPrint = category?.isKitchenPrint ?? false;
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'تعديل مجموعة' : 'إضافة مجموعة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المجموعة *'),
                ),
                const SizedBox(height: 15),
                const Text('لون المجموعة:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _colorOptions.map((color) {
                    final colorHex = '0x${color.value.toRadixString(16).toUpperCase()}';
                    final isSelected = selectedColorHex == colorHex;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColorHex = colorHex);
                      },
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 18,
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
                SwitchListTile(
                  title: const Text('طباعة المطبخ'),
                  value: isKitchenPrint,
                  onChanged: (val) => setDialogState(() => isKitchenPrint = val),
                ),
                SwitchListTile(
                  title: const Text('نشط (تظهر في نقطة البيع)'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final cat = Category(
                  id: isEditing ? category.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  colorHex: selectedColorHex,
                  isKitchenPrint: isKitchenPrint,
                  isActive: isActive,
                );
                await DBHelper.saveCategory(cat);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: Text(isEditing ? 'تحديث' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 2. إدارة الأصناف ====================
  void _showProductDialog({Product? product}) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final purchasePriceController = TextEditingController(text: product?.purchasePrice.toString() ?? '0.0');
    final sellPriceController = TextEditingController(text: product?.sellPrice.toString() ?? '0.0');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '0.0');
    String selectedCatId = product?.categoryId ?? (_categories.isNotEmpty ? _categories.first.id : '');
    bool isActive = product?.isActive ?? true;

    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة مجموعة أولاً قبل إضافة صنف')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'تعديل صنف' : 'إضافة صنف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الصنف *'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCatId.isNotEmpty ? selectedCatId : null,
                  decoration: const InputDecoration(labelText: 'المجموعة *'),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCatId = val);
                  },
                ),
                TextField(
                  controller: purchasePriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر الشراء'),
                ),
                TextField(
                  controller: sellPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر البيع'),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية الحالية'),
                ),
                SwitchListTile(
                  title: const Text('نشط (تظهر في نقطة البيع)'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || selectedCatId.isEmpty) return;
                final prod = Product(
                  id: isEditing ? product.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  categoryId: selectedCatId,
                  purchasePrice: double.tryParse(purchasePriceController.text.trim()) ?? 0.0,
                  sellPrice: double.tryParse(sellPriceController.text.trim()) ?? 0.0,
                  quantity: double.tryParse(quantityController.text.trim()) ?? 0.0,
                  isActive: isActive,
                );
                await DBHelper.saveProduct(prod);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: Text(isEditing ? 'تحديث' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المخزن'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.category), text: 'إدارة المجموعات'),
              Tab(icon: Icon(Icons.fastfood), text: 'إدارة الأصناف'),
              Tab(icon: Icon(Icons.inventory_2), text: 'جرد المخزن'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildCategoriesTab(),
                  _buildProductsTab(),
                  _buildStockTab(),
                ],
              ),
      ),
    );
  }

  // التبويب الأول: المجموعات
  Widget _buildCategoriesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: _categories.isEmpty
          ? const Center(child: Text('لا توجد مجموعات أضف واحدة بضغط +'))
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (ctx, index) {
                final cat = _categories[index];
                final color = Color(int.parse(cat.colorHex));
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: color),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('طباعة مطبخ: ${cat.isKitchenPrint ? "نعم" : "لا"} | الظهور بـ POS: ${cat.isActive ? "نشط" : "غير نشط"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showCategoryDialog(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DBHelper.deleteCategory(cat.id);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // التبويب الثاني: الأصناف
  Widget _buildProductsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add),
      ),
      body: _products.isEmpty
          ? const Center(child: Text('لا توجد أصناف أضف صنف بضغط +'))
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (ctx, index) {
                final prod = _products[index];
                final catName = _categories.firstWhere((c) => c.id == prod.categoryId, orElse: () => Category(id: '', name: 'بدون مجموعة')).name;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المجموعة: $catName\nشراء: ${prod.purchasePrice} | بيع: ${prod.sellPrice}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: prod.isActive ? Colors.green : Colors.grey, size: 14),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showProductDialog(product: prod),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DBHelper.deleteProduct(prod.id);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // التبويب الثالث: جرد المخزن
  Widget _buildStockTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('اسم الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('المجموعة', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _products.map((p) {
          final catName = _categories.firstWhere((c) => c.id == p.categoryId, orElse: () => Category(id: '', name: '-')).name;
          return DataRow(cells: [
            DataCell(Text(p.name)),
            DataCell(Text(catName)),
            DataCell(Text(
              '${p.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: p.quantity <= 0 ? Colors.red : Colors.green.shade800,
              ),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
