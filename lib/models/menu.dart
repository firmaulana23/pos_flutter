class Category {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MenuItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double cogs; // Cost of Goods Sold
  final int categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? category;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.cogs,
    required this.categoryId,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      cogs: (json['cogs'] as num).toDouble(),
      categoryId: json['category_id'],
      imageUrl: json['image_url'],
      isAvailable: json['is_available'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      category: json['category'] != null 
          ? Category.fromJson(json['category']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'cogs': cogs,
      'category_id': categoryId,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get margin {
    if (price == 0) return 0;
    return ((price - cogs) / price) * 100;
  }

  double get profit => price - cogs;

  MenuItem copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    double? cogs,
    int? categoryId,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cogs: cogs ?? this.cogs,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}

class AddOn {
  final int id;
  final int? menuItemId;  // null for global add-ons, specific ID for menu-specific add-ons
  final String name;
  final String? description;
  final double price;
  final double? cogs;
  final double? margin;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddOn({
    required this.id,
    this.menuItemId,
    required this.name,
    this.description,
    required this.price,
    this.cogs,
    this.margin,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddOn.fromJson(Map<String, dynamic> json) {
    return AddOn(
      id: json['id'],
      menuItemId: json['menu_item_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      cogs: json['cogs'] != null ? (json['cogs'] as num).toDouble() : null,
      margin: json['margin'] != null ? (json['margin'] as num).toDouble() : null,
      isAvailable: json['is_available'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'name': name,
      'description': description,
      'price': price,
      'cogs': cogs,
      'margin': margin,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AddOn copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddOn(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
