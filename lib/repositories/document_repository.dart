import 'package:meus_recibos/core/database/app_database.dart';
import 'package:meus_recibos/core/utils/quantity_utils.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/models/document_item.dart';
import 'package:meus_recibos/services/document_number_service.dart';
import 'package:sqflite/sqflite.dart';

class DocumentRepository {
  DocumentRepository(this._appDatabase, this._numberService);

  final AppDatabase _appDatabase;
  final DocumentNumberService _numberService;

  Future<AppDocument> saveNew(AppDocument document) async {
    if (document.items.isEmpty) {
      throw ArgumentError('O documento deve possuir pelo menos um item.');
    }
    final database = await _appDatabase.database;
    return database.transaction((transaction) async {
      final items = document.items
          .map(
            (item) => DocumentItem(
              description: item.description.trim(),
              quantityMillis: item.quantityMillis,
              unit: item.unit.trim(),
              unitPrice: item.unitPrice,
              total: QuantityUtils.calculateTotal(
                item.quantityMillis,
                item.unitPrice,
              ),
            ),
          )
          .toList();
      final subtotal = items.fold<int>(0, (sum, item) => sum + item.total);
      if (document.discount < 0 || document.discount > subtotal) {
        throw ArgumentError('O desconto deve estar entre zero e o subtotal.');
      }
      final number = await _numberService.next(
        transaction,
        document.type,
        document.date.year,
      );
      final values = document.toMap()
        ..remove('id')
        ..['number'] = number.value
        ..['sequence'] = number.sequence
        ..['year'] = number.year
        ..['subtotal'] = subtotal
        ..['total'] = subtotal - document.discount;
      final id = await transaction.insert('documents', values);
      for (final item in items) {
        final itemValues = item.toMap()
          ..remove('id')
          ..['document_id'] = id;
        await transaction.insert('document_items', itemValues);
      }
      return (await _findById(transaction, id))!;
    });
  }

  Future<List<AppDocument>> findRecent({
    DocumentType? type,
    int limit = 10,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'documents',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type.databaseValue],
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    final documents = <AppDocument>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final items = await _findItems(database, id);
      documents.add(AppDocument.fromMap(row, items: items));
    }
    return documents;
  }

  Future<AppDocument?> findById(int id) async {
    final database = await _appDatabase.database;
    return _findById(database, id);
  }

  Future<AppDocument> updatePdfPath(int id, String pdfPath) async {
    final database = await _appDatabase.database;
    await database.update(
      'documents',
      {'pdf_path': pdfPath, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    return (await _findById(database, id))!;
  }

  Future<AppDocument> updateStatus(int id, String status) async {
    const allowed = {'pending', 'approved', 'paid', 'rejected'};
    if (!allowed.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Status inválido');
    }
    final database = await _appDatabase.database;
    await database.update(
      'documents',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    return (await _findById(database, id))!;
  }

  Future<AppDocument?> _findById(DatabaseExecutor database, int id) async {
    final rows = await database.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    final items = await _findItems(database, id);
    return AppDocument.fromMap(rows.single, items: items);
  }

  Future<List<DocumentItem>> _findItems(
    DatabaseExecutor database,
    int documentId,
  ) async {
    final rows = await database.query(
      'document_items',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'id ASC',
    );
    return rows.map(DocumentItem.fromMap).toList();
  }
}
