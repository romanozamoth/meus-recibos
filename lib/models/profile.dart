class Profile {
  const Profile({
    this.id,
    required this.name,
    this.tradeName,
    required this.documentType,
    required this.documentNumber,
    required this.serviceType,
    required this.phone,
    this.email,
    this.address,
    required this.city,
    required this.state,
    this.pixKey,
    this.pixType,
    this.logoPath,
    required this.color,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? tradeName;
  final String documentType;
  final String documentNumber;
  final String serviceType;
  final String phone;
  final String? email;
  final String? address;
  final String city;
  final String state;
  final String? pixKey;
  final String? pixType;
  final String? logoPath;
  final int color;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'trade_name': tradeName,
    'document_type': documentType,
    'document_number': documentNumber,
    'service_type': serviceType,
    'phone': phone,
    'email': email,
    'address': address,
    'city': city,
    'state': state,
    'pix_key': pixKey,
    'pix_type': pixType,
    'logo_path': logoPath,
    'color': color,
    'is_default': isDefault ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Profile.fromMap(Map<String, Object?> map) => Profile(
    id: map['id'] as int?,
    name: map['name'] as String,
    tradeName: map['trade_name'] as String?,
    documentType: map['document_type'] as String,
    documentNumber: map['document_number'] as String,
    serviceType: map['service_type'] as String,
    phone: map['phone'] as String,
    email: map['email'] as String?,
    address: map['address'] as String?,
    city: map['city'] as String,
    state: map['state'] as String,
    pixKey: map['pix_key'] as String?,
    pixType: map['pix_type'] as String?,
    logoPath: map['logo_path'] as String?,
    color: map['color'] as int,
    isDefault: map['is_default'] == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
