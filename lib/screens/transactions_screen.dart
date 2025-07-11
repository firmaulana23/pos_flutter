import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../models/transaction.dart';
import '../models/menu.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'package:flutter_pos/services/thermal_printer_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTransactions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  // Alternative method to force refresh the transaction list
  void _forceRefreshTransactions() {
    final transactionProvider = context.read<TransactionProvider>();
    // Force a complete reload from the server
    transactionProvider.loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithActions(
        title: 'Transaksi',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.disabled,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Pending'),
              Tab(text: 'Lunas'),
            ],
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                if (transactionProvider.isLoading) {
                  return const LoadingWidget(message: 'Memproses...');
                }

                if (transactionProvider.error != null) {
                  return AppErrorWidget(
                    message: transactionProvider.error!,
                    onRetry: _loadTransactions,
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(transactionProvider.transactions),
                    _buildTransactionList(transactionProvider.pendingTransactions),
                    _buildTransactionList(transactionProvider.paidTransactions),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long,
        message: 'Tidak ada transaksi.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _forceRefreshTransactions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isPending = transaction.status == 'pending';
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isAdminOrManager = authProvider.currentUser != null && 
                                 (authProvider.currentUser!.isAdmin || 
                                  authProvider.currentUser!.isManager);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending ? Colors.orange.shade200 : Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.transactionNo ?? 'New Transaction',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.formatDateTime(transaction.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Paid',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Customer: ${transaction.customerName.isNotEmpty ? transaction.customerName : "N/A"}',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    // Only show edit button for pending transactions
                    if (isPending)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => _showEditCustomerNameDialog(transaction),
                        tooltip: 'Edit Customer Name',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        color: Colors.blue,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transaction.items.length,
                  itemBuilder: (context, index) {
                    final item = transaction.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.menuItem?.name ?? 'Unknown Item'}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (item.addOns.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: item.addOns.map((addon) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 16),
                                        child: Text(
                                          '+ ${addon.quantity}x ${addon.addOn?.name ?? 'Unknown Add-on'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(item.total),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          // Edit item button for pending transactions
                          if (isPending)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _showEditItemDialog(transaction, item),
                              tooltip: 'Edit Item',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(left: 8),
                              color: Colors.blue,
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                // Add new item button for pending transactions
                if (isPending)
                  ElevatedButton.icon(
                    onPressed: () => _showAddItemDialog(transaction),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text(AppFormatters.formatCurrency(transaction.subTotal)),
                  ],
                ),
                if (transaction.tax > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax'),
                      Text(AppFormatters.formatCurrency(transaction.tax)),
                    ],
                  ),
                ],
                if (transaction.discount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount'),
                      Text(
                        '- ${AppFormatters.formatCurrency(transaction.discount)}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppFormatters.formatCurrency(transaction.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Payment method display
                if (transaction.paymentMethod != null && transaction.paymentMethod!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Method'),
                      Text(
                        _getPaymentMethodDisplayName(transaction.paymentMethod!),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Allow deletes only for:
                // 1. Pending transactions (by any user)
                // 2. Paid transactions (only by admin/manager)
                if (isPending || isAdminOrManager) 
                  OutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmation(transaction),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                const SizedBox(width: 12),
                if (isPending)
                  ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(transaction),
                    icon: const Icon(Icons.payment),
                    label: const Text('Process Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                // Print button for paid transactions
                if (transaction.isPaid)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await ThermalPrinterService.printReceipt(transaction);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Struk berhasil dicetak' : 'Gagal mencetak struk'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to add a new item to a pending transaction
  void _showAddItemDialog(Transaction transaction) async {
    // Load menu items
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    await menuProvider.loadMenuItems(usePublicEndpoint: true);
    
    if (!mounted) return;

    MenuItem? selectedMenuItem;
    int quantity = 1;
    final List<CartAddOn> selectedAddOns = [];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Item to Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<MenuItem>(
                      decoration: const InputDecoration(
                        labelText: 'Select Menu Item',
                      ),
                      value: selectedMenuItem,
                      items: menuProvider.menuItems
                          .where((item) => item.isAvailable) // Only available items
                          .map((item) {
                        return DropdownMenuItem<MenuItem>(
                          value: item,
                          child: Text('${item.name} (${AppFormatters.formatCurrency(item.price)})'),
                        );
                      }).toList(),
                      onChanged: (MenuItem? value) async {
                        if (value != null) {
                          setState(() {
                            selectedMenuItem = value;
                            selectedAddOns.clear(); // Reset add-ons when item changes
                          });
                          
                          // Load add-ons for this menu item
                          if (selectedMenuItem != null) {
                            await menuProvider.loadMenuItemAddOns(selectedMenuItem!.id);
                            
                            if (!context.mounted) return;
                            setState(() {}); // Refresh to update available add-ons
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Quantity: '),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() => quantity--);
                            }
                          },
                        ),
                        Text('$quantity'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() => quantity++);
                          },
                        ),
                      ],
                    ),
                    if (selectedMenuItem != null) ...[
                      const SizedBox(height: 16),
                      const Text('Add-ons (Optional):'),
                      const SizedBox(height: 8),
                      ...menuProvider.menuItemAddOns
                          .where((addOn) => addOn.isAvailable)
                          .map((addOn) {
                        final isSelected = selectedAddOns.any((a) => a.addOn.id == addOn.id);
                        final selectedAddOn = isSelected 
                            ? selectedAddOns.firstWhere((a) => a.addOn.id == addOn.id) 
                            : null;
                        
                        return CheckboxListTile(
                          title: Text(addOn.name),
                          subtitle: Text(AppFormatters.formatCurrency(addOn.price)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedAddOns.add(CartAddOn(addOn: addOn));
                              } else {
                                selectedAddOns.removeWhere((a) => a.addOn.id == addOn.id);
                              }
                            });
                          },
                          secondary: isSelected
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          final index = selectedAddOns.indexWhere((a) => a.addOn.id == addOn.id);
                                          if (index != -1 && selectedAddOns[index].quantity > 1) {
                                            selectedAddOns[index] = CartAddOn(
                                              addOn: addOn,
                                              quantity: selectedAddOns[index].quantity - 1,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    Text('${selectedAddOn?.quantity ?? 1}'),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          final index = selectedAddOns.indexWhere((a) => a.addOn.id == addOn.id);
                                          if (index != -1) {
                                            selectedAddOns[index] = CartAddOn(
                                              addOn: addOn,
                                              quantity: selectedAddOns[index].quantity + 1,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedMenuItem == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                          
                          final success = await transactionProvider.addItemToTransaction(
                            transaction.id!,
                            selectedMenuItem!,
                            quantity,
                            selectedAddOns,
                          );
                          
                          if (!mounted) return;
                          
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Item added successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(transactionProvider.error ?? 'Failed to add item'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to edit an existing transaction item
  void _showEditItemDialog(Transaction transaction, TransactionItem item) async {
    // Load menu items and add-ons
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    await menuProvider.loadMenuItemAddOns(item.menuItemId);
    
    if (!mounted) return;

    int quantity = item.quantity;
    final List<CartAddOn> selectedAddOns = [];
    
    // Convert existing add-ons to CartAddOn format
    for (final addon in item.addOns) {
      if (addon.addOn != null) {
        selectedAddOns.add(CartAddOn(
          addOn: addon.addOn!,
          quantity: addon.quantity,
        ));
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Menu Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item: ${item.menuItem?.name ?? 'Unknown Item'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Quantity: '),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() => quantity--);
                            }
                          },
                        ),
                        Text('$quantity'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() => quantity++);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Add-ons:'),
                    const SizedBox(height: 8),
                    ...menuProvider.menuItemAddOns
                        .where((addOn) => addOn.isAvailable)
                        .map((addOn) {
                      final isSelected = selectedAddOns.any((a) => a.addOn.id == addOn.id);
                      final selectedAddOn = isSelected 
                          ? selectedAddOns.firstWhere((a) => a.addOn.id == addOn.id) 
                          : null;
                      
                      return CheckboxListTile(
                        title: Text(addOn.name),
                        subtitle: Text(AppFormatters.formatCurrency(addOn.price)),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedAddOns.add(CartAddOn(addOn: addOn));
                            } else {
                              selectedAddOns.removeWhere((a) => a.addOn.id == addOn.id);
                            }
                          });
                        },
                        secondary: isSelected
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        final index = selectedAddOns.indexWhere((a) => a.addOn.id == addOn.id);
                                        if (index != -1 && selectedAddOns[index].quantity > 1) {
                                          selectedAddOns[index] = CartAddOn(
                                            addOn: addOn,
                                            quantity: selectedAddOns[index].quantity - 1,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  Text('${selectedAddOn?.quantity ?? 1}'),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        final index = selectedAddOns.indexWhere((a) => a.addOn.id == addOn.id);
                                        if (index != -1) {
                                          selectedAddOns[index] = CartAddOn(
                                            addOn: addOn,
                                            quantity: selectedAddOns[index].quantity + 1,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ],
                              )
                            : null,
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                    
                    final success = await transactionProvider.updateTransactionItem(
                      transaction.id!,
                      item.id!,
                      quantity,
                      selectedAddOns,
                    );
                    
                    if (!mounted) return;
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item updated successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(transactionProvider.error ?? 'Failed to update item'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Update Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show confirmation dialog before deleting a transaction
  void _showDeleteConfirmation(Transaction transaction) {
    final isPending = transaction.status == 'pending';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isAdminOrManager = authProvider.currentUser != null && 
                                  (authProvider.currentUser!.isAdmin || 
                                   authProvider.currentUser!.isManager);
    
    // Check permission: only admins/managers can delete paid transactions
    if (!isPending && !isAdminOrManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admin or manager can delete paid transactions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isPending ? 'Pending' : 'Paid'} Transaction'),
        content: Text(
          'Are you sure you want to delete this transaction?\n'
          'Transaction No: ${transaction.transactionNo ?? 'N/A'}\n'
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
              
              try {
                await transactionProvider.deleteTransaction(transaction.id!);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete transaction: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  // Process payment for a pending transaction
  void _showPaymentDialog(Transaction transaction) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    String selectedPaymentMethod = transactionProvider.paymentMethods.isNotEmpty 
        ? transactionProvider.paymentMethods.first.code 
        : '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Process Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction: ${transaction.transactionNo ?? "#${transaction.id}"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${AppFormatters.formatCurrency(transaction.total)}'),
              const SizedBox(height: 16),
              const Text('Select Payment Method:'),
              const SizedBox(height: 8),
              if (transactionProvider.paymentMethods.isEmpty)
                const Text('Loading payment methods...', style: TextStyle(fontStyle: FontStyle.italic))
              else
                StatefulBuilder(
                  builder: (context, setState) {
                    return DropdownButtonFormField<String>(
                      value: selectedPaymentMethod,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: transactionProvider.paymentMethods
                          .where((pm) => pm.isActive)
                          .map((pm) {
                        return DropdownMenuItem<String>(
                          value: pm.code,
                          child: Text(pm.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value ?? '';
                        });
                      },
                    );
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedPaymentMethod.isEmpty 
                  ? null 
                  : () async {
                      Navigator.pop(context);
                      double uangDiterima = 0.0;
                      double kembalian = 0.0;
                      if (selectedPaymentMethod.toLowerCase() == 'cash') {
                        uangDiterima = await showDialog<double>(
                              context: context,
                              builder: (context) {
                                final TextEditingController controller = TextEditingController();
                                double change = 0.0;
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    double total = transaction.total;
                                    double received = double.tryParse(controller.text) ?? 0.0;
                                    change = (received - total).clamp(0.0, double.infinity);
                                    return AlertDialog(
                                      title: const Text('Pembayaran'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Total'),
                                              Text(AppFormatters.formatCurrency(total)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: controller,
                                            keyboardType: TextInputType.number,
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Uang Diterima',
                                              prefixText: 'Rp ',
                                            ),
                                            onChanged: (val) => setState(() {}),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Kembalian'),
                                              Text(AppFormatters.formatCurrency(change)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: (double.tryParse(controller.text) ?? 0.0) >= total
                                              ? () => Navigator.pop(context, double.tryParse(controller.text) ?? 0.0)
                                              : null,
                                          child: const Text('Bayar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ) ?? 0.0;
                        kembalian = (uangDiterima - transaction.total).clamp(0.0, double.infinity);
                        if (uangDiterima < transaction.total) return;
                      } else {
                        uangDiterima = transaction.total;
                        kembalian = 0.0;
                      }
                      final success = await transactionProvider.payTransaction(
                        transaction.id!,
                        selectedPaymentMethod,
                        uangDiterima: uangDiterima,
                        kembalian: kembalian,
                      );
                      
                      if (!context.mounted) return;
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment processed successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(transactionProvider.error ?? 'Failed to process payment'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Process Payment'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to edit customer name for a pending transaction
  void _showEditCustomerNameDialog(Transaction transaction) {
    final TextEditingController _customerNameController = TextEditingController(text: transaction.customerName);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Customer Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction: ${transaction.transactionNo ?? "#${transaction.id}"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter customer name',
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                final newName = _customerNameController.text.trim();
                
                final success = await transactionProvider.updateTransaction(
                  transaction.id!,
                  customerName: newName,
                );
                
                if (!context.mounted) return;
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer name updated successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(transactionProvider.error ?? 'Failed to update customer name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Dialog to edit discount and tax for a transaction
  void _showEditDiscountTaxDialog(Transaction transaction) {
    final TextEditingController _discountController = TextEditingController(text: transaction.discount.toStringAsFixed(0));
    final TextEditingController _taxController = TextEditingController(text: transaction.tax.toStringAsFixed(0));
    showDialog(
      context: context, // Use the local context
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Discount & Tax'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Discount (Rp)',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tax (Rp)',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final discount = double.tryParse(_discountController.text) ?? 0.0;
                final tax = double.tryParse(_taxController.text) ?? 0.0;
                final provider = Provider.of<TransactionProvider>(context, listen: false);
                await provider.updateTransaction(
                  transaction.id!,
                  discount: discount,
                  tax: tax,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _getPaymentMethodDisplayName(String code) {
    // You can customize this method to return the display name based on the payment method code
    switch (code.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'card':
        return 'Kartu Kredit/Debit';
      case 'ovo':
        return 'OVO';
      case 'gopay':
        return 'GoPay';
      case 'shopeepay':
        return 'ShopeePay';
      // Add more cases for other payment methods as needed
      default:
        return code; // Return the code itself if no match is found
    }
  }
}
