import 'package:flutter/foundation.dart';
import '../models/menu.dart' as menu_models;
import '../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  List<menu_models.Category> _categories = [];
  List<menu_models.MenuItem> _menuItems = [];
  List<menu_models.AddOn> _addOns = [];
  List<menu_models.AddOn> _menuItemAddOns =
      []; // Store add-ons for specific menu item
  bool _isLoading = false;
  String? _error;

  List<menu_models.Category> get categories => _categories;
  List<menu_models.MenuItem> get menuItems => _menuItems;
  List<menu_models.AddOn> get addOns => _addOns;
  List<menu_models.AddOn> get menuItemAddOns =>
      _menuItemAddOns; // Getter for menu item specific add-ons
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

      print(
        'MenuProvider: Loading all menu data with usePublicEndpoint: $usePublicEndpoint',
      );

      final futures = await Future.wait([
        ApiService.getCategories(usePublicEndpoint: usePublicEndpoint),
        ApiService.getMenuItems(usePublicEndpoint: usePublicEndpoint),
        ApiService.getAddOns(usePublicEndpoint: usePublicEndpoint),
      ]);

      _categories = futures[0] as List<menu_models.Category>;
      _menuItems = futures[1] as List<menu_models.MenuItem>;
      _addOns = futures[2] as List<menu_models.AddOn>;

      print(
        'MenuProvider: Loaded ${_categories.length} categories, ${_menuItems.length} menu items, ${_addOns.length} add-ons',
      );

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

      _categories = await ApiService.getCategories(
        usePublicEndpoint: usePublicEndpoint,
      );
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

      _menuItems = await ApiService.getMenuItems(
        usePublicEndpoint: usePublicEndpoint,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAddOns({
    bool usePublicEndpoint = false,
    bool resetError = true,
  }) async {
    try {
      _setLoading(true);
      if (resetError) _setError(null);

      print(
        'MenuProvider: Loading add-ons with usePublicEndpoint: $usePublicEndpoint',
      );

      _addOns = await ApiService.getAddOns(
        usePublicEndpoint: usePublicEndpoint,
      );
      print('MenuProvider: Loaded ${_addOns.length} add-ons');

      notifyListeners();
    } catch (e) {
      print('MenuProvider: Error loading add-ons: $e');
      _setError('Failed to load add-ons: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add method to load add-ons specific to a menu item
  Future<void> loadMenuItemAddOns(
    int menuItemId, {
    bool usePublicEndpoint = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      print('MenuProvider: Loading add-ons for menu item #$menuItemId');

      _menuItemAddOns = await ApiService.getMenuItemAddOns(
        menuItemId,
        usePublicEndpoint: usePublicEndpoint,
      );
      print(
        'MenuProvider: Loaded ${_menuItemAddOns.length} add-ons for menu item #$menuItemId',
      );

      notifyListeners();
    } catch (e) {
      print('MenuProvider: Error loading add-ons for menu item: $e');
      _setError('Failed to load add-ons for menu item: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load menu items associated with a specific add-on
  Future<List<menu_models.MenuItem>> loadAddOnMenuItems(
    int addOnId, {
    bool usePublicEndpoint = true,
  }) async {
    try {
      print('MenuProvider: Loading menu items for add-on #$addOnId');

      final menuItems = await ApiService.getAddOnMenuItems(
        addOnId,
        usePublicEndpoint: usePublicEndpoint,
      );
      print(
        'MenuProvider: Loaded ${menuItems.length} menu items for add-on #$addOnId',
      );

      return menuItems;
    } catch (e) {
      print('MenuProvider: Error loading menu items for add-on: $e');
      return [];
    }
  }

  // Get menu items that are NOT associated with a specific add-on
  Future<List<menu_models.MenuItem>> getAvailableMenuItemsForAddOn(
    int addOnId, {
    bool usePublicEndpoint = true,
  }) async {
    try {
      final allMenuItems = _menuItems;
      final addOnMenuItems = await loadAddOnMenuItems(
        addOnId,
        usePublicEndpoint: usePublicEndpoint,
      );
      final addOnMenuItemIds = addOnMenuItems.map((item) => item.id).toSet();

      // Filter out menu items that are already in the add-on
      final availableItems = allMenuItems
          .where((item) => !addOnMenuItemIds.contains(item.id))
          .toList();

      print(
        'MenuProvider: Found ${availableItems.length} available menu items for add-on #$addOnId',
      );
      return availableItems;
    } catch (e) {
      print('MenuProvider: Error getting available menu items for add-on: $e');
      return _menuItems; // Fallback to all menu items
    }
  }

  // Add menu items to an existing add-on
  Future<bool> addMenuItemsToAddOn(int addOnId, List<int> menuItemIds) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.addMenuItemsToAddOn(addOnId, menuItemIds);

      // Reload add-ons to reflect changes
      await loadAddOns();

      return true;
    } catch (e) {
      _setError('Failed to add menu items to add-on: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove menu items from an add-on
  Future<bool> removeMenuItemsFromAddOn(
    int addOnId,
    List<int> menuItemIds,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.removeMenuItemsFromAddOn(addOnId, menuItemIds);

      // Reload add-ons to reflect changes
      await loadAddOns();

      return true;
    } catch (e) {
      _setError('Failed to remove menu items from add-on: $e');
      return false;
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
      if (menuItem.category != null &&
          !categoriesMap.containsKey(menuItem.category!.id)) {
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

  Future<bool> createAddOn({
    required String name,
    required double price,
    required double cogs,
    required List<int> menuItemIds,
    String? description,
    bool isAvailable = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final addOnData = {
        'name': name,
        'price': price,
        'cogs': cogs,
        'is_available': isAvailable,
        'menu_item_ids': menuItemIds,
        if (description != null) 'description': description,
      };

      final newAddOn = await ApiService.createAddOn(addOnData);
      _addOns.add(newAddOn);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create add-on: $e');
      return false;
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

      final categoryData = {'name': name, 'description': description};

      await ApiService.updateCategory(id, categoryData);
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(
          name: name,
          description: description,
        );
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

  Future<void> updateMenuItem(
    int id,
    String name,
    int categoryId,
    String description,
    double price,
    double cogs,
    bool isAvailable,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      final itemData = {
        'name': name,
        'category_id': categoryId,
        'description': description,
        'price': price,
        'cogs': cogs,
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
          cogs: cogs,
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
  Future<void> updateAddOn(
    int id,
    String name,
    String description,
    double price,
    double cogs,
    bool isAvailable,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      final addOnData = {
        'name': name,
        'description': description,
        'price': price,
        'cogs': cogs,
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
