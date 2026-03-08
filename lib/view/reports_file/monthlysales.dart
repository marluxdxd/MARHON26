import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:cashier/pdf/view_pdf_screen.dart';

class MonthlySales extends StatefulWidget {
  const MonthlySales({super.key});

  @override
  State<MonthlySales> createState() => _MonthlySalesState();
}

class _MonthlySalesState extends State<MonthlySales> {
  final supabase = Supabase.instance.client;

  List<String> availableMonths = [];
  bool isLoading = true;

  pw.Font? regularFont;
  pw.Font? boldFont;
  Uint8List? logoBytes;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await loadFonts();
    await loadLogo();
    await loadMonths();
  }

  // LOAD FONTS
  Future<void> loadFonts() async {
    final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

    regularFont = pw.Font.ttf(regularData);
    boldFont = pw.Font.ttf(boldData);
  }

  // LOAD LOGO
  Future<void> loadLogo() async {
    final logoData = await rootBundle.load('assets/images/marhon.png');
    logoBytes = logoData.buffer.asUint8List();
  }

  // LOAD MONTHS
  Future<void> loadMonths() async {
    final res = await supabase
        .from('transactions')
        .select('created_at')
        .order('created_at');

    final months = (res as List)
        .map((e) => DateTime.parse(e['created_at']))
        .map((d) => DateFormat('yyyy-MM').format(d))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      availableMonths = months;
      isLoading = false;
    });
  }

  String formatToPHT(String? utcString) {
    if (utcString == null) return '';
    final utcTime = DateTime.parse(utcString).toUtc();
    final phtTime = utcTime.add(const Duration(hours: 8));
    return DateFormat('yyyy-MM-dd hh:mm a').format(phtTime);
  }

  String formatMonth(String yyyymm) {
    final date = DateTime.parse('$yyyymm-01');
    return DateFormat('MMMM yyyy').format(date);
  }

  // FETCH ITEMS + PROMOS
  Future<List<Map<String, dynamic>>> fetchAllItemsMerged() async {
    final itemsRes = await supabase
        .from('transaction_items')
        .select('*, transaction:transactions(created_at)');

    final items = List<Map<String, dynamic>>.from(itemsRes as List);

    final promosRes = await supabase.from('transaction_promos').select('*');
    final promos = List<Map<String, dynamic>>.from(promosRes);

    for (var item in items) {
      final relatedPromos = promos.where((p) =>
          p['transaction_id'] == item['transaction_id'] &&
          p['product_id'] == item['product_id']);

      final totalPromo =
          relatedPromos.fold<int>(0, (sum, p) => sum + ((p['promo_count'] ?? 0) as int));

      item['promo_count'] = totalPromo;

      final isPromo = item['is_promo'] == true;

      if (isPromo) {
        item['subtotal'] =
            totalPromo * (item['retail_price'] as num).toDouble();
      } else {
        item['subtotal'] =
            (item['qty'] as int) * (item['retail_price'] as num).toDouble();
      }
    }

    return items;
  }

  // FILTER MONTH
  List<Map<String, dynamic>> filterItemsByMonth(
      List<Map<String, dynamic>> allItems, String month) {
    return allItems.where((item) {
      final createdAt = item['transaction']?['created_at'];
      if (createdAt == null) return false;

      final date = DateTime.parse(createdAt);
      return DateFormat('yyyy-MM').format(date) == month;
    }).toList();
  }

  // GENERATE PDF
  Future<File> generateMonthlyPDF(
      String month,
      List<Map<String, dynamic>> monthlyItems,
      List<Map<String, dynamic>> allItems) async {

    final pdf = pw.Document();

    final totalRevenue = monthlyItems.fold<double>(
      0,
      (sum, i) => sum + (i['subtotal'] as double),
    );

    final monthOrder = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];

    Map<String,double> monthlyTotals = {
      for (var m in monthOrder) m: 0.0
    };

    for (var item in allItems) {
      final createdAt = item['transaction']?['created_at'];
      if (createdAt == null) continue;

      final m = DateFormat('MMM').format(DateTime.parse(createdAt));

      if (monthlyTotals.containsKey(m)) {
        monthlyTotals[m] =
            monthlyTotals[m]! + (item['subtotal'] as double);
      }
    }

    final maxMonthlyRevenue =
        monthlyTotals.values.reduce((a, b) => a > b ? a : b);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [

          // HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoBytes != null)
                pw.Image(pw.MemoryImage(logoBytes!), width: 60),

              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Monthly Sales Report',
                      style: pw.TextStyle(font: boldFont, fontSize: 22)),
                  pw.Text(formatMonth(month),
                      style: pw.TextStyle(font: regularFont)),
                ],
              )
            ],
          ),

          pw.Divider(),

          pw.Text(
            'Total Revenue: ₱${totalRevenue.toStringAsFixed(2)}',
            style: pw.TextStyle(font: regularFont),
          ),

          pw.SizedBox(height: 20),

          // TABLE
          pw.Table.fromTextArray(
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey100),
            headers: [
              'Date',
              'Product',
              'Qty',
              'Promo',
              'Price',
              'Subtotal'
            ],
            data: monthlyItems.map((i) {
              final dateStr =
                  formatToPHT(i['transaction']?['created_at']);

              return [
                dateStr,
                i['product_name'] ?? '',
                i['qty'].toString(),
                (i['promo_count'] ?? 0).toString(),
                '₱${(i['retail_price'] as num).toStringAsFixed(2)}',
                '₱${(i['subtotal'] as double).toStringAsFixed(2)}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 25),

          // CHART
          pw.Text(
            'Monthly Sales Chart',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),

          pw.Container(
            height: 120,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: monthOrder.map((m) {

                final value = monthlyTotals[m]!;

                return pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [

                      if (value > 0)
                        pw.Text(
                          value.toStringAsFixed(0),
                          style: pw.TextStyle(font: regularFont, fontSize: 8),
                        ),

                      pw.Container(
                        width: 10,
                        height: (value / maxMonthlyRevenue) * 80,
                        color: PdfColors.blue,
                      ),

                      pw.Text(
                        m,
                        style: pw.TextStyle(font: regularFont, fontSize: 8),
                      )
                    ],
                  ),
                );

              }).toList(),
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sales_$month.pdf');

    await file.writeAsBytes(await pdf.save());

    return file;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: availableMonths.length,
      itemBuilder: (_, index) {

        final month = availableMonths[index];

        return Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Text(formatMonth(month)),
            trailing: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () async {

                final allItems = await fetchAllItemsMerged();
                final monthlyItems =
                    filterItemsByMonth(allItems, month);

                final file = await generateMonthlyPDF(
                    month, monthlyItems, allItems);

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ViewPDFScreen(pdfFile: file),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}