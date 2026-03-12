import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/menu.dart';
import '../models/transaction.dart';
import '../models/dashboard.dart';
import '../models/member.dart';
import '../models/promo.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  // Primary URLs (local IP)
  static const String _primaryBaseUrl = 'http://localhost:8080/api/v1';
  static const String _primaryPublicBaseUrl =
      'http://localhost:8080/api/v1/public';

  // Backup URLs (domain-based fallback)
  static const String _backupBaseUrl =
      'https://localhost:8080/api/v1';
  static const String _backupPublicBaseUrl =
      'https://localhost:8080/api/v1/public';

  // Active base URLs — switched automatically on failure
  static String baseUrl = _primaryBaseUrl;
  static String publicBaseUrl = _primaryPublicBaseUrl;

  // Track which URL is currently active
  static bool _usingBackup = false;

  /// Executes [request]. If it throws a connection error and we are not
  /// already on the backup URL, switches to the backup and retries once.
  static Future<http.Response> _executeWithFallback(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(const Duration(seconds: 10));
      // If we previously fell back and now primary succeeds, reset (optional)
      return response;
    } on Exception catch (e) {
      // SocketException, TimeoutException, HandshakeException, etc.
      if (!_usingBackup) {
        print(
          '[ApiService] Primary URL failed ($e). Switching to backup URL...',
        );
        _usingBackup = true;
        baseUrl = _backupBaseUrl;
        publicBaseUrl = _backupPublicBaseUrl;
        try {
          final response =
              await request().timeout(const Duration(seconds: 10));
          print('[ApiService] Backup URL succeeded.');
          return response;
        } catch (e2) {
          print('[ApiService] Backup URL also failed: $e2');
          rethrow;
        }
      }
      rethrow;
    }
  }

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String? _authToken;

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
  }) async {
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
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? errorMessage;
        print('API Error Details: $errorData');
      } catch (e) {
        print('API Error: Could not decode response body: ${response.body}');
      }
      final fullError =
          'Request failed with status ${response.statusCode}: $errorMessage (URL: ${response.request?.url})';
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
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final headers = await _getHeaders(includeAuth: false);
    final body = json.encode({'username': email, 'password': password});
    final response = await _executeWithFallback(
      () => http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: body,
      ),
    );

    print('Login response status: ${response.statusCode}'); // Debug output
    print('Login response body: ${response.body}'); // Debug output

    final data = _handleResponse(response);
    print('Parsed login data: $data'); // Debug output

    final responseData = data['data'] as Map<String, dynamic>?;
    if (responseData != null && responseData['token'] != null) {
      await setAuthToken(responseData['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    final headers = await _getHeaders(includeAuth: false);
    final body = json.encode({'email': email, 'password': password, 'name': name});
    final response = await _executeWithFallback(
      () => http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: body,
      ),
    );
    return _handleResponse(response);
  }

  static Future<User> getProfile() async {
    final headers = await _getHeaders();
    final response = await _executeWithFallback(
      () => http.get(Uri.parse('$baseUrl/profile'), headers: headers),
    );

    final data = _handleResponse(response);
    final userData = data['data'] as Map<String, dynamic>? ?? data;
    return User.fromJson(userData);
  }

  static Future<User> updateProfile(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _getHeaders(),
      body: json.encode(userData),
    );

    final data = _handleResponse(response);
    final profileData = data['data'] as Map<String, dynamic>? ?? data;
    return User.fromJson(profileData);
  }

  // Menu API
  static Future<List<Category>> getCategories({
    bool usePublicEndpoint = false,
  }) async {
    try {
      final url = usePublicEndpoint
          ? '$publicBaseUrl/menu/categories'
          : '$baseUrl/menu/categories';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: !usePublicEndpoint),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final jsonData = json.decode(response.body);

        // API returns {success, message, data: [...]}
        List? categoriesList;
        if (jsonData is Map<String, dynamic> && jsonData['data'] is List) {
          categoriesList = jsonData['data'] as List;
        } else if (jsonData is List) {
          // Fallback for direct array
          categoriesList = jsonData;
        }

        if (categoriesList != null) {
          return categoriesList
              .map((category) => Category.fromJson(category))
              .toList();
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

  static Future<List<MenuItem>> getMenuItems({
    bool usePublicEndpoint = false,
  }) async {
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

    return itemsData.map((item) => MenuItem.fromJson(item)).toList();
  }

  static Future<List<AddOn>> getAddOns({bool usePublicEndpoint = false}) async {
    try {
      final url = usePublicEndpoint
          ? '$publicBaseUrl/add-ons'
          : '$baseUrl/add-ons';

      print(
        'Add-ons API: Calling URL: $url (usePublicEndpoint: $usePublicEndpoint)',
      );

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

  static Future<Category> createCategory(
    Map<String, dynamic> categoryData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/menu/categories'),
      headers: await _getHeaders(),
      body: json.encode(categoryData),
    );

    final data = _handleResponse(response);
    final categoryResult = data['data'] as Map<String, dynamic>? ?? data;
    return Category.fromJson(categoryResult);
  }

  static Future<MenuItem> createMenuItem(Map<String, dynamic> itemData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/menu/items'),
      headers: await _getHeaders(),
      body: json.encode(itemData),
    );

    final data = _handleResponse(response);
    final itemData2 = data['data'] as Map<String, dynamic>? ?? data;
    return MenuItem.fromJson(itemData2);
  }

  static Future<AddOn> createAddOn(Map<String, dynamic> addOnData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-ons'),
      headers: await _getHeaders(),
      body: json.encode(addOnData),
    );

    final data = _handleResponse(response);
    final addOnResult = data['data'] as Map<String, dynamic>? ?? data;
    return AddOn.fromJson(addOnResult);
  }

  // Add menu items to an existing add-on
  static Future<void> addMenuItemsToAddOn(
    int addOnId,
    List<int> menuItemIds,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-ons/$addOnId/menu-items'),
      headers: await _getHeaders(),
      body: json.encode({'menu_item_ids': menuItemIds}),
    );

    _handleResponse(response);
  }

  // Remove menu items from an add-on
  static Future<void> removeMenuItemsFromAddOn(
    int addOnId,
    List<int> menuItemIds,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/add-ons/$addOnId/menu-items'),
      headers: await _getHeaders(),
      body: json.encode({'menu_item_ids': menuItemIds}),
    );

    _handleResponse(response);
  }

  static Future<Category> updateCategory(
    int id,
    Map<String, dynamic> categoryData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/menu/categories/$id'),
      headers: await _getHeaders(),
      body: json.encode(categoryData),
    );

    final data = _handleResponse(response);
    final categoryResult = data['data'] as Map<String, dynamic>? ?? data;
    return Category.fromJson(categoryResult);
  }

  static Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/menu/categories/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  static Future<MenuItem> updateMenuItem(
    int id,
    Map<String, dynamic> itemData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/menu/items/$id'),
      headers: await _getHeaders(),
      body: json.encode(itemData),
    );

    final data = _handleResponse(response);
    final itemResult = data['data'] as Map<String, dynamic>? ?? data;
    return MenuItem.fromJson(itemResult);
  }

  static Future<void> deleteMenuItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/menu/items/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  static Future<AddOn> updateAddOn(
    int id,
    Map<String, dynamic> addOnData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/add-ons/$id'),
      headers: await _getHeaders(),
      body: json.encode(addOnData),
    );

    final data = _handleResponse(response);
    final addOnResult = data['data'] as Map<String, dynamic>? ?? data;
    return AddOn.fromJson(addOnResult);
  }

  static Future<void> deleteAddOn(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/add-ons/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  // Transaction API
  static Future<List<PaymentMethod>> getPaymentMethods({
    bool usePublicEndpoint = false,
  }) async {
    final url = usePublicEndpoint
        ? '$publicBaseUrl/payment-methods'
        : '$baseUrl/payment-methods';

    print('ApiService: Calling payment methods API: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(includeAuth: !usePublicEndpoint),
    );

    print(
      'ApiService: Payment methods response status: ${response.statusCode}',
    );
    print('ApiService: Payment methods response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print(
          'ApiService: Payment methods response body is empty, returning empty list',
        );
        return [];
      }

      final jsonData = json.decode(response.body);
      print('ApiService: Parsed payment methods data: $jsonData');

      // API returns {success, message, data: [...]}
      List? methodsList;
      if (jsonData is Map<String, dynamic> && jsonData['data'] is List) {
        methodsList = jsonData['data'] as List;
      } else if (jsonData is List) {
        // Fallback for direct array
        methodsList = jsonData;
      }

      if (methodsList != null) {
        final methods = methodsList
            .map((method) => PaymentMethod.fromJson(method))
            .toList();
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

  // Member & Promo API
  static Future<Member> validateMember(String cardNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/members/validate?card_number=$cardNumber'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    if (data['success'] == true && data['data'] != null) {
      return Member.fromJson(data['data']);
    } else {
      throw ApiException(data['message'] ?? 'Invalid member code');
    }
  }

  static Future<Promo> validatePromo(String promoCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/promos/validate?code=$promoCode'),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);

    if (data['success'] == true && data['data'] != null) {
      return Promo.fromJson(data['data']);
    } else {
      throw ApiException(data['message'] ?? 'Invalid promo code');
    }
  }

  // Get all transactions with optional date filter (defaults to today)
  static Future<List<Transaction>> getAllTransactions({
    DateTime? startDate,
    DateTime? endDate,
    bool todayOnly = true,
    String? customerName,
  }) async {
    String url = '$baseUrl/transactions?limit=1000'; // High limit to get all

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
    if (customerName != null && customerName.isNotEmpty) {
      url += '&customer_name=$customerName';
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
    final txData = data['data'] as Map<String, dynamic>? ?? data;
    return Transaction.fromJson(txData);
  }

  static Future<Transaction> createTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: await _getHeaders(),
      body: json.encode(transactionData),
    );
    final data = _handleResponse(response);
    final txData = data['data'] as Map<String, dynamic>? ?? data;
    return Transaction.fromJson(txData);
  }

  static Future<Transaction> payTransaction(
    int id,
    String paymentMethodCode,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id/pay'),
      headers: await _getHeaders(),
      body: json.encode({'payment_method': paymentMethodCode}),
    );

    final data = _handleResponse(response);
    final txData = data['data'] as Map<String, dynamic>? ?? data;
    return Transaction.fromJson(txData);
  }

  static Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _getHeaders(),
    );

    _handleResponse(response);
  }

  // Add a new item to a pending transaction
  static Future<TransactionItem> addItemToTransaction(
    int transactionId,
    Map<String, dynamic> itemData,
  ) async {
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
    final itemResult = data['data'] as Map<String, dynamic>? ?? data;
    return TransactionItem.fromJson(itemResult);
  }

  // Update an existing transaction item
  static Future<TransactionItem> updateTransactionItem(
    int transactionId,
    int itemId,
    Map<String, dynamic> updateData,
  ) async {
    print(
      'API Service: Updating item #$itemId in transaction #$transactionId: $updateData',
    );

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
        print(
          'API Service: 404 Not Found - Check if the transaction ID ($transactionId) and item ID ($itemId) are correct',
        );
        throw ApiException(
          'Resource not found: The transaction or item does not exist or you do not have permission to update it',
          404,
        );
      }

      final data = _handleResponse(response);
      print('API Service: Update item parsed response: $data');
      final itemResult = data['data'] as Map<String, dynamic>? ?? data;
      return TransactionItem.fromJson(itemResult);
    } catch (e) {
      print('API Service: Exception during API call: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to update transaction item: $e');
    }
  }

  // Delete a transaction item
  static Future<void> deleteTransactionItem(
    int transactionId,
    int itemId,
  ) async {
    print(
      'API Service: Deleting item #$itemId from transaction #$transactionId',
    );

    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$transactionId/items/$itemId'),
      headers: await _getHeaders(),
    );

    print('API Service: Delete item response status: ${response.statusCode}');
    _handleResponse(response);
  }

  // Update basic transaction information
  static Future<Transaction> updateTransaction(
    int id,
    Map<String, dynamic> updateData,
  ) async {
    print('API Service: Updating transaction #$id: $updateData');

    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _getHeaders(),
      body: json.encode(updateData),
    );

    print(
      'API Service: Update transaction response status: ${response.statusCode}',
    );
    print('API Service: Update transaction response body: ${response.body}');

    final data = _handleResponse(response);
    final txData = data['data'] as Map<String, dynamic>? ?? data;
    return Transaction.fromJson(txData);
  }

  // Dashboard API
  static Future<DashboardData> getDashboardData(DateTime? date) async {
    String url = '$baseUrl/dashboard/data';
    final queryParams = <String, String>{};

    if (date != null) {
      final dateString = date.toIso8601String().split('T')[0];
      queryParams['start_date'] = dateString;
      queryParams['end_date'] = dateString;
    } else {
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];
      queryParams['start_date'] = todayString;
      queryParams['end_date'] = todayString;
    }

    if (queryParams.isNotEmpty) {
      url += '?${Uri(queryParameters: queryParams).query}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final data = _handleResponse(response);
    final dashData = data['data'] as Map<String, dynamic>? ?? data;
    return DashboardData.fromJson(dashData);
  }

  // Get add-ons for a specific menu item (includes both global and menu-specific add-ons)
  static Future<List<AddOn>> getMenuItemAddOns(
    int menuItemId, {
    bool usePublicEndpoint = true,
  }) async {
    try {
      final url = usePublicEndpoint
          ? '$publicBaseUrl/menu-item-add-ons/$menuItemId'
          : '$baseUrl/menu-item-add-ons/$menuItemId';

      print(
        'Menu Item Add-ons API: Calling URL: $url (usePublicEndpoint: $usePublicEndpoint)',
      );

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

        // API returns {success, message, data: {menu_item: {...}, add_ons: [...]}}
        if (jsonData is Map<String, dynamic>) {
          // Extract from data wrapper first
          final dataWrapper = jsonData['data'] as Map<String, dynamic>? ?? jsonData;
          if (dataWrapper['add_ons'] is List) {
            final addOnsList = dataWrapper['add_ons'] as List;
            print('Menu Item Add-ons received: ${addOnsList.length} items');
            return addOnsList.map((addOn) => AddOn.fromJson(addOn)).toList();
          }
        }

        print(
          'Menu Item Add-ons not received in expected format, returning empty',
        );
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
  static Future<List<MenuItem>> getAddOnMenuItems(
    int addOnId, {
    bool usePublicEndpoint = true,
  }) async {
    try {
      final url = usePublicEndpoint
          ? '$publicBaseUrl/add-ons/$addOnId'
          : '$baseUrl/add-ons/$addOnId';

      print(
        'Add-on Menu Items API: Calling URL: $url (usePublicEndpoint: $usePublicEndpoint)',
      );

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

        // API returns {success, message, data: {..., menu_items: [...]}}
        if (jsonData is Map<String, dynamic>) {
          // Extract from data wrapper first
          final dataWrapper = jsonData['data'] as Map<String, dynamic>? ?? jsonData;
          if (dataWrapper['menu_items'] is List) {
            final menuItemsList = dataWrapper['menu_items'] as List;
            print('Add-on Menu Items received: ${menuItemsList.length} items');
            return menuItemsList.map((menuItem) => MenuItem.fromJson(menuItem)).toList();
          }
        }

        print(
          'Add-on Menu Items not received in expected format, returning empty',
        );
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
