class Expense {
  final int id;
  final String type; // 'raw_material' or 'operational'
  final String description;
  final double amount;
  final DateTime date;
  final int? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      type: json['type'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isRawMaterial => type == 'raw_material';
  bool get isOperational => type == 'operational';
}

class DashboardStats {
  final double todaySales;
  final double todayProfit;
  final int todayTransactions;
  final double monthSales;
  final double monthProfit;
  final int monthTransactions;
  final double todayExpenses;
  final double monthExpenses;

  DashboardStats({
    required this.todaySales,
    required this.todayProfit,
    required this.todayTransactions,
    required this.monthSales,
    required this.monthProfit,
    required this.monthTransactions,
    required this.todayExpenses,
    required this.monthExpenses,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0.0,
      todayProfit: (json['today_profit'] as num?)?.toDouble() ?? 0.0,
      todayTransactions: json['today_transactions'] ?? 0,
      monthSales: (json['month_sales'] as num?)?.toDouble() ?? 0.0,
      monthProfit: (json['month_profit'] as num?)?.toDouble() ?? 0.0,
      monthTransactions: json['month_transactions'] ?? 0,
      todayExpenses: (json['today_expenses'] as num?)?.toDouble() ?? 0.0,
      monthExpenses: (json['month_expenses'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convenience getters for UI compatibility
  double get totalSales => todaySales;
  int get totalOrders => todayTransactions;
  int get totalCustomers => todayTransactions; // Simplified assumption
  double get averageOrderValue => totalOrders > 0 ? totalSales / totalOrders : 0.0;
}

class SalesReport {
  final List<SalesReportItem> items;
  final double totalSales;
  final double totalProfit;
  final int totalTransactions;

  SalesReport({
    required this.items,
    required this.totalSales,
    required this.totalProfit,
    required this.totalTransactions,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      items: (json['items'] as List?)
          ?.map((item) => SalesReportItem.fromJson(item))
          .toList() ?? [],
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: json['total_transactions'] ?? 0,
    );
  }

  // List-like behavior for UI compatibility
  bool get isEmpty => items.isEmpty;
  int get length => items.length;
  SalesReportItem operator [](int index) => items[index];
  Iterable<T> map<T>(T Function(SalesReportItem) f) => items.map(f);
}

class SalesReportItem {
  final String date;
  final double sales;
  final double profit;
  final int transactions;

  SalesReportItem({
    required this.date,
    required this.sales,
    required this.profit,
    required this.transactions,
  });

  factory SalesReportItem.fromJson(Map<String, dynamic> json) {
    return SalesReportItem(
      date: json['date'],
      sales: (json['sales'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      transactions: json['transactions'] ?? 0,
    );
  }

  // Convenience getters for UI compatibility
  double get totalSales => sales;
  int get hour {
    // Extract hour from date string, assuming format "YYYY-MM-DD HH:00:00" or similar
    try {
      final dateTime = DateTime.parse(date);
      return dateTime.hour;
    } catch (e) {
      return 0;
    }
  }
}

class TopSellingItem {
  final int menuItemId;
  final String menuItemName;
  final int quantity;
  final double revenue;

  TopSellingItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.revenue,
  });

  factory TopSellingItem.fromJson(Map<String, dynamic> json) {
    return TopSellingItem(
      menuItemId: json['menu_item_id'],
      menuItemName: json['menu_item_name'],
      quantity: json['quantity'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  // Convenience getters for UI compatibility
  String get itemName => menuItemName;
  int get quantitySold => quantity;
  double get totalRevenue => revenue;
}
