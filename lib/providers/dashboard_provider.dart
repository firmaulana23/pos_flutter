import 'package:flutter/foundation.dart';
import '../models/dashboard.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  DashboardData? get dashboardData => _dashboardData;
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

  Future<void> loadDashboardStats(DateTime date) async {
    try {
      _setLoading(true);
      _setError(null);

      _dashboardData = await ApiService.getDashboardData(date);
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
