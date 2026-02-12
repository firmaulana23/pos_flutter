import 'package:flutter_pos/models/menu.dart';

class DashboardData {
  final double totalSales;
  final int totalOrders;
  final int pendingOrders;
  final int paidOrders;
  final List<SalesChartData> salesChart;
  final List<SalesByPaymentMethod> salesByPaymentMethod;

  DashboardData({
    required this.totalSales,
    required this.totalOrders,
    required this.pendingOrders,
    required this.paidOrders,
    required this.salesChart,
    required this.salesByPaymentMethod,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      paidOrders: json['paid_orders'] ?? 0,
      salesChart: (json['sales_chart'] as List?)
              ?.map((item) => SalesChartData.fromJson(item))
              .toList() ??
          [],
      salesByPaymentMethod: (json['sales_by_payment_method'] as List?)
              ?.map((item) => SalesByPaymentMethod.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class SalesChartData {
  final DateTime date;
  final double amount;
  final int orders;

  SalesChartData(
      {required this.date, required this.amount, required this.orders});

  factory SalesChartData.fromJson(Map<String, dynamic> json) {
    return SalesChartData(
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      orders: json['orders'],
    );
  }
}

class SalesByPaymentMethod {
  final String paymentMethod;
  final double totalSales;

  SalesByPaymentMethod({
    required this.paymentMethod,
    required this.totalSales,
  });

  factory SalesByPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SalesByPaymentMethod(
      paymentMethod: json['payment_method'],
      totalSales: (json['total_sales'] as num).toDouble(),
    );
  }
}