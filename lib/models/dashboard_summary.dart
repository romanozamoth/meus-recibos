class DashboardSummary {
  const DashboardSummary({
    required this.billed,
    required this.receivable,
    required this.documentCount,
    required this.activeClients,
    required this.receiptCount,
    required this.budgetCount,
    required this.proofCount,
    required this.topClients,
  });

  final int billed;
  final int receivable;
  final int documentCount;
  final int activeClients;
  final int receiptCount;
  final int budgetCount;
  final int proofCount;
  final List<ClientRanking> topClients;
}

class ClientRanking {
  const ClientRanking({required this.name, required this.total});
  final String name;
  final int total;
}
