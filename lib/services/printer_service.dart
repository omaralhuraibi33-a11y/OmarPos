import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:omar_pos/db_helper.dart';

class PrinterService {
  
  // دالة توليد محتوى الفاتورة وإرسالها للطابعات المطابقة للاستخدام (زبون أو مطبخ)
  static Future<void> printInvoice({
    required dynamic invoice, // استخدام dynamic لمنع تضارب تعريف كلاس Invoice
    required List<Map<String, dynamic>> items,
    required String usageType, // 'زبون' أو 'مطبخ'
  }) async {
    try {
      // 1. جلب الطابعات المفضلة من قاعدة البيانات
      final savedPrintersJson = await DBHelper.getSetting('printers_list');
      if (savedPrintersJson == null || savedPrintersJson.isEmpty) {
        debugPrint('لا توجد طابعات مضافة في الإعدادات.');
        return;
      }

      final List<dynamic> decoded = jsonDecode(savedPrintersJson);
      final List<Map<String, dynamic>> printers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      // تصفية الطابعات التي تطابق نوع الاستخدام المطلوب (طابعة "مطبخ" أو "زبون")
      final targetPrinters = printers.where((p) => p['usage'] == usageType).toList();

      if (targetPrinters.isEmpty) {
        debugPrint('لا توجد طابعة مُعرّفة لنوع الاستخدام: $usageType');
        return;
      }

      for (var printer in targetPrinters) {
        await _sendToPrinter(printer, invoice, items, usageType);
      }
    } catch (e) {
      debugPrint('خطأ عام في PrinterService: $e');
    }
  }

  // دالة إرسال البيانات الفعلية للطابعة الفردية
  static Future<void> _sendToPrinter(
    Map<String, dynamic> printer,
    dynamic invoice,
    List<Map<String, dynamic>> items,
    String usageType,
  ) async {
    try {
      final paperSizeStr = printer['paperSize'] ?? '80';
      final paperSize = paperSizeStr == '57' ? PaperSize.mm58 : PaperSize.mm80;

      final profile = await CapabilityProfile.load();
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];

      // تصميم رأس الوصل (يختلف حسب إذا كان للزبون أو للمطبخ)
      bytes += generator.text(
        usageType == 'مطبخ' ? '*** طلب مطبخ تحضير ***' : 'OMAR POS',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
      );
      
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('رقم الفاتورة: ${invoice.id}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('التاريخ: ${invoice.date}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('العميل: ${invoice.customerName}', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // جدول الأصناف
      bytes += generator.row([
        PosColumn(text: 'الإجمالي', width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
        PosColumn(text: 'الكمية/السعر', width: 4, styles: const PosStyles(bold: true, align: PosAlign.center)),
        PosColumn(text: 'الصنف', width: 5, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      for (var item in items) {
        final name = item['name'].toString();
        final qty = item['qty'].toString();
        final price = item['price'].toString();
        final notes = item['notes']?.toString() ?? '';
        final total = (double.parse(qty) * double.parse(price)).toStringAsFixed(2);

        bytes += generator.row([
          PosColumn(text: total, width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: '$qty x $price', width: 4, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: name, width: 5, styles: const PosStyles(align: PosAlign.right)),
        ]);

        if (notes.isNotEmpty) {
          bytes += generator.text('  (ملاحظة: $notes)', styles: const PosStyles(align: PosAlign.right));
        }
      }

      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      if (usageType == 'زبون') {
        bytes += generator.text(
          'المبلغ الإجمالي: ${invoice.totalAmount.toStringAsFixed(2)}',
          styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size1),
        );
        bytes += generator.text('طريقة الدفع: ${invoice.paymentType}', styles: const PosStyles(align: PosAlign.right));
        bytes += generator.text('شكراً لزيارتكم!', styles: const PosStyles(align: PosAlign.center, bold: true));
      } else {
        bytes += generator.text('يرجى التجهيز بسرعة!', styles: const PosStyles(align: PosAlign.center, bold: true));
      }

      bytes += generator.feed(2);
      bytes += generator.cut();

      // فحص نوع الاتصال (واي فاي أم بلوتوث) والتنفيذ
      final connectionType = printer['connection'];
      if (connectionType == 'واي فاي') {
        final ip = (printer['ip'] ?? '').trim();
        if (ip.isNotEmpty) {
          final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 5));
          socket.add(bytes);
          await socket.flush();
          await socket.close();
          debugPrint('تمت الطباعة عبر الواي فاي بنجاح للطابعة: ${printer['name']}');
        }
      } else {
        // بلوتوث
        final mac = (printer['macAddress'] ?? '').trim();
        if (mac.isNotEmpty) {
          bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
          if (connected) {
            await PrintBluetoothThermal.writeBytes(bytes);
            await PrintBluetoothThermal.disconnect;
            debugPrint('تمت الطباعة عبر البلوتوث بنجاح للطابعة: ${printer['name']}');
          } else {
            debugPrint('فشل الاتصال بطابعة البلوتوث ذات العنوان: $mac');
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء إرسال الطباعة للطابعة ${printer['name']}: $e');
    }
  }
}
