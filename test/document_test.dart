import 'package:flutter_test/flutter_test.dart';
import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/core/utils/quantity_utils.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/models/document_item.dart';

void main() {
  group('CurrencyUtils', () {
    test('converte entrada brasileira para centavos', () {
      expect(CurrencyUtils.tryParseCents('95'), 9500);
      expect(CurrencyUtils.tryParseCents('95,50'), 9550);
      expect(CurrencyUtils.tryParseCents('R\$ 1.234,56'), 123456);
    });

    test('formata centavos em reais', () {
      expect(CurrencyUtils.format(9500), 'R\$ 95,00');
      expect(CurrencyUtils.format(123456), 'R\$ 1.234,56');
    });
  });

  test('calcula item sem usar ponto flutuante monetário', () {
    final quantity = QuantityUtils.tryParseMillis('1,5');
    expect(quantity, 1500);
    expect(QuantityUtils.calculateTotal(quantity!, 1000), 1500);
    expect(QuantityUtils.formatMillis(quantity), '1,5');
  });

  test('Document preserva snapshot do cliente e valores no SQLite', () {
    final now = DateTime.utc(2026, 8, 30, 14);
    final document = AppDocument(
      id: 4,
      number: 'REC-001/2026',
      sequence: 1,
      year: 2026,
      type: DocumentType.receipt,
      profileId: 1,
      clientName: 'Cliente avulso',
      clientDocument: '12345678901',
      clientAddress: 'Rua Teste, 10',
      date: now,
      serviceDescription: 'Serviço realizado',
      paymentMethod: 'PIX',
      subtotal: 10000,
      discount: 500,
      total: 9500,
      status: 'paid',
      createdAt: now,
      updatedAt: now,
      items: const [
        DocumentItem(
          description: 'Serviço',
          quantityMillis: 1000,
          unit: 'un',
          unitPrice: 10000,
          total: 10000,
        ),
      ],
    );

    final restored = AppDocument.fromMap(
      document.toMap(),
      items: document.items,
    );

    expect(restored.number, 'REC-001/2026');
    expect(restored.type, DocumentType.receipt);
    expect(restored.clientId, isNull);
    expect(restored.clientName, 'Cliente avulso');
    expect(restored.total, 9500);
    expect(restored.items.single.quantityMillis, 1000);
  });

  test('Comprovante preserva o vínculo com o orçamento original', () {
    final now = DateTime.utc(2026, 8, 30);
    final proof = AppDocument(
      number: 'COMP-001/2026',
      type: DocumentType.proof,
      profileId: 1,
      clientName: 'Cliente',
      date: now,
      serviceDescription: 'Serviço',
      paymentMethod: 'PIX',
      subtotal: 5000,
      discount: 0,
      total: 5000,
      status: 'paid',
      sourceDocumentId: 42,
      createdAt: now,
      updatedAt: now,
    );

    final restored = AppDocument.fromMap(proof.toMap());

    expect(restored.type, DocumentType.proof);
    expect(restored.sourceDocumentId, 42);
  });
}
