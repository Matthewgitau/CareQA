enum Role {
  admin('admin'),
  carer('carer'),
  client('client'),
  warehouse('warehouse'),
  family('family');

  final String value;

  const Role(this.value);

  factory Role.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'carer':
        return Role.carer;
      case 'client':
        return Role.client;
      case 'warehouse':
        return Role.warehouse;
      case 'family':
        return Role.family;
      default:
        throw ArgumentError('Invalid role: $value');
    }
  }

  @override
  String toString() => value;

  bool get isAdmin => this == Role.admin;
  bool get isCarer => this == Role.carer;
  bool get isClient => this == Role.client;
  bool get isWarehouse => this == Role.warehouse;
  bool get isFamily => this == Role.family;

  static List<Role> get all => [Role.admin, Role.carer, Role.client, Role.warehouse, Role.family];
}