import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/core/utils/date_utils.dart';
import 'package:meus_recibos/core/widgets/app_card.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/screens/documents/document_controller.dart';
import 'package:meus_recibos/screens/home/app_drawer.dart';
import 'package:meus_recibos/screens/profiles/profile_controller.dart';
import 'package:meus_recibos/screens/profiles/profile_form_screen.dart';
import 'package:meus_recibos/screens/receipt/receipt_detail_screen.dart';
import 'package:meus_recibos/screens/receipt/receipt_form_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A criação de documentos começa nos próximos marcos.'),
      ),
    );
  }

  void _newReceipt(BuildContext context, bool hasProfile) {
    if (!hasProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um perfil antes de criar um recibo.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfileController>();
    final documents = context.watch<DocumentController>();
    final profile = profiles.defaultProfile;
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Recibos')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              profile == null
                  ? 'Olá!'
                  : 'Olá, ${profile.tradeName ?? profile.name}!',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Crie e organize seus documentos profissionais.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            if (!profiles.loading && profile == null) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Complete seu perfil para personalizar seus documentos.',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileFormScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            _DashboardBanner(onTap: () => _comingSoon(context)),
            const SizedBox(height: 26),
            Text(
              'Criar documento',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocumentCard(
                      width: width,
                      title: 'Recibo',
                      subtitle: 'Pagamento recebido',
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.receipt,
                      onTap: () => _newReceipt(context, profile != null),
                    ),
                    _DocumentCard(
                      width: width,
                      title: 'Orçamento',
                      subtitle: 'Proposta de serviço',
                      icon: Icons.request_quote_outlined,
                      color: AppColors.budget,
                      onTap: () => _comingSoon(context),
                    ),
                    _DocumentCard(
                      width: width,
                      title: 'Comprovante',
                      subtitle: 'Serviço prestado',
                      icon: Icons.verified_outlined,
                      color: AppColors.proof,
                      onTap: () => _comingSoon(context),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Documentos recentes',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            if (documents.loading)
              const Center(child: CircularProgressIndicator())
            else if (documents.recentReceipts.isEmpty)
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 42,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Nenhum documento criado',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Seus documentos aparecerão aqui.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...documents.recentReceipts
                  .take(5)
                  .map(
                    (receipt) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentReceiptCard(receipt: receipt),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _RecentReceiptCard extends StatelessWidget {
  const _RecentReceiptCard({required this.receipt});

  final AppDocument receipt;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptDetailScreen(receipt: receipt),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.receipt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.clientName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${receipt.number} • ${AppDateUtils.format(receipt.date)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.format(receipt.total),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Abrir →',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashboardBanner extends StatelessWidget {
  const _DashboardBanner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primaryDark,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.dashboard_rounded, color: Colors.white),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Painel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Acompanhe seus resultados em breve',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 158,
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
