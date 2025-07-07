import 'package:flutter/foundation.dart';
import '../models/menu.dart' as menu_models;
import '../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  List<menu_models.Category> _categories = [];
  List<menu_models.MenuItem> _menuItems = [];
  List<menu_models.AddOn> _addOns = [];
  bool _isLoading = false;
  String? _error;

  List<menu_models.Category> get categories => _categories;
  List<menu_models.MenuItem> get menuItems => _menuItems;
  List<menu_models.AddOn> get addOns => _addOns;
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

  Future<void> loadAllMenuData({bool usePublicEndpoint = false}) async {
    try {
      _setLoading(true);
      _setError(null);

      print('MenuProvider: Loading all menu data with usePublicEndpoint: $usePublicEndpoint');

      final futures = await Future.wait([
        ApiService.getCategories(usePublicEndpoint: usePublicEndpoint),
        ApiService.getMenuItems(usePublicEndpoint: usePublicEndpoint),
        ApiService.getAddOns(usePublicEndpoint: usePublicEndpoint),
      ]);

      _categories = futures[0] as List<menu_models.Category>;
      _menuItems = futures[1] as List<menu_models.MenuItem>;
      _addOns = futures[2] as List<menu_models.AddOn>;

      print('MenuProvider: Loaded ${_categories.length} categories, ${_menuItems.length} menu items, ${_addOns.length} add-ons');

      notifyListeners();
    } catch (e) {
      print('MenuProvider: Error loading menu data: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategories({bool usePublicEndpoint = false}) async {
    try {
      _setLoading(true);
      _setError(null);

      _categories = await ApiService.getCategories(usePublicEndpoint: usePublicEndpoint);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMenuItems({bool usePublicEndpoint = false}) async {
    try {
      _setLoading(true);
      _setError(null);

      _menuItems = await ApiService.getMenuItems(usePublicEndpoint: usePublicEndpoint);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAddOns({bool usePublicEndpoint = false}) async {
    try {
      _setLoading(true);
      _setError(null);

      _addOns = await ApiService.getAddOns(usePublicEndpoint: usePublicEndpoint);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  List<menu_models.MenuItem> getMenuItemsByCategory(int categoryId) {
    return _menuItems.where((item) => item.categoryId == categoryId).toList();
  }

  List<menu_models.MenuItem> getAvailableMenuItems() {
    return _menuItems.where((item) => item.isAvailable).toList();
  }

  List<menu_models.AddOn> getAvailableAddOns() {
    return _addOns.where((addOn) => addOn.isAvailable).toList();
  }

  // Extract categories from menu items if categories endpoint is not available
  List<menu_models.Category> getCategoriesFromMenuItems() {
    final Map<int, menu_models.Category> categoriesMap = {};
    
    for (final menuItem in _menuItems) {
      if (menuItem.category != null && !categoriesMap.containsKey(menuItem.category!.id)) {
        categoriesMap[menuItem.category!.id] = menuItem.category!;
      }
    }
    
    return categoriesMap.values.toList();
  }

  // Fallback method to get categories - try API first, then extract from menu items
  List<menu_models.Category> get categoriesWithFallback {
    if (_categories.isNotEmpty) {
      return _categories;
    }
    return getCategoriesFromMenuItems();
  }

  menu_models.MenuItem? getMenuItemById(int id) {
    try {
      return _menuItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  menu_models.AddOn? getAddOnById(int id) {
    try {
      return _addOns.firstWhere((addOn) => addOn.id == id);
    } catch (e) {
      return null;
    }
  }

  menu_models.Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> createCategory(String name, {String? description}) async {
    try {
      _setLoading(true);
      _setError(null);

      final categoryData = {
        'name': name,
        if (description != null) 'description': description,
      };

      final newCategory = await ApiService.createCategory(categoryData);
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createMenuItem({
    required String name,
    required double price,
    required double cogs,
    required int categoryId,
    String? description,
    String? imageUrl,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final itemData = {
        'name': name,
        'price': price,
        'cogs': cogs,
        'category_id': categoryId,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      final newItem = await ApiService.createMenuItem(itemData);
      _menuItems.add(newItem);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createAddOn({
    required String name,
    required double price,
    String? description,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final addOnData = {
        'name': name,
        'price': price,
        if (description != null) 'description': description,
      };

      final newAddOn = await ApiService.createAddOn(addOnData);
      _addOns.add(newAddOn);
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

  // Category CRUD methods - removed duplicate, keeping the first version

  Future<void> updateCategory(int id, String name, String description) async {
    try {
      _setLoading(true);
      _setError(null);

      final categoryData = {
        'name': name,
        'description': description,
      };

      await ApiService.updateCategory(id, categoryData);
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(name: name, description: description);
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      // Also remove menu items in this category
      _menuItems.removeWhere((item) => item.categoryId == id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // MenuItem CRUD methods - removed duplicate, keeping the first version

  Future<void> updateMenuItem(int id, String name, int categoryId, String description, double price, bool isAvailable) async {
    try {
      _setLoading(true);
      _setError(null);

      final itemData = {
        'name': name,
        'category_id': categoryId,
        'description': description,
        'price': price,
        'is_available': isAvailable,
      };

      await ApiService.updateMenuItem(id, itemData);
      final index = _menuItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _menuItems[index] = _menuItems[index].copyWith(
          name: name,
          categoryId: categoryId,
          description: description,
          price: price,
          isAvailable: isAvailable,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMenuItem(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.deleteMenuItem(id);
      _menuItems.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // AddOn CRUD methods
  Future<void> updateAddOn(int id, String name, String description, double price, bool isAvailable) async {
    try {
      _setLoading(true);
      _setError(null);

      final addOnData = {
        'name': name,
        'description': description,
        'price': price,
        'is_available': isAvailable,
      };

      await ApiService.updateAddOn(id, addOnData);
      final index = _addOns.indexWhere((addOn) => addOn.id == id);
      if (index != -1) {
        _addOns[index] = _addOns[index].copyWith(
          name: name,
          description: description,
          price: price,
          isAvailable: isAvailable,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAddOn(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.deleteAddOn(id);
      _addOns.removeWhere((addOn) => addOn.id == id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
