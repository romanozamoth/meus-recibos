import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/core/utils/date_utils.dart';
import 'package:meus_recibos/core/utils/document_utils.dart';
import 'package:meus_recibos/core/utils/quantity_utils.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/screens/receipt/receipt_pdf_screen.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptDetailScreen extends StatelessWidget {
  const ReceiptDetailScreen({required this.receipt, super.key});

  final AppDocument receipt;

  Future<void> _print(BuildContext context) async {
    final path = receipt.pdfPath;
    if (path == null || !await File(path).exists()) {
      if (context.mounted) _missingPdf(context);
      return;
    }
    await Printing.layoutPdf(onLayout: (_) => File(path).readAsBytes());
  }

  Future<void> _share(BuildContext context) async {
    final path = receipt.pdfPath;
    if (path == null || !await File(path).exists()) {
      if (context.mounted) _missingPdf(context);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        title: receipt.number ?? 'Recibo',
        text: 'Recibo ${receipt.number ?? ''}',
      ),
    );
  }

  void _open(BuildContext context) {
    final path = receipt.pdfPath;
    if (path == null || !File(path).existsSync()) {
      _missingPdf(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceiptPdfScreen(receipt: receipt)),
    );
  }

  void _missingPdf(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Arquivo PDF não encontrado.')));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(receipt.number ?? 'Recibo')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.receipt,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECIBO',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                receipt.number ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppDateUtils.format(receipt.date),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const _Title('Cliente'),
        _Info(label: 'Nome', value: receipt.clientName),
        if (receipt.clientDocument != null)
          _Info(
            label: 'CPF/CNPJ',
            value: DocumentUtils.format(receipt.clientDocument),
          ),
        if (receipt.clientAddress != null)
          _Info(label: 'Endereço', value: receipt.clientAddress!),
        const _Title('Serviço'),
        Text(receipt.serviceDescription),
        const _Title('Itens'),
        ...receipt.items.map(
          (item) => Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${QuantityUtils.formatMillis(item.quantityMillis)} ${item.unit} × ${CurrencyUtils.format(item.unitPrice)}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      CurrencyUtils.format(item.total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Info(label: 'Subtotal', value: CurrencyUtils.format(receipt.subtotal)),
        if (receipt.discount > 0)
          _Info(
            label: 'Desconto',
            value: CurrencyUtils.format(receipt.discount),
          ),
        _Info(
          label: 'Total',
          value: CurrencyUtils.format(receipt.total),
          emphasized: true,
        ),
        const _Title('Pagamento'),
        _Info(label: 'Forma', value: receipt.paymentMethod),
        if (receipt.dueDate != null)
          _Info(
            label: 'Vencimento',
            value: AppDateUtils.format(receipt.dueDate!),
          ),
        if (receipt.notes != null) ...[
          const _Title('Observações'),
          Text(receipt.notes!),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Abrir PDF'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartilhar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _print(context),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimir'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      value,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  final String label;
  final String value;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              fontSize: emphasized ? 19 : 14,
              color: emphasized ? AppColors.primary : null,
            ),
          ),
        ),
      ],
    ),
  );
}
