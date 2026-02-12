import 'package:flutter/foundation.dart';
import '../models/member.dart';
import '../models/promo.dart';
import '../models/transaction.dart';
import '../models/menu.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  double _tax = 0.0;

  // Manual Discount
  double _manualDiscountPercentage = 0.0;
  double _manualDiscount = 0.0;

  // Member and Promo
  Member? _member;
  Promo? _promo;
  double _memberDiscount = 0.0; // Added for member discount
  double _promoDiscount = 0.0;
  String? _validationError;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get addOnsTotal =>
      _items.fold(0, (sum, item) => sum + item.addOnsTotal);
  double get discount => _manualDiscount;
  double get manualDiscountPercentage => _manualDiscountPercentage;
  double get tax => _tax;

  Member? get member => _member;
  Promo? get promo => _promo;
  double get memberDiscount => _memberDiscount;
  double get promoDiscount => _promoDiscount;
  String? get validationError => _validationError;

  double get total =>
      (subtotal +
              addOnsTotal +
              tax -
              _manualDiscount -
              _memberDiscount -
              _promoDiscount)
          .clamp(0.0, double.infinity);

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setValidationError(String? error) {
    _validationError = error;
    notifyListeners();
  }

  void addItem(MenuItem menuItem, {List<CartAddOn>? addOns}) {
    // Check if item already exists (with same add-ons)
    final existingIndex = _items.indexWhere(
      (item) =>
          item.menuItem.id == menuItem.id &&
          _areAddOnsSame(item.addOns, addOns ?? []),
    );

    if (existingIndex >= 0) {
      // Update quantity
      _items[existingIndex].quantity++;
    } else {
      // Add new item
      _items.add(CartItem(menuItem: menuItem, addOns: addOns ?? []));
    }
    _recalculateDiscounts();
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _recalculateDiscounts();
      notifyListeners();
    }
  }

  void updateItemQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length) {
      if (quantity <= 0) {
        removeItem(index);
      } else {
        _items[index].quantity = quantity;
        _recalculateDiscounts();
        notifyListeners();
      }
    }
  }

  void addAddOnToItem(int itemIndex, AddOn addOn) {
    if (itemIndex >= 0 && itemIndex < _items.length) {
      final existingAddOnIndex = _items[itemIndex].addOns.indexWhere(
        (cartAddOn) => cartAddOn.addOn.id == addOn.id,
      );

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
      _recalculateDiscounts();
      notifyListeners();
    }
  }

  void removeAddOnFromItem(int itemIndex, int addOnIndex) {
    if (itemIndex >= 0 &&
        itemIndex < _items.length &&
        addOnIndex >= 0 &&
        addOnIndex < _items[itemIndex].addOns.length) {
      _items[itemIndex].addOns.removeAt(addOnIndex);
      _recalculateDiscounts();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _manualDiscount = 0.0;
    _manualDiscountPercentage = 0.0;
    _tax = 0.0;
    _member = null;
    _promo = null;
    _memberDiscount = 0.0;
    _promoDiscount = 0.0;
    _validationError = null;
    notifyListeners();
  }

  void setDiscount(double percentage) {
    _manualDiscountPercentage = percentage.clamp(0.0, 100.0);
    _recalculateDiscounts();
    notifyListeners();
  }

  void setTax(double tax) {
    _tax = tax.clamp(0.0, double.infinity);
    notifyListeners();
  }

  void _recalculateDiscounts() {
    final currentSubtotal = subtotal + addOnsTotal;

    // Recalculate Manual Discount
    _manualDiscount = currentSubtotal * (_manualDiscountPercentage / 100);

    // Recalculate Member Discount
    if (_member != null) {
      _memberDiscount = currentSubtotal * (_member!.discount / 100);
    } else {
      _memberDiscount = 0.0;
    }

    // Recalculate Promo Discount
    if (_promo != null) {
      // If a member is applied and the promo is not stackable, don't apply promo discount
      if (_member != null && !_promo!.stackable) {
        _promoDiscount = 0.0;
      } else {
        if (_promo!.type.toLowerCase() == 'percentage') {
          // Apply percentage discount on the subtotal
          _promoDiscount = currentSubtotal * (_promo!.value / 100);
        } else {
          // 'fixed'
          _promoDiscount = _promo!.value;
        }
      }
    } else {
      _promoDiscount = 0.0;
    }
  }

  Future<bool> applyMember(String code) async {
    _setLoading(true);
    _setValidationError(null);
    try {
      final member = await ApiService.validateMember(code);
      _member = member;
      _recalculateDiscounts();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setValidationError(e.message);
      removeMember();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void removeMember() {
    _member = null;
    _memberDiscount = 0.0;
    _recalculateDiscounts();
    _setValidationError(null);
    notifyListeners();
  }

  Future<bool> applyPromo(String code) async {
    _setLoading(true);
    _setValidationError(null);
    try {
      final promo = await ApiService.validatePromo(code);

      // Basic validation
      if (!promo.isActive) {
        throw ApiException('Promo code is not active.');
      }
      if (promo.startAt != null && DateTime.now().isBefore(promo.startAt!)) {
        throw ApiException('Promo has not started yet.');
      }
      if (promo.endAt != null && DateTime.now().isAfter(promo.endAt!)) {
        throw ApiException('Promo has expired.');
      }

      // Check for stackability if member is already applied
      if (_member != null && !promo.stackable) {
        _setValidationError('Promo cannot be combined with a member discount.');
        // We still set the promo but the discount will be 0
      }

      _promo = promo;
      _recalculateDiscounts();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setValidationError(e.message);
      removePromo();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void removePromo() {
    _promo = null;
    _promoDiscount = 0.0;
    _recalculateDiscounts();
    _setValidationError(null);
    notifyListeners();
  }

  bool _areAddOnsSame(List<CartAddOn> addOns1, List<CartAddOn> addOns2) {
    if (addOns1.length != addOns2.length) return false;

    for (final addOn1 in addOns1) {
      final match = addOns2.any(
        (addOn2) =>
            addOn1.addOn.id == addOn2.addOn.id &&
            addOn1.quantity == addOn2.quantity,
      );
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
        'customer_name': customerName,
        'member_id': _member?.id,
        'promo_id': _promo?.id,
        'tax': tax,
        'discount_percentage':
            _manualDiscountPercentage, // Send percentage
        'items': _items
            .map(
              (item) => {
                'menu_item_id': item.menuItem.id,
                'quantity': item.quantity,
                'add_ons': item.addOns
                    .map(
                      (addOn) => {
                        'add_on_id': addOn.addOn.id,
                        'quantity': addOn.quantity,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
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

  Future<Transaction?> processPayment(
    String paymentMethodCode, {
    required String customerName,
  }) async {
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
