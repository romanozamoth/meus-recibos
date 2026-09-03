import 'package:flutter/material.dart';
import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/core/utils/date_utils.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/screens/documents/document_controller.dart';
import 'package:meus_recibos/screens/receipt/receipt_detail_screen.dart';
import 'package:provider/provider.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de documentos')),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : controller.recentReceipts.isEmpty
          ? const Center(child: Text('Nenhum documento criado.'))
          : RefreshIndicator(
              onRefresh: controller.loadRecentReceipts,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: controller.recentReceipts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final document = controller.recentReceipts[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(switch (document.type) {
                        DocumentType.receipt => Icons.receipt_long_outlined,
                        DocumentType.budget => Icons.request_quote_outlined,
                        DocumentType.proof => Icons.verified_outlined,
                      }),
                      title: Text(document.clientName),
                      subtitle: Text(
                        '${document.number} • ${AppDateUtils.format(document.date)}\n'
                        '${document.type.label}${document.type == DocumentType.budget ? ' • ${_statusLabel(document.status)}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: SizedBox(
                        width: 86,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            CurrencyUtils.format(document.total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReceiptDetailScreen(receipt: document),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'pending' => 'Pendente',
    'approved' => 'Aprovado',
    'paid' => 'Pago',
    'rejected' => 'Recusado',
    _ => status,
  };
}
