import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/models/profile.dart';
import 'package:meus_recibos/services/pdf_service.dart';
import 'package:printing/printing.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({
    required this.receipt,
    required this.profile,
    required this.onSave,
    super.key,
  });

  final AppDocument receipt;
  final Profile profile;
  final Future<void> Function() onSave;

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  late final Future<Uint8List> _preview;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _preview = PdfService().buildReceipt(widget.receipt, widget.profile);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar e gerar o PDF.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Prévia do ${widget.receipt.type.label.toLowerCase()}'),
    ),
    body: Column(
      children: [
        Expanded(
          child: PdfPreview(
            build: (_) => _preview,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            pdfFileName: '${widget.receipt.type.databaseValue}-previa.pdf',
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Salvando...' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
