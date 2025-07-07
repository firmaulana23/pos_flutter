class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing User from JSON: $json'); // Debug output
    
    // Handle different date field formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('Error parsing date: $dateValue');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return User(
      id: (json['id'] ?? 0) is int ? json['id'] ?? 0 : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email']?.toString() ?? json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? 'User',
      role: json['role']?.toString() ?? 'cashier',
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';
  bool get canManageUsers => isAdmin;
  bool get canManageMenu => isAdmin || isManager;
  bool get canViewReports => isAdmin || isManager;
}
