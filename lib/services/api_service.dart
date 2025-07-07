import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/menu.dart';
import '../models/transaction.dart';
import '../models/dashboard.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  static const String baseUrl = 'http://192.168.100.163:8080/api/v1';
  static const String publicBaseUrl = 'http://192.168.100.163:8080/api/v1/public';
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String? _authToken;

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (e) {
        errorMessage = 'Request failed with status ${response.statusCode}';
      }
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  // Auth methods
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getAuthToken() async {
    if (_authToken != null) return _authToken;
    _authToken = await _storage.read(key: 'auth_token');
    return _authToken;
  }

  static Future<void> clearAuthToken() async {
    _authToken = null;
    await _storage.delete(key: 'auth_token');
  }

  // Authentication API
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'username': email,
        'password': password,
      }),
    );

    print('Login response status: ${response.statusCode}'); // Debug output
    print('Login response body: ${response.body}'); // Debug output
    
    final data = _handleResponse(response);
    print('Parsed login data: $data'); // Debug output
    
    if (data['token'] != null) {
      await setAuthToken(data['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    return _handleResponse(response);
  }

  static Future<User> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  static Future<User> updateProfile(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _getHeaders(),
      body: json.encode(userData),
    );

    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  // Menu API
  static Future<List<Category>> getCategories({bool usePublicEndpoint = false}) async {
    try {
      final url = usePublicEndpoint 
          ? '$publicBaseUrl/menu/categories'
          : '$baseUrl/menu/categories';
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: !usePublicEndpoint),
      );

      // Handle response directly since categories API returns a direct array
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final data = json.decode(response.body);

        // According to API docs, categories are returned as direct array
        if (data is List) {
          return (data as List).map((category) => Category.fromJson(category)).toList();
        }
        return [];
      } else {
        String errorMessage = 'Request failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Request failed with status ${response.statusCode}';
        }
        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      return []; // Return empty list instead of throwing error
    }
  }

  static Future<List<MenuItem>> getMenuItems({bool usePublicEndpoint = false}) async {
    final url = usePublicEndpoint 
        ? '$publicBaseUrl/menu/items'
        : '$baseUrl/menu/items';
    
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(includeAuth: !usePublicEndpoint),
    );

    final data = _handleResponse(response);
    print('Menu Items API Response: $data');
    // According to API docs, menu items are returned in data object
    final itemsData = data['data'] as List?;
    if (itemsData == null) {
      print('Menu items data field is null, returning empty');
      return [];
    }
    print('Menu items received: ${itemsData.length} items');
    
    return itemsData
        .map((item) => MenuItem.fromJson(item))
        .toList();
  }

  static Future<List<AddOn>> getAddOns({bool usePublicEndpoint = false}) async {
    
    try {
        final url = usePublicEndpoint 
            ? '$publicBaseUrl/add-ons'
            : '$baseUrl/add-ons';
        
        final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: !usePublicEndpoint),
        );

        // Handle response - add-ons API returns data wrapped in an object with "data" field
        if (response.statusCode >= 200 && response.statusCode < 300) {
            if (response.body.isEmpty) return [];
            final jsonData = json.decode(response.body);
            
            
            // Add-ons API returns data in {"data": [...], "limit": 10, "page": 1, "total": 12} format
            if (jsonData is Map<String, dynamic> && jsonData['data'] is List) {
                final data = jsonData['data'] as List;
                return data.map((addOn) => AddOn.fromJson(addOn)).toList();
            }
            return [];
        } else {
            String errorMessage = 'Request failed';
            try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
            } catch (e) {
            errorMessage = 'Request failed with status ${response.statusCode}';
            }
            throw ApiException(errorMessage, response.statusCode);
        }
    } catch (e) {
        return []; // Return empty list instead of throwing error
    }
  }

  static Future<Category> createCategory(Map<String, dynamic> categoryData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: await _getHeaders(),
      body: json.encode(categoryData),
    );

    final data = _handleResponse(response);
    return Category.fromJson(data);
  }

  static Future<MenuItem> createMenuItem(Map<String, dynamic> itemData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/menu/items'),
      headers: await _getHeaders(),
      body: json.encode(itemData),
    );

    final data = _handleResponse(response);
    return MenuItem.fromJson(data);
  }

  static Future<AddOn> createAddOn(Map<String, dynamic> addOnData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-ons'),
      headers: await _getHeaders(),
      body: json.encode(addOnData),
    );

    final data = _handleResponse(response);
    return AddOn.fromJson(data);
  }

  static Future<Category> updateCategory(int id, Map<String, dynamic> categoryData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _getHeaders(),
      body: json.encode(categoryData),
    );

    final data = _handleResponse(response);
    return Category.fromJson(data);
  }

  static Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  static Future<MenuItem> updateMenuItem(int id, Map<String, dynamic> itemData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/menu/items/$id'),
      headers: await _getHeaders(),
      body: json.encode(itemData),
    );

    final data = _handleResponse(response);
    return MenuItem.fromJson(data);
  }

  static Future<void> deleteMenuItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/menu/items/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  static Future<AddOn> updateAddOn(int id, Map<String, dynamic> addOnData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/add-ons/$id'),
      headers: await _getHeaders(),
      body: json.encode(addOnData),
    );

    final data = _handleResponse(response);
    return AddOn.fromJson(data);
  }

  static Future<void> deleteAddOn(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/add-ons/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  // Transaction API
  static Future<List<PaymentMethod>> getPaymentMethods({bool usePublicEndpoint = false}) async {
    final url = usePublicEndpoint 
        ? '$publicBaseUrl/payment-methods'
        : '$baseUrl/payment-methods';
    
    print('ApiService: Calling payment methods API: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(includeAuth: !usePublicEndpoint),
    );

    print('ApiService: Payment methods response status: ${response.statusCode}');
    print('ApiService: Payment methods response body: ${response.body}');

    // Handle response differently for payment methods since they return a direct array
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print('ApiService: Payment methods response body is empty, returning empty list');
        return [];
      }
      
      final data = json.decode(response.body);
      print('ApiService: Parsed payment methods data: $data');
      
      // According to API docs, payment methods are returned as direct array
      if (data is List) {
        final methods = (data as List).map((method) => PaymentMethod.fromJson(method)).toList();
        print('ApiService: Converted ${methods.length} payment methods');
        return methods;
      }
      print('ApiService: Payment methods data is not a List, returning empty');
      return [];
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (e) {
        errorMessage = 'Request failed with status ${response.statusCode}';
      }
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  static Future<List<Transaction>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    print('Transactions API Response: $data');
    // According to API docs, transactions are returned in data object
    final transactionsData = data['data'] as List?;
    if (transactionsData == null) {
      print('Transactions data field is null, returning empty');
      return [];
    }
    print('Transactions received: ${transactionsData.length} items');
    
    return transactionsData
        .map((transaction) => Transaction.fromJson(transaction))
        .toList();
  }

  static Future<Transaction> getTransaction(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    return Transaction.fromJson(data);
  }

  static Future<Transaction> createTransaction(Map<String, dynamic> transactionData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: await _getHeaders(),
      body: json.encode(transactionData),
    );

    final data = _handleResponse(response);
    return Transaction.fromJson(data);
  }

  static Future<Transaction> payTransaction(int id, String paymentMethodCode) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id/pay'),
      headers: await _getHeaders(),
      body: json.encode({
        'payment_method': paymentMethodCode,
      }),
    );

    final data = _handleResponse(response);
    return Transaction.fromJson(data);
  }

  static Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  // Expense API
  static Future<List<Expense>> getExpenses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/expenses'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    // According to API docs, expenses are returned in data object
    final expensesData = data['data'] as List?;
    if (expensesData == null) return [];
    
    return expensesData
        .map((expense) => Expense.fromJson(expense))
        .toList();
  }

  static Future<Expense> createExpense(Map<String, dynamic> expenseData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: await _getHeaders(),
      body: json.encode(expenseData),
    );

    final data = _handleResponse(response);
    return Expense.fromJson(data);
  }

  // Dashboard API
  static Future<DashboardStats> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/stats'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    return DashboardStats.fromJson(data);
  }

  static Future<SalesReport> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '$baseUrl/dashboard/sales-report';
    final queryParams = <String, String>{};
    
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    if (queryParams.isNotEmpty) {
      url += '?${Uri(queryParameters: queryParams).query}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    return SalesReport.fromJson(data);
  }

  static Future<List<TopSellingItem>> getProfitAnalysis() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/profit-analysis'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    return (data['top_selling_items'] as List?)
        ?.map((item) => TopSellingItem.fromJson(item))
        .toList() ?? [];
  }
}
