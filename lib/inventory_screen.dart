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
  bool _hasChanges = false; // لمتابعة ما إذا تم إضافة أو تعديل أي عنصر لتحديث الشاشة الرئيسية عند الرجوع

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

  // الانتقال إلى شاشة إضافة أو تعديل مجموعة (شاشة كاملة)
  void _navigateToCategoryForm({Category? category}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(category: category),
      ),
    );
    // إذا تم الحفظ أو التعديل، نقوم بتحديث البيانات
    if (result == true) {
      _loadData();
    }
  }

  // الانتقال إلى شاشة إضافة أو تعديل صنف (شاشة كاملة)
  void _navigateToProductForm({Product? product}) async {
    if (_categories.isEmpty && product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة مجموعة أولاً قبل إضافة صنف')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          product: product,
          categories: _categories,
        ),
      ),
    );
    // إذا تم الحفظ أو التعديل، نقوم بتحديث البيانات
    if (result == true) {
      _loadData();
    }
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
        onPressed: () => _navigateToCategoryForm(),
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
                          onPressed: () => _navigateToCategoryForm(category: cat),
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
        onPressed: () => _navigateToProductForm(),
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
                          onPressed: () => _navigateToProductForm(product: prod),
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

// ==================== شاشة إضافة / تعديل مجموعة (شاشة كاملة) ====================
class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  const CategoryFormScreen({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  late final TextEditingController _nameController;
  late String _selectedColorHex;
  late bool _isKitchenPrint;
  late bool _isActive;
  bool _dataChanged = false; // لتتبع ما إذا تم حفظ أي شيء للرجوع لتحديث الجدول

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
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColorHex = widget.category?.colorHex ?? '0xFF2196F3';
    _isKitchenPrint = widget.category?.isKitchenPrint ?? false;
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _dataChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل مجموعة' : 'إضافة مجموعة جديدة'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _dataChanged),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المجموعة *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('لون المجموعة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: _colorOptions.map((color) {
                  final colorHex = '0x${color.value.toRadixString(16).toUpperCase()}';
                  final isSelected = _selectedColorHex == colorHex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = colorHex),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 20,
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('طباعة المطبخ'),
                value: _isKitchenPrint,
                onChanged: (val) => setState(() => _isKitchenPrint = val),
              ),
              SwitchListTile(
                title: const Text('نشط (تظهر في نقطة البيع)'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) return;
                    
                    final cat = Category(
                      id: isEditing ? widget.category!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      colorHex: _selectedColorHex,
                      isKitchenPrint: _isKitchenPrint,
                      isActive: _isActive,
                    );
                    
                    await DBHelper.saveCategory(cat);
                    _dataChanged = true;

                    if (isEditing) {
                      // إذا كان تعديل، نحفظ ونخرج من الشاشة مباشرة
                      if (mounted) Navigator.pop(context, true);
                    } else {
                      // إذا كانت إضافة جديدة، نحفظ ونفرغ حقل الاسم ونبقي الشاشة لإضافة أخرى
                      _nameController.clear();
                      setState(() {
                        _isKitchenPrint = false;
                        _isActive = true;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم الحفظ بنجاح، يمكنك إضافة مجموعة أخرى'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'تحديث المجموعة' : 'حفظ وإضافة أخرى', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== شاشة إضافة / تعديل صنف (شاشة كاملة) ====================
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final List<Category> categories;

  const ProductFormScreen({Key? key, this.product, required this.categories}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _quantityController;
  late String _selectedCatId;
  late bool _isActive;
  bool _dataChanged = false; // لتتبع التحديثات

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _purchasePriceController = TextEditingController(text: widget.product?.purchasePrice.toString() ?? '0.0');
    _sellPriceController = TextEditingController(text: widget.product?.sellPrice.toString() ?? '0.0');
    _quantityController = TextEditingController(text: widget.product?.quantity.toString() ?? '0.0');
    _selectedCatId = widget.product?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : '');
    _isActive = widget.product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _dataChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل صنف' : 'إضافة صنف جديد'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _dataChanged),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الصنف *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCatId.isNotEmpty ? _selectedCatId : null,
                decoration: const InputDecoration(
                  labelText: 'المجموعة *',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCatId = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر الشراء',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sellPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر البيع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الكمية الحالية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('نشط (تظهر في نقطة البيع)'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty || _selectedCatId.isEmpty) return;
                    
                    final prod = Product(
                      id: isEditing ? widget.product!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      categoryId: _selectedCatId,
                      purchasePrice: double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
                      sellPrice: double.tryParse(_sellPriceController.text.trim()) ?? 0.0,
                      quantity: double.tryParse(_quantityController.text.trim()) ?? 0.0,
                      isActive: _isActive,
                    );
                    
                    await DBHelper.saveProduct(prod);
                    _dataChanged = true;

                    if (isEditing) {
                      // إذا كان تعديل، نحفظ ونخرج من الشاشة مباشرة
                      if (mounted) Navigator.pop(context, true);
                    } else {
                      // إذا كانت إضافة جديدة، نحفظ ونفرغ الحقول ونبقي الشاشة لإضافة صنف تالي
                      _nameController.clear();
                      _purchasePriceController.text = '0.0';
                      _sellPriceController.text = '0.0';
                      _quantityController.text = '0.0';
                      setState(() {
                        _isActive = true;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم الحفظ بنجاح، يمكنك إضافة صنف آخر'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'تحديث الصنف' : 'حفظ وإضافة صنف آخر', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
