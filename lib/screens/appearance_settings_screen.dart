import 'package:flutter/material.dart';
import 'db_helper.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<Color>? onColorChanged;

  const AppearanceSettingsScreen({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.onColorChanged,
  }) : super(key: key);

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  String _mainButtonSize = 'وسط';
  String _posItemSize = 'وسط';
  late bool _currentIsDarkMode;

  // اللون الرئيسي المختار للنظام
  Color _selectedPrimaryColor = Colors.blue;

  // قائمة الألوان المتاحة لاختيار واجهات النظام
  final List<Color> _systemColors = [
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blueGrey,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _currentIsDarkMode = widget.isDarkMode;
    _loadSavedSettings();
  }

  // تحميل الإعدادات المحفوظة من قاعدة البيانات
  Future<void> _loadSavedSettings() async {
    final savedColorVal = await DBHelper.getSetting('theme_color');
    final savedMainBtn = await DBHelper.getSetting('main_button_size');
    final savedPosItem = await DBHelper.getSetting('pos_item_size');
    final savedThemeMode = await DBHelper.getSetting('is_dark_mode');

    if (mounted) {
      setState(() {
        if (savedColorVal != null) {
          _selectedPrimaryColor = Color(int.parse(savedColorVal));
        }
        if (savedMainBtn != null) {
          _mainButtonSize = savedMainBtn;
        }
        if (savedPosItem != null) {
          _posItemSize = savedPosItem;
        }
        if (savedThemeMode != null) {
          _currentIsDarkMode = savedThemeMode == 'true';
        }
      });
    }
  }

  // حفظ الإعدادات في قاعدة البيانات مع استخدام toARGB32 لتفادي تحذيرات الإصدارات الحديثة
  Future<void> _saveSettings() async {
    await DBHelper.saveSetting('theme_color', _selectedPrimaryColor.toARGB32().toString());
    await DBHelper.saveSetting('main_button_size', _mainButtonSize);
    await DBHelper.saveSetting('pos_item_size', _posItemSize);
    await DBHelper.saveSetting('is_dark_mode', _currentIsDarkMode.toString());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إعدادات المظهر بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryThemeColor = _selectedPrimaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات المظهر'),
        backgroundColor: primaryThemeColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'نمط المظهر العام',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_currentIsDarkMode ? primaryThemeColor : Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIsDarkMode = false;
                    });
                    widget.onThemeChanged(false);
                  },
                  icon: const Icon(Icons.wb_sunny, color: Colors.white),
                  label: const Text('وضع فاتح', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentIsDarkMode ? primaryThemeColor : Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIsDarkMode = true;
                    });
                    widget.onThemeChanged(true);
                  },
                  icon: const Icon(Icons.nightlight_round, color: Colors.white),
                  label: const Text('وضع داكن', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // قسم تغيير ألوان واجهات النظام
          const Text(
            'لون واجهات النظام الرئيسية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: _systemColors.map((color) {
              final isSelected = _selectedPrimaryColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPrimaryColor = color;
                  });
                  if (widget.onColorChanged != null) {
                    widget.onColorChanged!(color);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }).toList(),
          ),

          const Divider(height: 30),
          const Text(
            'حجم الأزرار والعرض',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _mainButtonSize,
            decoration: const InputDecoration(
              labelText: 'حجم أزرار الشاشة الرئيسية',
              border: OutlineInputBorder(),
            ),
            items: ['صغير', 'وسط', 'كبير']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => _mainButtonSize = val!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _posItemSize,
            decoration: const InputDecoration(
              labelText: 'حجم أصناف كروت نقطة البيع (POS)',
              border: OutlineInputBorder(),
            ),
            items: ['صغير', 'وسط', 'كبير']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => _posItemSize = val!),
          ),

          const SizedBox(height: 30),

          // زر حفظ الإعدادات
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryThemeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.save),
              label: const Text(
                'حفظ الإعدادات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _saveSettings,
            ),
          ),
        ],
      ),
    );
  }
}
