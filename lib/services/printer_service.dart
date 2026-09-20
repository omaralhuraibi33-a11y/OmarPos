import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:omar_pos/db_helper.dart';

class PrinterService {
  
  // دالة توليد محتوى الفاتورة وإرسالها للطابعات مع إظهار نافذة منبثقة بالنتيجة
  static Future<void> printInvoice({
    required BuildContext context,
    required dynamic invoice, 
    required List<Map<String, dynamic>> items,
    required String usageType, // 'زبون' أو 'مطبخ'
  }) async {
    try {
      final savedPrintersJson = await DBHelper.getSetting('printers_list');
      if (savedPrintersJson == null || savedPrintersJson.isEmpty) {
        _showAlertDialog(context, 'تنبيه طباعة', 'لا توجد طابعات مضافة في الإعدادات.');
        return;
      }

      final List<dynamic> decoded = jsonDecode(savedPrintersJson);
      final List<Map<String, dynamic>> printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      // تصفية الطابعات حسب الاستخدام ('مطبخ' أو 'زبون')
      final targetPrinters = printers.where((p) => p['usage'] == usageType).toList();

      if (targetPrinters.isEmpty) {
        _showAlertDialog(context, 'تنبيه طباعة', 'لا توجد طابعة مُعرّفة لنوع الاستخدام: "$usageType" في الإعدادات.');
        return;
      }

      for (var printer in targetPrinters) {
        await _sendToPrinter(context, printer, invoice, items, usageType);
      }
    } catch (e) {
      _showAlertDialog(context, 'خطأ عام في الطباعة', '$e');
    }
  }

