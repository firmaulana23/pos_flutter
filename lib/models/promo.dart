class Promo {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String type;
  final double value;
  final bool stackable;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;

  Promo({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.type,
    required this.value,
    required this.stackable,
    required this.isActive,
    this.startAt,
    this.endAt,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id'],
      code: json['code'],
      name: json['name'] ?? '',
      description: json['description'],
      type: json['discount_type'] ?? json['type'] ?? 'fixed',
      value: (json['discount_value'] as num? ?? json['value'] as num? ?? 0.0).toDouble(),
      stackable: json['stackable'] ?? false,
      isActive: json['is_active'] ?? false,
      startAt: json['start_date'] != null ? DateTime.parse(json['start_date']) : (json['start_at'] != null ? DateTime.parse(json['start_at']) : null),
      endAt: json['end_date'] != null ? DateTime.parse(json['end_date']) : (json['end_at'] != null ? DateTime.parse(json['end_at']) : null),
    );
  }
}
