class DocumentItem {
  const DocumentItem({
    this.id,
    this.documentId,
    required this.description,
    required this.quantityMillis,
    required this.unit,
    required this.unitPrice,
    required this.total,
  });

  final int? id;
  final int? documentId;
  final String description;
  final int quantityMillis;
  final String unit;
  final int unitPrice;
  final int total;

  Map<String, Object?> toMap() => {
    'id': id,
    'document_id': documentId,
    'description': description,
    'quantity_millis': quantityMillis,
    'unit': unit,
    'unit_price': unitPrice,
    'total': total,
  };

  factory DocumentItem.fromMap(Map<String, Object?> map) => DocumentItem(
    id: map['id'] as int?,
    documentId: map['document_id'] as int?,
    description: map['description'] as String,
    quantityMillis: map['quantity_millis'] as int,
    unit: map['unit'] as String,
    unitPrice: map['unit_price'] as int,
    total: map['total'] as int,
  );
}
