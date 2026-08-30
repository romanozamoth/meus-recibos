import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/utils/document_utils.dart';
import 'package:meus_recibos/models/client.dart';
import 'package:meus_recibos/screens/clients/client_controller.dart';
import 'package:meus_recibos/screens/clients/client_form_screen.dart';
import 'package:provider/provider.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({this.selectionMode = false, super.key});

  final bool selectionMode;

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late final TextEditingController _search;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final controller = context.read<ClientController>();
    final initialQuery = widget.selectionMode ? '' : controller.query;
    _search = TextEditingController(text: initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadClients(query: initialQuery);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => context.read<ClientController>().loadClients(query: value),
    );
  }

  Future<void> _openForm([Client? client]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)),
    );
  }

  Future<void> _delete(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text(
          'O cliente “${client.name}” será removido deste dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ClientController>().delete(client.id!);
    }
  }

  void _select(Client client) {
    if (widget.selectionMode) {
      Navigator.pop(context, client);
    } else {
      _openForm(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClientController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Selecionar Cliente' : 'Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo cliente',
            onPressed: _openForm,
          ),
        ],
      ),
      floatingActionButton: controller.clients.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _openForm,
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: TextField(
              controller: _search,
              onChanged: _searchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou CPF/CNPJ',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                          context.read<ClientController>().loadClients(
                            query: '',
                          );
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _buildContent(controller)),
        ],
      ),
    );
  }

  Widget _buildContent(ClientController controller) {
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.error!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.loadClients,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (controller.clients.isEmpty) {
      return _EmptyClients(
        hasQuery: controller.query.isNotEmpty,
        onCreate: _openForm,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.loadClients,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: controller.clients.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final client = controller.clients[index];
          return _ClientCard(
            client: client,
            selectionMode: widget.selectionMode,
            onTap: () => _select(client),
            onEdit: () => _openForm(client),
            onDelete: () => _delete(client),
          );
        },
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.selectionMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Client client;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final document = DocumentUtils.format(client.document);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.person_outline, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (document.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        document,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                    if (client.address != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        client.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (selectionMode)
                const Icon(Icons.chevron_right)
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients({required this.hasQuery, required this.onCreate});
  final bool hasQuery;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off : Icons.people_outline,
            size: 72,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 18),
          Text(
            hasQuery
                ? 'Nenhum cliente encontrado'
                : 'Você ainda não tem clientes',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery
                ? 'Tente buscar usando outro nome ou documento.'
                : 'Cadastre clientes para reutilizar os dados nos documentos.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Novo Cliente'),
            ),
          ],
        ],
      ),
    ),
  );
}
