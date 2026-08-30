import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:printing/printing.dart';

class ReceiptPdfScreen extends StatelessWidget {
  const ReceiptPdfScreen({required this.receipt, super.key});
  final AppDocument receipt;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(receipt.number ?? 'PDF do recibo')),
    body: PdfPreview(
      build: (_) => File(receipt.pdfPath!).readAsBytes(),
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      allowPrinting: false,
      allowSharing: false,
      pdfFileName: '${(receipt.number ?? 'recibo').replaceAll('/', '-')}.pdf',
    ),
  );
}
