import 'menu.dart';
import 'user.dart';

class TransactionItem {
  final int? id;
  final int transactionId;
  final int menuItemId;
  final int quantity;
  final double price;
  final List<TransactionAddOn> addOns;
  final MenuItem? menuItem;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.menuItemId,
    required this.quantity,
    required this.price,
    required this.addOns,
    this.menuItem,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      transactionId: json['transaction_id'],
      menuItemId: json['menu_item_id'],
      quantity: json['quantity'],
      price: (json['unit_price'] as num).toDouble(), // API uses 'unit_price'
      addOns: (json['add_ons'] as List?)
          ?.map((addOn) => TransactionAddOn.fromJson(addOn))
          .toList() ?? [],
      menuItem: json['menu_item'] != null 
          ? MenuItem.fromJson(json['menu_item']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'price': price,
      'add_ons': addOns.map((addOn) => addOn.toJson()).toList(),
    };
  }

  double get subtotal => price * quantity;
  double get addOnsTotal => addOns.fold(0, (sum, addOn) => sum + addOn.totalPrice);
  double get total => subtotal + addOnsTotal;
}

class TransactionAddOn {
  final int? id;
  final int transactionItemId;
  final int addOnId;
  final int quantity;
  final double price;
  final AddOn? addOn;

  TransactionAddOn({
    this.id,
    required this.transactionItemId,
    required this.addOnId,
    required this.quantity,
    required this.price,
    this.addOn,
  });

  factory TransactionAddOn.fromJson(Map<String, dynamic> json) {
    return TransactionAddOn(
      id: json['id'],
      transactionItemId: json['transaction_item_id'],
      addOnId: json['add_on_id'],
      quantity: json['quantity'],
      price: (json['unit_price'] as num).toDouble(), // API uses 'unit_price'
      addOn: json['add_on'] != null 
          ? AddOn.fromJson(json['add_on']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_item_id': transactionItemId,
      'add_on_id': addOnId,
      'quantity': quantity,
      'price': price,
    };
  }

  double get totalPrice => price * quantity;
}

class PaymentMethod {
  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive,
    };
  }
}

class Transaction {
  final int? id;
  final String? transactionNo;
  final String status; // 'pending' or 'paid'
  final double subTotal;
  final double tax;
  final double discount;
  final double total;
  final String? paymentMethod; // Payment method as string from API
  final int? userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final List<TransactionItem> items;
  final User? user;

  Transaction({
    this.id,
    this.transactionNo,
    required this.status,
    required this.subTotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.paymentMethod,
    this.userId,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
    required this.items,
    this.user,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      transactionNo: json['transaction_no'],
      status: json['status'],
      subTotal: (json['sub_total'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['payment_method'], // String from API
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at']) 
          : null,
      items: (json['items'] as List?)
          ?.map((item) => TransactionItem.fromJson(item))
          .toList() ?? [],
      user: json['user'] != null 
          ? User.fromJson(json['user']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'total': total,
      'payment_method': paymentMethod,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get addOnsTotal => items.fold(0, (sum, item) => sum + item.addOnsTotal);
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

// Cart models for POS functionality
class CartItem {
  final MenuItem menuItem;
  int quantity;
  final List<CartAddOn> addOns;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    List<CartAddOn>? addOns,
  }) : addOns = addOns ?? [];

  double get subtotal => menuItem.price * quantity;
  double get addOnsTotal => addOns.fold(0, (sum, addOn) => sum + addOn.totalPrice);
  double get total => subtotal + addOnsTotal;

  CartItem copyWith({
    int? quantity,
    List<CartAddOn>? addOns,
  }) {
    return CartItem(
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      addOns: addOns ?? List.from(this.addOns),
    );
  }
}

class CartAddOn {
  final AddOn addOn;
  final int quantity;

  CartAddOn({
    required this.addOn,
    this.quantity = 1,
  });

  double get totalPrice => addOn.price * quantity;
}
