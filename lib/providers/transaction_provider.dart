import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import '../services/thermal_printer_service.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Transaction> get pendingTransactions => 
      _transactions.where((t) => t.isPending).toList();
  
  List<Transaction> get paidTransactions => 
      _transactions.where((t) => t.isPaid).toList();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    try {
      _setLoading(true);
      _setError(null);
      
      print('TransactionProvider: Starting to load transactions...');
      
      // Check if we have an auth token
      final token = await ApiService.getAuthToken();
      print('TransactionProvider: Auth token exists: ${token != null}');
      
      _transactions = await ApiService.getTransactions();
      print('TransactionProvider: Loaded ${_transactions.length} transactions');
      notifyListeners();
    } catch (e) {
      print('TransactionProvider: Error loading transactions: $e');
      print('TransactionProvider: Error type: ${e.runtimeType}');
      if (e is ApiException) {
        print('TransactionProvider: API Exception - Status Code: ${e.statusCode}');
      }
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPaymentMethods({bool usePublicEndpoint = false}) async {
    try {
      _setLoading(true);
      _setError(null);

      print('TransactionProvider: Loading payment methods (usePublicEndpoint: $usePublicEndpoint)...');
      _paymentMethods = await ApiService.getPaymentMethods(
        usePublicEndpoint: usePublicEndpoint
      );
      print('TransactionProvider: Loaded ${_paymentMethods.length} payment methods');
      for (var method in _paymentMethods) {
        print('TransactionProvider: - ${method.name} (ID: ${method.id})');
      }
      notifyListeners();
    } catch (e) {
      print('TransactionProvider: Error loading payment methods: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Transaction?> getTransaction(int id) async {
    try {
      _setLoading(true);
      _setError(null);

      return await ApiService.getTransaction(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> payTransaction(int transactionId, String paymentMethodCode, {double? uangDiterima, double? kembalian}) async {
    try {
      _setLoading(true);
      _setError(null);

      final updatedTransaction = await ApiService.payTransaction(
        transactionId, 
        paymentMethodCode,
      );

      // Attach uang diterima and kembalian for receipt
      final txWithExtra = Transaction(
        id: updatedTransaction.id,
        transactionNo: updatedTransaction.transactionNo,
        status: updatedTransaction.status,
        subTotal: updatedTransaction.subTotal,
        tax: updatedTransaction.tax,
        discount: updatedTransaction.discount,
        total: updatedTransaction.total,
        paymentMethod: updatedTransaction.paymentMethod,
        userId: updatedTransaction.userId,
        customerName: updatedTransaction.customerName,
        createdAt: updatedTransaction.createdAt,
        updatedAt: updatedTransaction.updatedAt,
        paidAt: updatedTransaction.paidAt,
        items: updatedTransaction.items,
        user: updatedTransaction.user,
        extra: {
          if (uangDiterima != null) 'uangDiterima': uangDiterima,
          if (kembalian != null) 'kembalian': kembalian,
        },
      );

      // Update local transaction data
      final index = _transactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index >= 0) {
        _transactions[index] = txWithExtra;
      } else {
        _transactions.add(txWithExtra);
      }
      // Print receipt after successful payment
      if (ThermalPrinterService.isConnected) {
        print('TransactionProvider: Attempting to print receipt for transaction ${updatedTransaction.id}');
        try {
          final printSuccess = await ThermalPrinterService.printReceipt(txWithExtra);
          if (printSuccess) {
            print('TransactionProvider: Receipt printed successfully');
          }
        } catch (e) {
          print('TransactionProvider: Error printing receipt: $e');
        }
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Add a new menu item to a pending transaction
  Future<bool> addItemToTransaction(int transactionId, MenuItem menuItem, int quantity, List<CartAddOn>? addOns) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Format data for API
      final itemData = {
        'menu_item_id': menuItem.id,
        'quantity': quantity,
        'add_ons': (addOns ?? []).map((addOn) => {
          'add_on_id': addOn.addOn.id,
          'quantity': addOn.quantity,
        }).toList(),
      };
      
      // Add the item to the transaction
      await ApiService.addItemToTransaction(transactionId, itemData);
      
      // Update local transaction data after item is added
      await loadTransactions();
      
      return true;
    } catch (e) {
      _setError('Failed to add item to transaction: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update an existing transaction item
  Future<bool> updateTransactionItem(int transactionId, int itemId, int quantity, List<CartAddOn>? addOns) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Format data for API
      final updateData = {
        'quantity': quantity,
        'add_ons': (addOns ?? []).map((addOn) => {
          'add_on_id': addOn.addOn.id,
          'quantity': addOn.quantity,
        }).toList(),
      };
      
      await ApiService.updateTransactionItem(transactionId, itemId, updateData);
      
      // Update local transaction data after item is updated
      await loadTransactions();
      
      return true;
    } catch (e) {
      _setError('Failed to update transaction item: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a transaction item
  Future<bool> deleteTransactionItem(int transactionId, int itemId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await ApiService.deleteTransactionItem(transactionId, itemId);
      
      // Update local transaction data after item is deleted
      await loadTransactions();
      
      return true;
    } catch (e) {
      _setError('Failed to delete transaction item: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update basic transaction information
  Future<bool> updateTransaction(int id, {String? customerName, double? tax, double? discount}) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final updateData = <String, dynamic>{};
      if (customerName != null) updateData['customer_name'] = customerName;
      if (tax != null) updateData['tax'] = tax;
      if (discount != null) updateData['discount'] = discount;
      
      await ApiService.updateTransaction(id, updateData);
      
      // Update local transaction data
      await loadTransactions();
      
      return true;
    } catch (e) {
      _setError('Failed to update transaction: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      print('TransactionProvider: Starting delete operation for transaction $id');
      _setLoading(true);
      _setError(null);

      await ApiService.deleteTransaction(id);

      // Remove from the list and notify immediately
      final initialCount = _transactions.length;
      _transactions.removeWhere((t) => t.id == id);
      final finalCount = _transactions.length;
      
      print('TransactionProvider: Deleted transaction $id. Count changed from $initialCount to $finalCount');
      
      // Force notify listeners before setting loading to false
      notifyListeners();

      return true;
    } catch (e) {
      print('TransactionProvider: Error deleting transaction: $e');
      _setError(e.toString());
      return false;
    } finally {
      // Ensure loading is always set to false
      print('TransactionProvider: Setting loading to false after delete operation');
      _setLoading(false);
      print('TransactionProvider: Delete transaction operation completed, loading set to false');
    }
  }

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    notifyListeners();
  }

  PaymentMethod? getPaymentMethodById(int id) {
    try {
      return _paymentMethods.firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _setError(null);
  }
}