  static Future<void> _sendToPrinter(
    BuildContext context,
    Map<String, dynamic> printer,
    dynamic invoice,
    List<Map<String, dynamic>> items,
    String usageType,
  ) async {
    String printerName = printer['name']?.toString() ?? 'طابعة غير محددة';
    try {
      final paperSizeStr = printer['paperSize'] ?? '80';
      final paperSize = (paperSizeStr == '57' || paperSizeStr == '58') ? PaperSize.mm58 : PaperSize.mm80;

      final profile = await CapabilityProfile.load();
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];

      bytes += generator.reset();

      // استخراج بيانات الفاتورة بمرونة عالية
      String invoiceId = '';
      String invoiceDate = '';
      String customerName = '';
      double totalAmount = 0.0;
      String paymentType = '';

      if (invoice is Map) {
        invoiceId = invoice['id']?.toString() ?? '';
        invoiceDate = invoice['date']?.toString() ?? '';
        customerName = invoice['customerName']?.toString() ?? 'عميل نقدي';
        totalAmount = double.tryParse(invoice['totalAmount']?.toString() ?? '0') ?? 0.0;
        paymentType = invoice['paymentType']?.toString() ?? 'cash';
      } else {
        invoiceId = invoice.id?.toString() ?? '';
        invoiceDate = invoice.date?.toString() ?? '';
        customerName = invoice.customerName?.toString() ?? 'عميل نقدي';
        totalAmount = double.tryParse(invoice.totalAmount?.toString() ?? '0') ?? 0.0;
        paymentType = invoice.paymentType?.toString() ?? 'cash';
      }

      final String footerText = await DBHelper.getSetting('invoice_footer', defaultValue: 'شكراً لزيارتكم! نأمل رؤيتكم مجدداً.') ?? 'شكراً لزيارتكم!';

      // --- تصميم الوصل ---
      bytes += generator.text(
        usageType == 'مطبخ' ? '*** طلب مطبخ تحضير ***' : 'OMAR POS',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
      );
      
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('رقم الفاتورة: $invoiceId', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('التاريخ: $invoiceDate', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('العميل: $customerName', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // رأس جدول الأصناف
      bytes += generator.row([
        PosColumn(text: 'الإجمالي', width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
        PosColumn(text: 'الكمية/السعر', width: 4, styles: const PosStyles(bold: true, align: PosAlign.center)),
        PosColumn(text: 'الصنف', width: 5, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // تفاصيل الأصناف
      if (items.isNotEmpty) {
        for (var item in items) {
          final name = item['name']?.toString() ?? '';
          final qty = item['qty']?.toString() ?? '1';
          final price = item['price']?.toString() ?? '0';
          final notes = item['notes']?.toString() ?? '';
          
          final double q = double.tryParse(qty) ?? 1.0;
          final double p = double.tryParse(price) ?? 0.0;
          final total = (q * p).toStringAsFixed(2);

          bytes += generator.row([
            PosColumn(text: total, width: 3, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(text: '$qty x $price', width: 4, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: name, width: 5, styles: const PosStyles(align: PosAlign.right)),
          ]);

          if (notes.isNotEmpty) {
            bytes += generator.text('  (ملاحظة: $notes)', styles: const PosStyles(align: PosAlign.right));
          }
        }
      } else {
        bytes += generator.text('تفاصيل الأصناف غير متوفرة لهذه الفاتورة', styles: const PosStyles(align: PosAlign.center));
      }

      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      if (usageType == 'زبون') {
        bytes += generator.text(
          'المبلغ الإجمالي: ${totalAmount.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size1),
        );
        bytes += generator.text('طريقة الدفع: $paymentType', styles: const PosStyles(align: PosAlign.right));
        bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text(footerText, styles: const PosStyles(align: PosAlign.center, bold: true));
      } else {
        bytes += generator.text('يرجى التجهيز بسرعة!', styles: const PosStyles(align: PosAlign.center, bold: true));
      }

      bytes += generator.feed(2);
      bytes += generator.cut();

      // --- إرسال البيانات والتقاط الخطأ لعرضه كـ نافذة منبثقة ---
      final ip = (printer['ip'] ?? '').trim();
      final mac = (printer['macAddress'] ?? '').trim();

      if (ip.isNotEmpty && ip != '0.0.0.0' && ip != 'null') {
        try {
          debugPrint('محاولة الاتصال بالطابعة ($printerName) عبر الـ IP: $ip...');
          final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 5));
          socket.add(bytes);
          await socket.flush();
          await Future.delayed(const Duration(milliseconds: 500));
          await socket.close();
          
          // إذا تمت الطباعة بنجاح
          _showAlertDialog(context, 'نجاح الطباعة', 'تم إرسال الفاتورة إلى الطابعة ($printerName) بنجاح عبر الشبكة.');
        } catch (socketErr) {
          // إذا فشل الاتصال بالشبكة، نعرض رسالة الخطأ للمستخدم
          _showAlertDialog(
            context, 
            'فشل الاتصال بالطابعة ($printerName)', 
                  'تعذر الاتصال بعنوان الـ IP ($ip).\n\nالسبب التفصيلي:\n$socketErr\n\nتأكد أن الطابعة متصلة بنفس شبكة الواي فاي وأن الـ IP صحيح.'
          );
        }
      } else if (mac.isNotEmpty) {
        try {
          await PrintBluetoothThermal.disconnect;
        } catch (_) {}

        bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
        if (connected) {
          await Future.delayed(const Duration(milliseconds: 300));
          await PrintBluetoothThermal.writeBytes(bytes);
          await Future.delayed(const Duration(milliseconds: 500));
          await PrintBluetoothThermal.disconnect;
          
          _showAlertDialog(context, 'نجاح الطباعة', 'تمت الطباعة عبر البلوتوث للطابعة ($printerName) بنجاح.');
        } else {
          _showAlertDialog(context, 'فشل البلوتوث', 'لم يتمكن التطبيق من الاتصال بالطابعة عبر عنوان الـ MAC: $mac');
        }
      } else {
        _showAlertDialog(context, 'خطأ في إعدادات الطابعة', 'الطابعة ($printerName) لا تحتوي على عنوان IP أو MAC صالح.');
      }
    } catch (e) {
      _showAlertDialog(context, 'خطأ في معالجة الطباعة', 'حدث خطأ أثناء إعداد بيانات الطابعة ($printerName):\n$e');
    }
  }

  // دالة مساعدة لإظهار النافذة المنبثقة
  static void _showAlertDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        );
      },
    );
  }
}
