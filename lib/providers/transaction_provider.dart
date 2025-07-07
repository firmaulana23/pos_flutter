import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
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

  Future<bool> payTransaction(int transactionId, String paymentMethodCode) async {
    try {
      _setLoading(true);
      _setError(null);

      final updatedTransaction = await ApiService.payTransaction(
        transactionId, 
        paymentMethodCode
      );

      // Update the transaction in the list
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index] = updatedTransaction;
        notifyListeners();
      }

      // Print receipt if printer is connected
      if (ThermalPrinterService.isConnected) {
        try {
          bool printSuccess = await ThermalPrinterService.printReceipt(updatedTransaction);
          if (printSuccess) {
            print('TransactionProvider: Receipt printed successfully');
          } else {
            print('TransactionProvider: Failed to print receipt');
          }
        } catch (e) {
          print('TransactionProvider: Error printing receipt: $e');
          // Don't fail the transaction if printing fails
        }
      } else {
        print('TransactionProvider: Printer not connected, skipping receipt print');
      }

      return true;
    } catch (e) {
      print('TransactionProvider: Error processing payment: $e');
      print('TransactionProvider: Error type: ${e.runtimeType}');
      if (e is ApiException) {
        print('TransactionProvider: API Exception - Status Code: ${e.statusCode}');
      }
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTransaction(int transactionId) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.deleteTransaction(transactionId);

      // Remove from the list
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
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
