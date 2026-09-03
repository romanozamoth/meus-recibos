import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/core/utils/date_utils.dart';
import 'package:meus_recibos/core/utils/document_utils.dart';
import 'package:meus_recibos/core/utils/quantity_utils.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/screens/documents/document_controller.dart';
import 'package:meus_recibos/screens/profiles/profile_controller.dart';
import 'package:meus_recibos/screens/receipt/receipt_form_screen.dart';
import 'package:meus_recibos/screens/receipt/receipt_pdf_screen.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
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
        title: receipt.number ?? receipt.type.label,
        text: '${receipt.type.label} ${receipt.number ?? ''}',
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

  void _edit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptFormScreen(
          type: receipt.type,
          initialDocument: receipt,
          editing: true,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Excluir ${receipt.type.label.toLowerCase()}?'),
        content: Text(
          'O documento ${receipt.number ?? ''} e seu PDF serão excluídos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      await context.read<DocumentController>().deleteDocument(receipt);
      if (!context.mounted) return;
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        SnackBar(content: Text('${receipt.type.label} excluído com sucesso.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o documento.')),
      );
    }
  }

  void _missingPdf(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Arquivo PDF não encontrado.')));

  Future<void> _changeStatus(BuildContext context, String status) async {
    final profile = context.read<ProfileController>().profiles.firstWhere(
      (profile) => profile.id == receipt.profileId,
    );
    try {
      final updated = await context
          .read<DocumentController>()
          .updateBudgetStatus(receipt, status, profile);
      if (!context.mounted) return;
      if (status == 'paid') {
        final generate = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Gerar comprovante?'),
            content: const Text(
              'O orçamento foi marcado como pago. Deseja emitir um comprovante de pagamento com os mesmos dados?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Agora não'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Gerar comprovante'),
              ),
            ],
          ),
        );
        if (!context.mounted) return;
        if (generate == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptFormScreen(
                type: DocumentType.proof,
                initialDocument: updated,
              ),
            ),
          );
          return;
        }
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptDetailScreen(receipt: updated),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível alterar o status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(receipt.number ?? receipt.type.label),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Opções do documento',
          onSelected: (value) {
            if (value == 'edit') _edit(context);
            if (value == 'delete') _delete(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: switch (receipt.type) {
                DocumentType.receipt => AppColors.receipt,
                DocumentType.budget => AppColors.budget,
                DocumentType.proof => AppColors.proof,
              },
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.type.label.toUpperCase(),
                  style: const TextStyle(
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
          if (receipt.type == DocumentType.budget) ...[
            const _Title('Status do orçamento'),
            DropdownButtonFormField<String>(
              initialValue: receipt.status,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items:
                  const {
                        'pending': 'Pendente',
                        'approved': 'Aprovado',
                        'paid': 'Pago',
                        'rejected': 'Recusado',
                      }.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null && value != receipt.status) {
                  _changeStatus(context, value);
                }
              },
            ),
          ],
          if (receipt.type == DocumentType.proof &&
              receipt.sourceDocumentId != null)
            _SourceDocumentInfo(sourceId: receipt.sourceDocumentId!),
          const _Title('Cliente'),
          _Info(label: 'Nome', value: receipt.clientName),
          if (receipt.clientDocument != null)
            _Info(
              label: 'CPF/CNPJ',
              value: DocumentUtils.format(receipt.clientDocument),
            ),
          if (receipt.clientAddress != null)
            _Info(label: 'Endereço', value: receipt.clientAddress!),
          if (receipt.serviceDescription.isNotEmpty) ...[
            const _Title('Serviço'),
            Text(receipt.serviceDescription),
          ],
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
          _Info(
            label: 'Subtotal',
            value: CurrencyUtils.format(receipt.subtotal),
          ),
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
          if (receipt.validUntil != null)
            _Info(
              label: 'Validade',
              value: AppDateUtils.format(receipt.validUntil!),
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
          OutlinedButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartilhar'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _print(context),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Imprimir'),
          ),
        ],
      ),
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

class _SourceDocumentInfo extends StatelessWidget {
  const _SourceDocumentInfo({required this.sourceId});
  final int sourceId;

  @override
  Widget build(BuildContext context) => FutureBuilder<AppDocument?>(
    future: context.read<DocumentController>().findById(sourceId),
    builder: (context, snapshot) {
      final source = snapshot.data;
      if (source == null) return const SizedBox.shrink();
      return Card(
        color: const Color(0xFFE8F5E9),
        child: ListTile(
          leading: const Icon(Icons.link, color: AppColors.proof),
          title: const Text('Origem do comprovante'),
          subtitle: Text(source.number ?? 'Orçamento original'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptDetailScreen(receipt: source),
            ),
          ),
        ),
      );
    },
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
