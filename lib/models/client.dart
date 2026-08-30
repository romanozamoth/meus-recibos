class Client {
  const Client({
    this.id,
    required this.name,
    this.document,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? document;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'document': document,
    'address': address,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Client.fromMap(Map<String, Object?> map) => Client(
    id: map['id'] as int?,
    name: map['name'] as String,
    document: map['document'] as String?,
    address: map['address'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
