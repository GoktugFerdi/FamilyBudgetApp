import 'package:family_budget_app/domain/entities/transaction.dart';
import 'package:family_budget_app/presentation/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generateAndPrintPdf({
    required List<TransactionEntity> transactions,
    required String title,
    required String incomeLabel,
    required String expenseLabel,
    required String netLabel,
    required String personLabel,
    required bool isFamilyPlan,
  }) async {
    final pdf = pw.Document();

    // Fontları yükle (Türkçe karakter desteği için)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final totalIncome = getTotalIncome(transactions);
    final totalExpense = getTotalExpense(transactions);
    final netBalance = totalIncome - totalExpense; // Basitleştirilmiş net
    
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(incomeLabel, currencyFormat.format(totalIncome), PdfColors.green700),
                    _buildSummaryItem(expenseLabel, currencyFormat.format(totalExpense), PdfColors.red700),
                    _buildSummaryItem(netLabel, currencyFormat.format(netBalance), PdfColors.blue700),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: [
                'Tarih',
                'İşlem',
                if (isFamilyPlan) personLabel,
                'Tür',
                'Tutar',
              ],
              data: transactions.map((t) {
                String typeStr = '';
                switch (t.type) {
                  case TransactionType.income: typeStr = 'Gelir'; break;
                  case TransactionType.expense: typeStr = 'Gider'; break;
                  case TransactionType.debt: typeStr = 'Borç'; break;
                  case TransactionType.investment: typeStr = 'Yatırım'; break;
                }
                
                return [
                  DateFormat('dd.MM.yyyy').format(t.date),
                  t.title,
                  if (isFamilyPlan) t.creatorName ?? '-',
                  typeStr,
                  currencyFormat.format(t.amount),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'butce_raporu_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}
