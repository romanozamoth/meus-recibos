import 'package:meus_recibos/core/database/app_database.dart';
import 'package:meus_recibos/models/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<DashboardSummary> load(DateTime reference) async {
    final database = await _appDatabase.database;
    final monthStart = _date(DateTime(reference.year, reference.month));
    final nextMonth = _date(DateTime(reference.year, reference.month + 1));
    final yearStart = _date(DateTime(reference.year));
    final nextYear = _date(DateTime(reference.year + 1));

    final totals = (await database.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type IN ('receipt', 'proof') THEN total ELSE 0 END), 0) AS billed,
        COALESCE(SUM(CASE WHEN type = 'budget' AND status IN ('pending', 'approved') THEN total ELSE 0 END), 0) AS receivable,
        COUNT(*) AS document_count,
        COUNT(DISTINCT CASE
          WHEN client_id IS NOT NULL THEN 'id:' || client_id
          ELSE 'name:' || LOWER(TRIM(client_name))
        END) AS active_clients,
        SUM(CASE WHEN type = 'receipt' THEN 1 ELSE 0 END) AS receipt_count,
        SUM(CASE WHEN type = 'budget' THEN 1 ELSE 0 END) AS budget_count,
        SUM(CASE WHEN type = 'proof' THEN 1 ELSE 0 END) AS proof_count
      FROM documents
      WHERE date >= ? AND date < ?
      ''',
      [monthStart, nextMonth],
    )).single;

    final rankingRows = await database.rawQuery(
      '''
      SELECT client_name, SUM(total) AS total
      FROM documents
      WHERE date >= ? AND date < ?
        AND type IN ('receipt', 'proof')
      GROUP BY LOWER(TRIM(client_name))
      ORDER BY total DESC, client_name COLLATE NOCASE ASC
      LIMIT 5
      ''',
      [yearStart, nextYear],
    );

    return DashboardSummary(
      billed: _integer(totals['billed']),
      receivable: _integer(totals['receivable']),
      documentCount: _integer(totals['document_count']),
      activeClients: _integer(totals['active_clients']),
      receiptCount: _integer(totals['receipt_count']),
      budgetCount: _integer(totals['budget_count']),
      proofCount: _integer(totals['proof_count']),
      topClients: rankingRows
          .map(
            (row) => ClientRanking(
              name: row['client_name'] as String,
              total: _integer(row['total']),
            ),
          )
          .toList(),
    );
  }

  int _integer(Object? value) => (value as num?)?.toInt() ?? 0;

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
