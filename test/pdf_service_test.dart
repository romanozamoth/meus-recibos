import 'package:flutter_test/flutter_test.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/models/document_item.dart';
import 'package:meus_recibos/models/profile.dart';
import 'package:meus_recibos/services/pdf_service.dart';

void main() {
  test('gera recibo A4 offline sem exigir logo', () async {
    final now = DateTime(2026, 8, 30);
    final receipt = AppDocument(
      number: 'REC-001/2026',
      type: DocumentType.receipt,
      profileId: 1,
      clientName: 'Cliente Teste',
      date: now,
      serviceDescription: 'Serviço de teste',
      paymentMethod: 'PIX',
      subtotal: 10000,
      discount: 500,
      total: 9500,
      status: 'paid',
      createdAt: now,
      updatedAt: now,
      items: const [
        DocumentItem(
          description: 'Item de teste',
          quantityMillis: 1000,
          unit: 'un',
          unitPrice: 10000,
          total: 10000,
        ),
      ],
    );
    final profile = Profile(
      id: 1,
      name: 'Empresa Teste',
      documentType: 'CNPJ',
      documentNumber: '12345678000199',
      serviceType: 'Serviços',
      phone: '(11) 99999-9999',
      city: 'São Paulo',
      state: 'SP',
      color: 0xFF1565C0,
      isDefault: true,
      createdAt: now,
      updatedAt: now,
    );

    final bytes = await PdfService().buildReceipt(receipt, profile);

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
