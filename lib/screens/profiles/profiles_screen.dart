import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/models/profile.dart';
import 'package:meus_recibos/screens/profiles/profile_controller.dart';
import 'package:meus_recibos/screens/profiles/profile_form_screen.dart';
import 'package:provider/provider.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  Future<void> _openForm(BuildContext context, [Profile? profile]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileFormScreen(profile: profile)),
    );
  }

  Future<void> _delete(BuildContext context, Profile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir perfil?'),
        content: Text(
          'O perfil “${profile.name}” será removido deste dispositivo.',
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
    if (confirmed == true && context.mounted) {
      await context.read<ProfileController>().delete(profile.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Perfis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo perfil',
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      floatingActionButton: controller.profiles.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : controller.error != null
          ? _ErrorState(
              message: controller.error!,
              onRetry: controller.loadProfiles,
            )
          : controller.profiles.isEmpty
          ? _EmptyState(onCreate: () => _openForm(context))
          : RefreshIndicator(
              onRefresh: controller.loadProfiles,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: controller.profiles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final profile = controller.profiles[index];
                  return _ProfileCard(
                    profile: profile,
                    onEdit: () => _openForm(context, profile),
                    onSetDefault: () => controller.setDefault(profile.id!),
                    onDelete: () => _delete(context, profile),
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.badge_outlined,
            size: 72,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 18),
          const Text(
            'Nenhum perfil cadastrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre sua empresa ou seus dados profissionais.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Novo Perfil'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });
  final Profile profile;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final logo = profile.logoPath;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Color(profile.color).withValues(alpha: 0.12),
                backgroundImage: logo != null && File(logo).existsSync()
                    ? FileImage(File(logo))
                    : null,
                child: logo == null || !File(logo).existsSync()
                    ? Icon(Icons.business_rounded, color: Color(profile.color))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (profile.isDefault) ...[
                          const SizedBox(width: 8),
                          const _DefaultBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.documentType} • ${profile.documentNumber}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    Text(
                      '${profile.city} - ${profile.state}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'default') onSetDefault();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (!profile.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Definir como padrão'),
                    ),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFE3F2FD),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'Padrão',
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
