import 'package:meus_recibos/models/app_document.dart';
import 'package:sqflite/sqflite.dart';

class DocumentNumber {
  const DocumentNumber({
    required this.value,
    required this.sequence,
    required this.year,
  });

  final String value;
  final int sequence;
  final int year;
}

class DocumentNumberService {
  Future<DocumentNumber> next(
    DatabaseExecutor database,
    DocumentType type,
    int year,
  ) async {
    final result = await database.rawQuery(
      'SELECT MAX(sequence) AS last_sequence FROM documents WHERE type = ? AND year = ?',
      [type.databaseValue, year],
    );
    final last = result.single['last_sequence'] as int? ?? 0;
    final sequence = last + 1;
    final formatted = sequence.toString().padLeft(3, '0');
    return DocumentNumber(
      value: '${type.prefix}-$formatted/$year',
      sequence: sequence,
      year: year,
    );
  }
}
