import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

import '../data/models.dart';

class SaveResult {
  const SaveResult({required this.success, this.path, this.message});
  final bool success;
  final String? path;
  final String? message;
}

class ExportService {
  ExportService._();

  static final _money = NumberFormat('#,###', 'uz');

  // ===========================================================================
  //  STORAGE & PERMISSIONS
  // ===========================================================================

  static Future<bool> _ensureStoragePermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    // Try MANAGE_EXTERNAL_STORAGE first (Android 11+), fall back to legacy.
    if (await Permission.manageExternalStorage.isGranted) return true;
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;

    if (await Permission.storage.isGranted) return true;
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  static Future<Directory> _resolveSaveDirectory() async {
    if (Platform.isAndroid) {
      // /storage/emulated/0/Download — visible in Files app.
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) return downloads;
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          final downloadsAlt = Directory('${ext.path}/Download');
          if (!await downloadsAlt.exists()) {
            await downloadsAlt.create(recursive: true);
          }
          return downloadsAlt;
        }
      } catch (_) {}
    }
    try {
      final dl = await getDownloadsDirectory();
      if (dl != null) return dl;
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  static Future<SaveResult> _saveBytes(
    List<int> bytes,
    String fileName, {
    required String mimeType,
  }) async {
    try {
      if (kIsWeb) {
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return SaveResult(
          success: true,
          path: fileName,
          message: '$fileName yuklab olindi',
        );
      }
      await _ensureStoragePermission();
      final dir = await _resolveSaveDirectory();
      final filePath = '${dir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return SaveResult(success: true, path: filePath);
    } catch (e) {
      return SaveResult(success: false, message: e.toString());
    }
  }

  static Future<void> openFile(String path) async {
    if (kIsWeb) return;
    await OpenFilex.open(path);
  }

  // ===========================================================================
  //  PDF — Common helpers
  // ===========================================================================

  static pw.ThemeData? _pdfTheme;

  static Future<pw.ThemeData> _theme() async {
    if (_pdfTheme != null) return _pdfTheme!;
    try {
      final regular = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      _pdfTheme = pw.ThemeData.withFont(
        base: regular,
        bold: bold,
      );
    } catch (_) {
      // Fallback — built-in Helvetica supports basic Latin.
      _pdfTheme = pw.ThemeData.base();
    }
    return _pdfTheme!;
  }

  static Future<Uint8ListLike> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/logo.png');
      return Uint8ListLike(data.buffer.asUint8List());
    } catch (_) {
      return const Uint8ListLike(null);
    }
  }

  static pw.Widget _docHeader(String title, {String? subtitle}) {
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SANTEXNIKA',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF2563EB),
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0F172A),
                  ),
                ),
                if (subtitle != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFDBEAFE),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'Sana: $now',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF2563EB),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 2,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromInt(0xFF2563EB),
                PdfColor.fromInt(0xFFDBEAFE),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Santexnika admin',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF94A3B8),
            ),
          ),
          pw.Text(
            'Sahifa ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  //  PDF — Single order
  // ===========================================================================

  static Future<List<int>> buildOrderPdfBytes(
    OrderRecord order, {
    String? driverName,
  }) async {
    final theme = await _theme();
    final logo = await _loadLogo();
    final doc = pw.Document(theme: theme);

    pw.Widget infoRow(String label, String value, {bool last = false}) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: last ? 0 : 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 95,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF64748B),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        header: (ctx) {
          if (ctx.pageNumber > 1) return pw.SizedBox.shrink();
          return _docHeader(
            'Buyurtma ${order.id}',
            subtitle: DateFormat('dd MMMM yyyy, HH:mm').format(order.createdAt),
          );
        },
        footer: _footer,
        build: (ctx) => [
          if (logo.bytes != null) ...[
            pw.SizedBox(height: 4),
          ],
          // Status + total panel
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Status',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromInt(0xFF64748B),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _statusBg(order.status),
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        order.status.label,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _statusFg(order.status),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Umumiy summa',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromInt(0xFF64748B),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${_money.format(order.total)} so\'m',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          // Customer
          pw.Text(
            'Mijoz ma\'lumotlari',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0F172A),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                infoRow('Ism familiya:', order.customerName),
                infoRow('Telefon:', order.phone),
                if (order.email != null && order.email!.isNotEmpty)
                  infoRow('Email:', order.email!),
                infoRow('Manzil:', order.address),
                infoRow(
                  'Haydovchi:',
                  driverName ?? 'Tayinlanmagan',
                  last: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          // Items table
          pw.Text(
            'Mahsulotlar',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF0F172A),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(
              color: PdfColor.fromInt(0xFFE2E8F0),
              width: 0.5,
            ),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF2563EB),
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headerAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
            ),
            headers: ['Mahsulot', 'Soni', 'Narx', 'Jami'],
            data: [
              for (final item in order.items)
                [
                  item.name,
                  '${item.quantity}',
                  _money.format(item.price),
                  _money.format(item.price * item.quantity),
                ],
            ],
          ),
          pw.SizedBox(height: 14),
          // Total
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFDBEAFE),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'UMUMIY JAMI:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Text(
                      '${_money.format(order.total)} so\'m',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text(
              'Buyurtma uchun rahmat!',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: PdfColor.fromInt(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<SaveResult> exportOrder(
    OrderRecord order, {
    String? driverName,
  }) async {
    final bytes = await buildOrderPdfBytes(order, driverName: driverName);
    final fileName = 'buyurtma_${order.id}.pdf';
    return _saveBytes(bytes, fileName, mimeType: 'application/pdf');
  }

  // ===========================================================================
  //  PDF — All orders
  // ===========================================================================

  static Future<SaveResult> exportAllOrders(
    List<OrderRecord> orders,
    Map<String, String> driverNames,
  ) async {
    final theme = await _theme();
    final doc = pw.Document(theme: theme);
    final total = orders.fold<double>(0, (s, o) => s + o.total);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) {
          if (ctx.pageNumber > 1) return pw.SizedBox.shrink();
          return _docHeader(
            'Buyurtmalar ro\'yxati',
            subtitle: '${orders.length} ta buyurtma · jami ${_money.format(total)} so\'m',
          );
        },
        footer: _footer,
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(
              color: PdfColor.fromInt(0xFFE2E8F0),
              width: 0.5,
            ),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF2563EB),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.center,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.center,
              7: pw.Alignment.centerRight,
            },
            headerAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 5,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(2.5),
              4: pw.FlexColumnWidth(1.6),
              5: pw.FlexColumnWidth(2),
              6: pw.FlexColumnWidth(1),
              7: pw.FlexColumnWidth(2),
            },
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
            ),
            headers: [
              'ID',
              'Mijoz',
              'Telefon',
              'Haydovchi',
              'Status',
              'Sana',
              'Soni',
              'Summa (so\'m)',
            ],
            data: [
              for (final o in orders)
                [
                  o.id,
                  o.customerName,
                  o.phone,
                  driverNames[o.driverId ?? ''] ?? '—',
                  o.status.label,
                  DateFormat('dd.MM.yy HH:mm').format(o.createdAt),
                  '${o.items.fold<int>(0, (s, i) => s + i.quantity)}',
                  _money.format(o.total),
                ],
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFDBEAFE),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'UMUMIY:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      '${_money.format(total)} so\'m',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return _saveBytes(
      bytes,
      'buyurtmalar_$stamp.pdf',
      mimeType: 'application/pdf',
    );
  }

  // ===========================================================================
  //  PDF — Products
  // ===========================================================================

  static Future<SaveResult> exportProducts(
    List<Product> products,
    Map<String, String> categoryNames,
  ) async {
    final theme = await _theme();
    final doc = pw.Document(theme: theme);
    final totalValue = products.fold<double>(
      0,
      (s, p) => s + p.price * p.stock,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) {
          if (ctx.pageNumber > 1) return pw.SizedBox.shrink();
          return _docHeader(
            'Mahsulotlar ro\'yxati',
            subtitle:
                '${products.length} ta mahsulot · jami zaxira qiymati ${_money.format(totalValue)} so\'m',
          );
        },
        footer: _footer,
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(
              color: PdfColor.fromInt(0xFFE2E8F0),
              width: 0.5,
            ),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF2563EB),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: const {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.centerRight,
            },
            headerAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.6),
              1: pw.FlexColumnWidth(4),
              2: pw.FlexColumnWidth(2.5),
              3: pw.FlexColumnWidth(1.8),
              4: pw.FlexColumnWidth(2),
              5: pw.FlexColumnWidth(1),
              6: pw.FlexColumnWidth(1),
              7: pw.FlexColumnWidth(2.2),
            },
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
            ),
            headers: [
              '№',
              'Nomi',
              'Kategoriya',
              'SKU',
              'Narx (so\'m)',
              'Zaxira',
              'Sotilgan',
              'Qiymat (so\'m)',
            ],
            data: [
              for (var i = 0; i < products.length; i++)
                [
                  '${i + 1}',
                  products[i].name,
                  categoryNames[products[i].categoryId] ?? '—',
                  products[i].sku.isEmpty ? '—' : products[i].sku,
                  _money.format(products[i].price),
                  '${products[i].stock}',
                  '${products[i].soldCount}',
                  _money.format(products[i].price * products[i].stock),
                ],
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFDBEAFE),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'JAMI ZAXIRA QIYMATI:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      '${_money.format(totalValue)} so\'m',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return _saveBytes(
      bytes,
      'mahsulotlar_$stamp.pdf',
      mimeType: 'application/pdf',
    );
  }

  // ===========================================================================
  //  Status colors for PDF
  // ===========================================================================

  static PdfColor _statusBg(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return PdfColor.fromInt(0xFFFEF3C7);
      case OrderStatus.processing:
        return PdfColor.fromInt(0xFFDBEAFE);
      case OrderStatus.completed:
        return PdfColor.fromInt(0xFFD1FAE5);
      case OrderStatus.cancelled:
        return PdfColor.fromInt(0xFFFEE2E2);
    }
  }

  static PdfColor _statusFg(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return PdfColor.fromInt(0xFFF59E0B);
      case OrderStatus.processing:
        return PdfColor.fromInt(0xFF3B82F6);
      case OrderStatus.completed:
        return PdfColor.fromInt(0xFF10B981);
      case OrderStatus.cancelled:
        return PdfColor.fromInt(0xFFEF4444);
    }
  }
}

class Uint8ListLike {
  const Uint8ListLike(this.bytes);
  final List<int>? bytes;
}
