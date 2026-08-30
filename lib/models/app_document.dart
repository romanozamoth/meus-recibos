import 'package:meus_recibos/models/document_item.dart';

enum DocumentType { receipt, budget, proof }

extension DocumentTypeDatabase on DocumentType {
  String get databaseValue => switch (this) {
    DocumentType.receipt => 'receipt',
    DocumentType.budget => 'budget',
    DocumentType.proof => 'proof',
  };

  String get label => switch (this) {
    DocumentType.receipt => 'Recibo',
    DocumentType.budget => 'Orçamento',
    DocumentType.proof => 'Comprovante',
  };

  String get prefix => switch (this) {
    DocumentType.receipt => 'REC',
    DocumentType.budget => 'ORC',
    DocumentType.proof => 'COMP',
  };

  static DocumentType fromDatabase(String value) => switch (value) {
    'receipt' => DocumentType.receipt,
    'budget' => DocumentType.budget,
    'proof' => DocumentType.proof,
    _ => throw ArgumentError.value(
      value,
      'value',
      'Tipo de documento inválido',
    ),
  };
}

class AppDocument {
  const AppDocument({
    this.id,
    this.number,
    this.sequence,
    this.year,
    required this.type,
    required this.profileId,
    this.clientId,
    required this.clientName,
    this.clientDocument,
    this.clientAddress,
    required this.date,
    this.dueDate,
    this.validUntil,
    required this.serviceDescription,
    required this.paymentMethod,
    this.notes,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    this.sourceDocumentId,
    this.pdfPath,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  final int? id;
  final String? number;
  final int? sequence;
  final int? year;
  final DocumentType type;
  final int profileId;
  final int? clientId;
  final String clientName;
  final String? clientDocument;
  final String? clientAddress;
  final DateTime date;
  final DateTime? dueDate;
  final DateTime? validUntil;
  final String serviceDescription;
  final String paymentMethod;
  final String? notes;
  final int subtotal;
  final int discount;
  final int total;
  final String status;
  final int? sourceDocumentId;
  final String? pdfPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DocumentItem> items;

  Map<String, Object?> toMap() => {
    'id': id,
    'number': number,
    'sequence': sequence,
    'year': year,
    'type': type.databaseValue,
    'profile_id': profileId,
    'client_id': clientId,
    'client_name': clientName,
    'client_document': clientDocument,
    'client_address': clientAddress,
    'date': _dateOnly(date),
    'due_date': dueDate == null ? null : _dateOnly(dueDate!),
    'valid_until': validUntil == null ? null : _dateOnly(validUntil!),
    'service_description': serviceDescription,
    'payment_method': paymentMethod,
    'notes': notes,
    'subtotal': subtotal,
    'discount': discount,
    'total': total,
    'status': status,
    'source_document_id': sourceDocumentId,
    'pdf_path': pdfPath,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory AppDocument.fromMap(
    Map<String, Object?> map, {
    List<DocumentItem> items = const [],
  }) => AppDocument(
    id: map['id'] as int?,
    number: map['number'] as String?,
    sequence: map['sequence'] as int?,
    year: map['year'] as int?,
    type: DocumentTypeDatabase.fromDatabase(map['type'] as String),
    profileId: map['profile_id'] as int,
    clientId: map['client_id'] as int?,
    clientName: map['client_name'] as String,
    clientDocument: map['client_document'] as String?,
    clientAddress: map['client_address'] as String?,
    date: DateTime.parse(map['date'] as String),
    dueDate: _parseDate(map['due_date']),
    validUntil: _parseDate(map['valid_until']),
    serviceDescription: map['service_description'] as String,
    paymentMethod: map['payment_method'] as String,
    notes: map['notes'] as String?,
    subtotal: map['subtotal'] as int,
    discount: map['discount'] as int,
    total: map['total'] as int,
    status: map['status'] as String,
    sourceDocumentId: map['source_document_id'] as int?,
    pdfPath: map['pdf_path'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    items: items,
  );

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
