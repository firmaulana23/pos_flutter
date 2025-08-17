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
  static const String baseUrl = 'http://192.168.100.175:8080/api/v1';
  static const String publicBaseUrl = 'http://192.168.100.175:8080/api/v1/public';
  
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
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        print('API Error Details: $errorData');
      } catch (e) {
        print('API Error: Could not decode response body: ${response.body}');
      }
      final fullError = 'Request failed with status ${response.statusCode}: $errorMessage (URL: ${response.request?.url})';
      print(fullError);
      throw ApiException(fullError, response.statusCode);
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
      
      print('Add-ons API: Calling URL: $url (usePublicEndpoint: $usePublicEndpoint)');
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: !usePublicEndpoint),
      );

      print('Add-ons API: Response status: ${response.statusCode}');
      print('Add-ons API: Response body: ${response.body}');

      // Handle response - add-ons API returns data wrapped in an object with "data" field
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final jsonData = json.decode(response.body);
        
        print('Add-ons API Response: $jsonData');
        
        // Add-ons API returns data in {"data": [...], "limit": 10, "page": 1, "total": 12} format
        if (jsonData is Map<String, dynamic> && jsonData['data'] is List) {
          final data = jsonData['data'] as List;
          print('Add-ons received: ${data.length} items');
          return data.map((addOn) => AddOn.fromJson(addOn)).toList();
        }
        
        print('Add-ons not received in expected format, returning empty');
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
      print('Add-ons API Error: $e - returning empty list');
      return []; // Return empty list instead of throwing error
    }
  }

  static Future<Category> createCategory(Map<String, dynamic> categoryData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/menu/categories'),
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

  // Add menu items to an existing add-on
  static Future<void> addMenuItemsToAddOn(int addOnId, List<int> menuItemIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-ons/$addOnId/menu-items'),
      headers: await _getHeaders(),
      body: json.encode({'menu_item_ids': menuItemIds}),
    );

    _handleResponse(response);
  }

  // Remove menu items from an add-on
  static Future<void> removeMenuItemsFromAddOn(int addOnId, List<int> menuItemIds) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/add-ons/$addOnId/menu-items'),
      headers: await _getHeaders(),
      body: json.encode({'menu_item_ids': menuItemIds}),
    );

    _handleResponse(response);
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

  static Future<List<Transaction>> getTransactions({int? limit}) async {
    String url = '$baseUrl/transactions';
    if (limit != null) {
      url += '?limit=$limit';
    }

    final response = await http.get(
      Uri.parse(url),
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

  // Get all transactions with optional date filter (defaults to today)
  static Future<List<Transaction>> getAllTransactions({
    DateTime? startDate,
    DateTime? endDate,
    bool todayOnly = true,
  }) async {
    String url = '$baseUrl/transactions?limit=100'; // High limit to get all
    
    // If todayOnly is true and no dates provided, use today's date
    if (todayOnly && startDate == null && endDate == null) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      url += '&start_date=${todayStart.toIso8601String().split('T')[0]}';
      url += '&end_date=${todayEnd.toIso8601String().split('T')[0]}';
    } else {
      // Use provided dates
      if (startDate != null) {
        url += '&start_date=${startDate.toIso8601String().split('T')[0]}';
      }
      if (endDate != null) {
        url += '&end_date=${endDate.toIso8601String().split('T')[0]}';
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    final transactionsData = data['data'] as List?;
    if (transactionsData == null) {
      return [];
    }
    
    return transactionsData
        .map((transaction) => Transaction.fromJson(transaction))
        .toList();
  }

  // Get today's transactions only
  static Future<List<Transaction>> getTodayTransactions() async {
    return getAllTransactions(todayOnly: true);
  }

  // Get transactions for a specific date range
  static Future<List<Transaction>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getAllTransactions(
      startDate: startDate,
      endDate: endDate,
      todayOnly: false,
    );
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

  // Add a new item to a pending transaction
  static Future<TransactionItem> addItemToTransaction(int transactionId, Map<String, dynamic> itemData) async {
    print('API Service: Adding item to transaction #$transactionId: $itemData');
    
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/$transactionId/items'),
      headers: await _getHeaders(),
      body: json.encode(itemData),
    );

    print('API Service: Add item response status: ${response.statusCode}');
    print('API Service: Add item response body: ${response.body}');
    
    final data = _handleResponse(response);
    print('API Service: Add item parsed response: $data');
    return TransactionItem.fromJson(data);
  }

  // Update an existing transaction item
  static Future<TransactionItem> updateTransactionItem(int transactionId, int itemId, Map<String, dynamic> updateData) async {
    print('API Service: Updating item #$itemId in transaction #$transactionId: $updateData');
    
    // Using the correct endpoint as per API docs
    final url = '$baseUrl/transactions/$transactionId/items/$itemId';
    print('API Service: Using URL: $url');
    
    final headers = await _getHeaders();
    print('API Service: Headers: $headers');
    
    final jsonBody = json.encode(updateData);
    print('API Service: Request body: $jsonBody');
    
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonBody,
      );

      print('API Service: Update item response status: ${response.statusCode}');
      print('API Service: Update item response body: ${response.body}');
      
      // Special handling for 404 errors to be more descriptive
      if (response.statusCode == 404) {
        print('API Service: 404 Not Found - Check if the transaction ID ($transactionId) and item ID ($itemId) are correct');
        throw ApiException('Resource not found: The transaction or item does not exist or you do not have permission to update it', 404);
      }
      
      final data = _handleResponse(response);
      print('API Service: Update item parsed response: $data');
      return TransactionItem.fromJson(data);
    } catch (e) {
      print('API Service: Exception during API call: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to update transaction item: $e');
    }
  }

  // Delete a transaction item
  static Future<void> deleteTransactionItem(int transactionId, int itemId) async {
    print('API Service: Deleting item #$itemId from transaction #$transactionId');
    
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$transactionId/items/$itemId'),
      headers: await _getHeaders(),
    );

    print('API Service: Delete item response status: ${response.statusCode}');
    _handleResponse(response);
  }

  // Update basic transaction information
  static Future<Transaction> updateTransaction(int id, Map<String, dynamic> updateData) async {
    print('API Service: Updating transaction #$id: $updateData');
    
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _getHeaders(),
      body: json.encode(updateData),
    );

    print('API Service: Update transaction response status: ${response.statusCode}');
    print('API Service: Update transaction response body: ${response.body}');
    
    final data = _handleResponse(response);
    return Transaction.fromJson(data);
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

  // Get add-ons for a specific menu item (includes both global and menu-specific add-ons)
  static Future<List<AddOn>> getMenuItemAddOns(int menuItemId, {bool usePublicEndpoint = true}) async {
    try {
      final url = usePublicEndpoint 
          ? '$publicBaseUrl/menu-item-add-ons/$menuItemId'
          : '$baseUrl/menu-item-add-ons/$menuItemId';
      
      print('Menu Item Add-ons API: Calling URL: $url (usePublicEndpoint: $usePublicEndpoint)');
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: !usePublicEndpoint),
      );

      print('Menu Item Add-ons API: Response status: ${response.statusCode}');
      print('Menu Item Add-ons API: Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final jsonData = json.decode(response.body);
        
        print('Menu Item Add-ons API Response: $jsonData');
        
        // API returns {"add_ons": [...], "menu_item": {...}}
        if (jsonData is Map<String, dynamic> && jsonData['add_ons'] is List) {
          final data = jsonData['add_ons'] as List;
          print('Menu Item Add-ons received: ${data.length} items');
          return data.map((addOn) => AddOn.fromJson(addOn)).toList();
        }
        
        print('Menu Item Add-ons not received in expected format, returning empty');
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
      print('Menu Item Add-ons API Error: $e - returning empty list');
      return [];
    }
  }

  // Get menu items associated with a specific add-on
  static Future<List<MenuItem>> getAddOnMenuItems(int addOnId, {bool usePublicEndpoint = true}) async {
    try {
      final url = usePublicEndpoint 
          ? '$publicBaseUrl/add-ons/$addOnId'
          : '$baseUrl/add-ons/$addOnId';
      
      print('Add-on Menu Items API: Calling URL: $url (usePublicEndpoint: $usePublicEndpoint)');
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: !usePublicEndpoint),
      );

      print('Add-on Menu Items API: Response status: ${response.statusCode}');
      print('Add-on Menu Items API: Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final jsonData = json.decode(response.body);
        
        print('Add-on Menu Items API Response: $jsonData');
        
        // API returns add-on data with menu_items array
        if (jsonData is Map<String, dynamic> && jsonData['menu_items'] is List) {
          final data = jsonData['menu_items'] as List;
          print('Add-on Menu Items received: ${data.length} items');
          return data.map((menuItem) => MenuItem.fromJson(menuItem)).toList();
        }
        
        print('Add-on Menu Items not received in expected format, returning empty');
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
      print('Add-on Menu Items API Error: $e - returning empty list');
      return [];
    }
  }

}
