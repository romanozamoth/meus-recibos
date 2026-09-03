import 'package:flutter_test/flutter_test.dart';
import 'package:meus_recibos/core/database/app_database.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/models/document_item.dart';
import 'package:meus_recibos/repositories/document_repository.dart';
import 'package:meus_recibos/services/document_number_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final appDatabase = AppDatabase.instance;
  late DocumentRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await appDatabase.close();
    await deleteDatabase(await appDatabase.filePath);
    final database = await appDatabase.database;
    final now = DateTime.utc(2026, 9, 3).toIso8601String();
    await database.insert('profiles', {
      'name': 'Empresa Teste',
      'document_type': 'CNPJ',
      'document_number': '12345678000190',
      'service_type': 'Serviços',
      'phone': '11999999999',
      'city': 'São Paulo',
      'state': 'SP',
      'color': 0xFF1769AA,
      'is_default': 1,
      'created_at': now,
      'updated_at': now,
    });
    repository = DocumentRepository(appDatabase, DocumentNumberService());
  });

  tearDown(() async => appDatabase.close());

  test('edição preserva número e substitui itens e valores', () async {
    final original = await repository.saveNew(
      _document(type: DocumentType.receipt),
    );

    final updated = await repository.updateExisting(
      _document(
        id: original.id,
        number: original.number,
        sequence: original.sequence,
        year: original.year,
        type: original.type,
        clientName: 'Cliente editado',
        discount: 500,
        items: const [
          DocumentItem(
            description: 'Item atualizado',
            quantityMillis: 2000,
            unit: 'h',
            unitPrice: 6000,
            total: 0,
          ),
        ],
      ),
    );

    expect(updated.id, original.id);
    expect(updated.number, original.number);
    expect(updated.sequence, original.sequence);
    expect(updated.clientName, 'Cliente editado');
    expect(updated.items, hasLength(1));
    expect(updated.items.single.description, 'Item atualizado');
    expect(updated.subtotal, 12000);
    expect(updated.total, 11500);
  });

  test('exclusão remove itens e preserva comprovante sem vínculo', () async {
    final budget = await repository.saveNew(
      _document(type: DocumentType.budget, status: 'paid'),
    );
    final proof = await repository.saveNew(
      _document(
        type: DocumentType.proof,
        sourceDocumentId: budget.id,
      ),
    );

    await repository.delete(budget.id!);

    expect(await repository.findById(budget.id!), isNull);
    final preservedProof = await repository.findById(proof.id!);
    expect(preservedProof, isNotNull);
    expect(preservedProof!.sourceDocumentId, isNull);
    final database = await appDatabase.database;
    final orphanItems = await database.query(
      'document_items',
      where: 'document_id = ?',
      whereArgs: [budget.id],
    );
    expect(orphanItems, isEmpty);
  });
}

AppDocument _document({
  int? id,
  String? number,
  int? sequence,
  int? year,
  required DocumentType type,
  String clientName = 'Cliente',
  String status = 'paid',
  int discount = 0,
  int? sourceDocumentId,
  List<DocumentItem>? items,
}) {
  final now = DateTime.utc(2026, 9, 3);
  final documentItems = items ??
      const [
        DocumentItem(
          description: 'Serviço',
          quantityMillis: 1000,
          unit: 'un',
          unitPrice: 10000,
          total: 10000,
        ),
      ];
  return AppDocument(
    id: id,
    number: number,
    sequence: sequence,
    year: year,
    type: type,
    profileId: 1,
    clientName: clientName,
    date: now,
    serviceDescription: '',
    paymentMethod: 'PIX',
    subtotal: documentItems.fold(0, (sum, item) => sum + item.total),
    discount: discount,
    total: 0,
    status: status,
    sourceDocumentId: sourceDocumentId,
    createdAt: now,
    updatedAt: now,
    items: documentItems,
  );
}
