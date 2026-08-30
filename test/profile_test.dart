import 'package:flutter_test/flutter_test.dart';
import 'package:meus_recibos/models/profile.dart';

void main() {
  test('Profile mantém os dados ao converter para e do SQLite', () {
    final createdAt = DateTime.utc(2026, 8, 29, 20);
    final profile = Profile(
      id: 7,
      name: 'Empresa Teste',
      tradeName: 'Teste',
      documentType: 'CNPJ',
      documentNumber: '12.345.678/0001-90',
      serviceType: 'Manutenção',
      phone: '(11) 99999-9999',
      email: 'contato@teste.com',
      address: 'Rua Teste, 10',
      city: 'São Paulo',
      state: 'SP',
      logoPath: '/dados/logo.png',
      color: 0xFF1769AA,
      isDefault: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final restored = Profile.fromMap(profile.toMap());

    expect(restored.id, 7);
    expect(restored.name, 'Empresa Teste');
    expect(restored.documentNumber, '12.345.678/0001-90');
    expect(restored.isDefault, isTrue);
    expect(restored.color, 0xFF1769AA);
    expect(restored.createdAt, createdAt);
  });
}
