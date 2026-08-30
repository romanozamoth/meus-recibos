import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:meus_recibos/core/database/app_database.dart';
import 'package:meus_recibos/screens/clients/client_controller.dart';
import 'package:meus_recibos/screens/dashboard/dashboard_controller.dart';
import 'package:meus_recibos/screens/documents/document_controller.dart';
import 'package:meus_recibos/screens/profiles/profile_controller.dart';
import 'package:meus_recibos/services/backup_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupService(AppDatabase.instance);
  bool _working = false;

  Future<void> _export() async {
    setState(() => _working = true);
    try {
      final file = await _service.createBackup();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/zip')],
          title: 'Backup Meus Recibos',
          text: 'Backup local do aplicativo Meus Recibos',
        ),
      );
    } catch (_) {
      if (mounted) _message('Não foi possível criar o backup.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _chooseRestore() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mrbak'],
    );
    if (files.isEmpty || !mounted) return;
    final bytes = await files.single.readAsBytes();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
          'Os perfis, clientes e documentos atuais serão substituídos pelos dados deste backup. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _restore(bytes);
  }

  Future<void> _restore(Uint8List bytes) async {
    setState(() => _working = true);
    try {
      await _service.restore(bytes);
      if (!mounted) return;
      await Future.wait([
        context.read<ProfileController>().loadProfiles(),
        context.read<ClientController>().loadClients(),
        context.read<DocumentController>().loadRecentReceipts(),
        context.read<DashboardController>().load(),
      ]);
      if (mounted) _message('Backup restaurado com sucesso.');
    } on FormatException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Não foi possível restaurar este backup.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup e restauração')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'O backup é criado localmente e inclui banco de dados, logos e PDFs. Guarde o arquivo em um local seguro.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _working ? null : _export,
          icon: const Icon(Icons.ios_share_outlined),
          label: const Text('Exportar backup'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _working ? null : _chooseRestore,
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Restaurar de um arquivo'),
        ),
        if (_working) ...[
          const SizedBox(height: 28),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 10),
          const Center(child: Text('Processando dados locais...')),
        ],
        const SizedBox(height: 28),
        const Text(
          'Importante: não edite ou renomeie o conteúdo interno do arquivo de backup.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    ),
  );
}
