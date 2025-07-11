import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/menu.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  double _discount = 0.0;
  double _tax = 0.0;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get addOnsTotal => _items.fold(0, (sum, item) => sum + item.addOnsTotal);
  double get discount => _discount;
  double get tax => _tax;
  double get total => (subtotal + addOnsTotal + tax - discount).clamp(0.0, double.infinity);

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void addItem(MenuItem menuItem, {List<CartAddOn>? addOns}) {
    // Check if item already exists (with same add-ons)
    final existingIndex = _items.indexWhere((item) => 
        item.menuItem.id == menuItem.id && 
        _areAddOnsSame(item.addOns, addOns ?? []));

    if (existingIndex >= 0) {
      // Update quantity
      _items[existingIndex].quantity++;
    } else {
      // Add new item
      _items.add(CartItem(
        menuItem: menuItem,
        addOns: addOns ?? [],
      ));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItemQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length) {
      if (quantity <= 0) {
        removeItem(index);
      } else {
        _items[index].quantity = quantity;
        notifyListeners();
      }
    }
  }

  void addAddOnToItem(int itemIndex, AddOn addOn) {
    if (itemIndex >= 0 && itemIndex < _items.length) {
      final existingAddOnIndex = _items[itemIndex].addOns
          .indexWhere((cartAddOn) => cartAddOn.addOn.id == addOn.id);
      
      if (existingAddOnIndex >= 0) {
        // Increase quantity of existing add-on
        final currentAddOn = _items[itemIndex].addOns[existingAddOnIndex];
        _items[itemIndex].addOns[existingAddOnIndex] = CartAddOn(
          addOn: addOn,
          quantity: currentAddOn.quantity + 1,
        );
      } else {
        // Add new add-on
        _items[itemIndex].addOns.add(CartAddOn(addOn: addOn));
      }
      notifyListeners();
    }
  }

  void removeAddOnFromItem(int itemIndex, int addOnIndex) {
    if (itemIndex >= 0 && itemIndex < _items.length &&
        addOnIndex >= 0 && addOnIndex < _items[itemIndex].addOns.length) {
      _items[itemIndex].addOns.removeAt(addOnIndex);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _discount = 0.0;
    _tax = 0.0;
    notifyListeners();
  }

  void setDiscount(double discount) {
    _discount = discount.clamp(0.0, double.infinity);
    notifyListeners();
  }

  void setTax(double tax) {
    _tax = tax.clamp(0.0, double.infinity);
    notifyListeners();
  }

  bool _areAddOnsSame(List<CartAddOn> addOns1, List<CartAddOn> addOns2) {
    if (addOns1.length != addOns2.length) return false;
    
    for (final addOn1 in addOns1) {
      final match = addOns2.any((addOn2) => 
          addOn1.addOn.id == addOn2.addOn.id && 
          addOn1.quantity == addOn2.quantity);
      if (!match) return false;
    }
    return true;
  }

  Future<Transaction?> saveTransaction({required String customerName}) async {
    if (_items.isEmpty) return null;

    try {
      _setLoading(true);
      _setError(null);

      final transactionData = {
        'status': 'pending',
        'sub_total': subtotal + addOnsTotal,
        'tax': tax,
        'discount': discount,
        'total': total,
        'customer_name': customerName,
        'items': _items.map((item) => {
          'menu_item_id': item.menuItem.id,
          'quantity': item.quantity,
          'price': item.menuItem.price,
          'add_ons': item.addOns.map((addOn) => {
            'add_on_id': addOn.addOn.id,
            'quantity': addOn.quantity, // Multiply add-on quantity by menu item quantity
            'price': addOn.addOn.price,
          }).toList(),
        }).toList(),
      };

      final transaction = await ApiService.createTransaction(transactionData);
      clear(); // Clear cart after successful save
      return transaction;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Transaction?> processPayment(String paymentMethodCode, {required String customerName}) async {
    if (_items.isEmpty) return null;

    try {
      _setLoading(true);
      _setError(null);

      // First create the transaction
      final transaction = await saveTransaction(customerName: customerName);
      if (transaction == null) return null;

      // Then process payment
      final paidTransaction = await ApiService.payTransaction(
        transaction.id!,
        paymentMethodCode,
      );
      
      return paidTransaction;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }
}
