import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/widgets/app_button.dart';
import 'package:meus_recibos/core/widgets/app_input.dart';
import 'package:meus_recibos/models/client.dart';
import 'package:meus_recibos/repositories/client_repository.dart';
import 'package:meus_recibos/screens/clients/client_controller.dart';
import 'package:provider/provider.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({this.client, super.key});

  final Client? client;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _document;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.client?.name);
    _document = TextEditingController(text: widget.client?.document);
    _address = TextEditingController(text: widget.client?.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _document.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await context.read<ClientController>().save(
        Client(
          id: widget.client?.id,
          name: _name.text.trim(),
          document: _optional(_document.text),
          address: _optional(_address.text),
          createdAt: widget.client?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on DuplicateClientDocumentException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Já existe um cliente com este CPF/CNPJ.'),
          ),
        );
        setState(() => _saving = false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o cliente.')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'Novo Cliente' : 'Editar Cliente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Cadastre os dados básicos para reutilizá-los nos próximos documentos.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            AppInput(
              controller: _name,
              label: 'Nome do cliente',
              icon: Icons.person_outline,
              validator: _required,
            ),
            const SizedBox(height: 14),
            AppInput(
              controller: _document,
              label: 'CPF/CNPJ (opcional)',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Endereço (opcional)',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 42),
                  child: Icon(Icons.location_on_outlined),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Salvar Cliente',
              icon: Icons.save_outlined,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
