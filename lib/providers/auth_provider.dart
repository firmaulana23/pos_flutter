import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  User? get currentUser => _user; // Alias for user to make code more readable
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.login(email, password);
      print('Login response: $response'); // Debug output

      // Check if the response has a 'user' field or if the user data is at the root level
      try {
        if (response['user'] != null) {
          print('Parsing user from response[user]');
          _user = User.fromJson(response['user']);
        } else {
          print('Parsing user from response directly');
          _user = User.fromJson(response);
        }
      } catch (userParseError) {
        print('Error parsing user: $userParseError');
        print('Available response keys: ${response.keys.toList()}');
        // Fallback: create a minimal user with just the available data
        _user = User(
          id: 1,
          email: email,
          name: email,
          role: 'cashier',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e'); // Debug output
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.register(email, password, name);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await ApiService.getAuthToken();
      if (token != null) {
        _user = await ApiService.getProfile();
        notifyListeners();
      }
    } catch (e) {
      // Token might be expired, clear it
      await logout();
    }
  }

  Future<void> logout() async {
    _user = null;
    await ApiService.clearAuthToken();
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> userData) async {
    try {
      _setLoading(true);
      _setError(null);

      _user = await ApiService.updateProfile(userData);
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
