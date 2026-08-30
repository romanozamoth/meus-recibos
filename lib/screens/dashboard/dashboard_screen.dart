import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/models/dashboard_summary.dart';
import 'package:meus_recibos/screens/dashboard/dashboard_controller.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Painel')),
      body: controller.loading && controller.summary == null
          ? const Center(child: CircularProgressIndicator())
          : controller.error != null && controller.summary == null
          ? _ErrorState(message: controller.error!, onRetry: controller.load)
          : RefreshIndicator(
              onRefresh: controller.load,
              child: _DashboardContent(summary: controller.summary!),
            ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Resumo de ${_monthLabel(DateTime.now())}',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(
                width: width,
                label: 'Faturado',
                value: CurrencyUtils.format(summary.billed),
                icon: Icons.payments_outlined,
                color: AppColors.proof,
              ),
              _MetricCard(
                width: width,
                label: 'A receber',
                value: CurrencyUtils.format(summary.receivable),
                icon: Icons.schedule_outlined,
                color: AppColors.budget,
              ),
              _MetricCard(
                width: width,
                label: 'Documentos',
                value: summary.documentCount.toString(),
                icon: Icons.description_outlined,
                color: AppColors.receipt,
              ),
              _MetricCard(
                width: width,
                label: 'Clientes ativos',
                value: summary.activeClients.toString(),
                icon: Icons.people_outline,
                color: AppColors.primary,
              ),
            ],
          );
        },
      ),
      const _SectionTitle('Documentos por tipo'),
      Card(
        child: Column(
          children: [
            _TypeLine(
              icon: Icons.receipt_long_outlined,
              color: AppColors.receipt,
              label: 'Recibos',
              value: summary.receiptCount,
            ),
            const Divider(height: 1),
            _TypeLine(
              icon: Icons.request_quote_outlined,
              color: AppColors.budget,
              label: 'Orçamentos',
              value: summary.budgetCount,
            ),
            const Divider(height: 1),
            _TypeLine(
              icon: Icons.verified_outlined,
              color: AppColors.proof,
              label: 'Comprovantes',
              value: summary.proofCount,
            ),
          ],
        ),
      ),
      const _SectionTitle('Top clientes do ano'),
      Card(
        child: summary.topClients.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Ainda não há recebimentos neste ano.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            : Column(
                children: summary.topClients.indexed.map((entry) {
                  final (index, client) = entry;
                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(client.name),
                        trailing: Text(
                          CurrencyUtils.format(client.total),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (index < summary.topClients.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
      ),
      const SizedBox(height: 16),
    ],
  );

  String _monthLabel(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${months[date.month - 1]} de ${date.year}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 126,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    ),
  );
}

class _TypeLine extends StatelessWidget {
  const _TypeLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(label),
    trailing: Text(
      value.toString(),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}
