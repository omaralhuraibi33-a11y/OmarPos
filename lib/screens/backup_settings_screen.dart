import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'db_helper.dart'; // تأكد من مسار ملف DBHelper في مشروعك

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  String? _customFolderPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadCustomPath();
  }

  /// قراءة مسار المجلد المحفوظ سابقاً
  Future<void> _loadCustomPath() async {
    final path = await DBHelper.getSetting('backup_folder_path');
    if (path != null && path.isNotEmpty) {
      setState(() => _customFolderPath = path);
    } else {
      final defaultDir = await _getDefaultBackupDirectory();
      setState(() => _customFolderPath = defaultDir.path);
    }
  }

  /// الحصول على المجلد الافتراضي باسم النظام (OmarPOS_Backups)
  Future<Directory> _getDefaultBackupDirectory() async {
    Directory? extDir = await getExternalStorageDirectory();
    extDir ??= await getApplicationDocumentsDirectory();

    final backupDir = Directory(p.join(extDir.path, 'OmarPOS_Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// تغيير موقع مجلد النسخ الاحتياطي
  Future<void> _changeBackupDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final newDir = Directory(p.join(selectedDirectory, 'OmarPOS_Backups'));
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }

      await DBHelper.saveSetting('backup_folder_path', newDir.path);
      setState(() {
        _customFolderPath = newDir.path;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تغيير مسار الحفظ إلى: ${newDir.path}')),
      );
    }
  }

  /// إنشاء نسخة احتياطية برقم وتاريخ مميز
  Future<void> _createBackup() async {
    setState(() => _isProcessing = true);
    try {
      final dbPath = await getDatabasesPath();
      final currentDbFile = File(p.join(dbPath, 'omar_pos.db')); // اسم قاعدة بيانات مشروعك

      if (!await currentDbFile.exists()) {
        throw Exception('قاعدة البيانات غير موجودة!');
      }

      final targetDirPath = _customFolderPath ?? (await _getDefaultBackupDirectory()).path;
      final targetDir = Directory(targetDirPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // إعطاء النسخة رقماً وتاريخاً مميزاً (سنة_شهر_يوم_ساعة_دقيقة_ثانية)
      final now = DateTime.now();
      final timeStamp = '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
      final backupFileName = 'OmarPOS_Backup_$timeStamp.db';

      final backupFile = File(p.join(targetDirPath, backupFileName));
      await currentDbFile.copy(backupFile.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء النسخة بنجاح:\n$backupFileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إنشاء النسخة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// استعادة نسخة احتياطية من المجلد المحدد
  Future<void> _restoreBackup() async {
    setState(() => _isProcessing = true);
    try {
      final initialPath = _customFolderPath ?? (await _getDefaultBackupDirectory()).path;

      // فتح متصفح الملفات لاختيار النسخة الاحتياطية (.db)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        initialDirectory: initialPath,
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null && result.files.single.path != null) {
        final selectedFilePath = result.files.single.path!;
        final selectedFile = File(selectedFilePath);

        final dbPath = await getDatabasesPath();
        final currentDbPath = p.join(dbPath, 'omar_pos.db');

        // أغلق قاعدة البيانات الحالية قبل الاستبدال
        final db = await openDatabase(currentDbPath);
        await db.close();

        // استبدال قاعدة البيانات بالنسخة المختارة
        await selectedFile.copy(currentDbPath);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة النسخة الاحتياطية بنجاح! يُفضل إعادة تشغيل التطبيق.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الاستعادة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي والاستعادة')),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.amber),
                    title: const Text('موقع مجلد النسخ الاحتياطي'),
                    subtitle: Text(
                      _customFolderPath ?? 'جاري جلب المسار...',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.blue),
                    onTap: _changeBackupDirectory,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                    title: const Text('إنشاء نسخة احتياطية جديدة'),
                    subtitle: const Text('حفظ نسخة كاملة باسم ورقم مميز بناءً على الوقت الحالي'),
                    onTap: _createBackup,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_download, color: Colors.green),
                    title: const Text('استعادة نسخة احتياطية'),
                    subtitle: const Text('اختيار ملف قاعدة البيانات والمرتجع لاسترجاع بياناته'),
                    onTap: _restoreBackup,
                  ),
                ),
              ],
            ),
    );
  }
}
