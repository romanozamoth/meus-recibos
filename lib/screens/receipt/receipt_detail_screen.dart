import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/core/utils/date_utils.dart';
import 'package:meus_recibos/core/utils/document_utils.dart';
import 'package:meus_recibos/core/utils/quantity_utils.dart';
import 'package:meus_recibos/models/app_document.dart';

class ReceiptDetailScreen extends StatelessWidget {
  const ReceiptDetailScreen({required this.receipt, super.key});

  final AppDocument receipt;

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
        const Text(
          'Preview e PDF serão adicionados no Marco 4.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
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
