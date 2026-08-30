import 'package:flutter_test/flutter_test.dart';
import 'package:meus_recibos/core/utils/document_utils.dart';
import 'package:meus_recibos/models/client.dart';

void main() {
  test('Client mantém os dados ao converter para e do SQLite', () {
    final createdAt = DateTime.utc(2026, 8, 30, 12);
    final client = Client(
      id: 3,
      name: 'Cliente Teste',
      document: '12345678901',
      address: 'Rua Teste, 20',
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final restored = Client.fromMap(client.toMap());

    expect(restored.id, 3);
    expect(restored.name, 'Cliente Teste');
    expect(restored.document, '12345678901');
    expect(restored.address, 'Rua Teste, 20');
    expect(restored.createdAt, createdAt);
  });

  group('DocumentUtils', () {
    test('remove a máscara antes da persistência e pesquisa', () {
      expect(DocumentUtils.digitsOnly('123.456.789-01'), '12345678901');
      expect(DocumentUtils.digitsOnly('12.345.678/0001-90'), '12345678000190');
    });

    test('formata CPF e CNPJ para exibição', () {
      expect(DocumentUtils.format('12345678901'), '123.456.789-01');
      expect(DocumentUtils.format('12345678000190'), '12.345.678/0001-90');
    });
  });
}
