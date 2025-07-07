import 'package:flutter/foundation.dart';
import '../models/dashboard.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  DashboardStats? _dashboardStats;
  SalesReport? _salesReport;
  List<TopSellingItem> _topSellingItems = [];
  bool _isLoading = false;
  String? _error;

  DashboardStats? get dashboardStats => _dashboardStats;
  SalesReport? get salesReport => _salesReport;
  List<TopSellingItem> get topSellingItems => _topSellingItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadDashboardStats() async {
    try {
      _setLoading(true);
      _setError(null);

      _dashboardStats = await ApiService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      _salesReport = await ApiService.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTopSellingItems() async {
    try {
      _setLoading(true);
      _setError(null);

      _topSellingItems = await ApiService.getProfitAnalysis();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAllDashboardData() async {
    try {
      _setLoading(true);
      _setError(null);

      final futures = await Future.wait([
        ApiService.getDashboardStats(),
        ApiService.getSalesReport(),
        ApiService.getProfitAnalysis(),
      ]);

      _dashboardStats = futures[0] as DashboardStats;
      _salesReport = futures[1] as SalesReport;
      _topSellingItems = futures[2] as List<TopSellingItem>;

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }
}
