import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/models/document_item.dart';
import 'package:meus_recibos/screens/receipt/receipt_detail_screen.dart';

void main() {
  testWidgets('detalhe não causa overflow em tela pequena com fonte ampliada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: ReceiptDetailScreen(receipt: _document()),
      ),
    );

    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Imprimir'),
      find.byType(Scrollable),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

AppDocument _document() {
  final now = DateTime.utc(2026, 9, 3);
  return AppDocument(
    id: 1,
    number: 'REC-001/2026',
    sequence: 1,
    year: 2026,
    type: DocumentType.receipt,
    profileId: 1,
    clientName: 'Cliente com nome propositalmente muito extenso',
    clientAddress: 'Endereço longo para validar quebra de linha em tela pequena',
    date: now,
    serviceDescription: '',
    paymentMethod: 'Transferência bancária',
    subtotal: 123456789,
    discount: 0,
    total: 123456789,
    status: 'paid',
    createdAt: now,
    updatedAt: now,
    items: const [
      DocumentItem(
        description: 'Descrição extensa de um item para validar o layout',
        quantityMillis: 1000,
        unit: 'serv.',
        unitPrice: 123456789,
        total: 123456789,
      ),
    ],
  );
}
