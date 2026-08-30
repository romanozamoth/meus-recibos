import 'dart:io';
import 'dart:typed_data';

import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/core/utils/date_utils.dart';
import 'package:meus_recibos/core/utils/document_utils.dart';
import 'package:meus_recibos/core/utils/quantity_utils.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/models/profile.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  Future<Uint8List> buildReceipt(AppDocument receipt, Profile profile) async {
    final pdf = pw.Document();
    final accent = PdfColor.fromInt(profile.color);
    pw.MemoryImage? logo;
    final logoPath = profile.logoPath;
    if (logoPath != null) {
      final file = File(logoPath);
      if (await file.exists()) logo = pw.MemoryImage(await file.readAsBytes());
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 14),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: accent, width: 2)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 64,
                  height: 64,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 14),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.tradeName ?? profile.name,
                      style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    if (profile.tradeName != null)
                      pw.Text(
                        profile.name,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    pw.Text(
                      '${profile.documentType}: ${DocumentUtils.format(profile.documentNumber)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'RECIBO',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  pw.Text(receipt.number ?? 'REC-PRÉVIA'),
                  pw.Text(AppDateUtils.format(receipt.date)),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          _sectionTitle('DADOS DO CLIENTE', accent),
          _info('Nome', receipt.clientName),
          if (receipt.clientDocument != null)
            _info('CPF/CNPJ', DocumentUtils.format(receipt.clientDocument!)),
          if (receipt.clientAddress != null)
            _info('Endereço', receipt.clientAddress!),
          _sectionTitle('SERVIÇO', accent),
          pw.Text(receipt.serviceDescription),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerDecoration: pw.BoxDecoration(color: accent),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(6),
            headers: const ['Item', 'Qtd.', 'Un.', 'Valor unit.', 'Total'],
            data: receipt.items
                .map(
                  (item) => [
                    item.description,
                    QuantityUtils.formatMillis(item.quantityMillis),
                    item.unit,
                    CurrencyUtils.format(item.unitPrice),
                    CurrencyUtils.format(item.total),
                  ],
                )
                .toList(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(0.8),
              2: const pw.FlexColumnWidth(0.7),
              3: const pw.FlexColumnWidth(1.3),
              4: const pw.FlexColumnWidth(1.3),
            },
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _total('Subtotal', receipt.subtotal),
                  if (receipt.discount > 0)
                    _total('Desconto', -receipt.discount),
                  pw.Divider(color: accent),
                  _total('TOTAL', receipt.total, bold: true, color: accent),
                ],
              ),
            ),
          ),
          _sectionTitle('PAGAMENTO', accent),
          _info('Forma', receipt.paymentMethod),
          if (receipt.dueDate != null)
            _info('Vencimento', AppDateUtils.format(receipt.dueDate!)),
          if (receipt.notes != null) ...[
            _sectionTitle('OBSERVAÇÕES', accent),
            pw.Text(receipt.notes!),
          ],
          pw.SizedBox(height: 42),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Container(width: 260, height: 1, color: PdfColors.grey500),
                pw.SizedBox(height: 5),
                pw.Text(profile.tradeName ?? profile.name),
                pw.Text(
                  '${profile.city} - ${profile.state}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(
            [
              if (profile.phone.isNotEmpty) profile.phone,
              if (profile.email?.isNotEmpty == true) profile.email!,
              if (profile.address?.isNotEmpty == true) profile.address!,
            ].join('  •  '),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<String> saveReceipt(Uint8List bytes, AppDocument receipt) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'pdfs'));
    await directory.create(recursive: true);
    final safeNumber = (receipt.number ?? 'recibo').replaceAll('/', '-');
    final file = File(p.join(directory.path, '$safeNumber.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  pw.Widget _sectionTitle(String text, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 7),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );

  pw.Widget _info(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 72,
          child: pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(child: pw.Text(value)),
      ],
    ),
  );

  pw.Widget _total(
    String label,
    int cents, {
    bool bold = false,
    PdfColor? color,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : null,
            color: color,
          ),
        ),
        pw.Text(
          CurrencyUtils.format(cents),
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : null,
            color: color,
          ),
        ),
      ],
    ),
  );
}
