import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

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
        title: 'Tidak ada transaksi',
        subtitle: 'Belum ada transaksi yang tersedia',
        icon: Icons.receipt_long_outlined,
      );
    }

    return ListView.builder(
      padding: AppStyles.defaultPadding,
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(transactions[index]);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppFormatters.formatTransactionId(transaction.id!),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              StatusChip(
                text: transaction.status.toUpperCase(),
                color: transaction.isPaid ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            AppFormatters.formatDateTime(transaction.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurface.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Pelanggan: ${transaction.customerName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${transaction.totalQuantity} item • ${AppFormatters.formatCurrency(transaction.total)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          if (transaction.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showTransactionDetails(transaction),
                    child: const Text('Detail'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _processPayment(transaction),
                    child: const Text('Bayar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(context, transaction),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showTransactionDetails(transaction),
                    child: const Text('Lihat Detail'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(context, transaction),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Hapus (Admin)',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailBottomSheet(
        transaction: transaction,
        onDelete: () {
          // Close the bottom sheet first
          Navigator.of(context).pop();
          // Then show delete confirmation
          _showDeleteConfirmation(context, transaction);
        },
      ),
    );
  }

  void _processPayment(Transaction transaction) async {
    final transactionProvider = context.read<TransactionProvider>();
    final paymentMethods = transactionProvider.paymentMethods;

    if (paymentMethods.isEmpty) {
      await transactionProvider.loadPaymentMethods(usePublicEndpoint: true);
    }

    if (context.mounted) {
      final selectedPaymentMethod = await showDialog<PaymentMethod>(
        context: context,
        builder: (context) => PaymentMethodDialog(
          paymentMethods: transactionProvider.paymentMethods,
        ),
      );

      if (selectedPaymentMethod != null) {
        final success = await transactionProvider.payTransaction(
          transaction.id!,
          selectedPaymentMethod.code,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pembayaran ${AppFormatters.formatTransactionId(transaction.id!)} berhasil'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
            const SizedBox(height: 8),
            Text(
              'ID: ${AppFormatters.formatTransactionId(transaction.id!)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Pelanggan: ${transaction.customerName}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Total: ${AppFormatters.formatCurrency(transaction.total)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (transaction.isPaid)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: const Text(
                  'Perhatian: Transaksi yang sudah dibayar hanya dapat dihapus oleh admin.',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTransaction(context, transaction);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(BuildContext context, Transaction transaction) async {
    final transactionProvider = context.read<TransactionProvider>();
    
    // Prevent multiple delete operations
    if (transactionProvider.isLoading) {
      return;
    }
    
    try {
      // Add timeout to prevent infinite loading
      final success = await transactionProvider.deleteTransaction(transaction.id!).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Delete transaction timeout');
          return false;
        },
      );
      
      if (success && context.mounted) {
        // Force a rebuild of the widget tree
        if (mounted) {
          setState(() {
            // This empty setState will force a rebuild
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi ${AppFormatters.formatTransactionId(transaction.id!)} berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus transaksi: ${transactionProvider.error ?? 'Error tidak diketahui'}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class TransactionDetailBottomSheet extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;

  const TransactionDetailBottomSheet({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Transaksi',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                StatusChip(
                  text: transaction.status.toUpperCase(),
                  color: transaction.isPaid ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Transaction Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ID Transaksi', AppFormatters.formatTransactionId(transaction.id!)),
                _buildInfoRow('Pelanggan', transaction.customerName),
                _buildInfoRow('Tanggal', AppFormatters.formatDateTime(transaction.createdAt)),
                if (transaction.paymentMethod != null)
                  _buildInfoRow('Metode Pembayaran', transaction.paymentMethod!),
              ],
            ),
          ),
          
          const Divider(),
          
          // Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: transaction.items.length,
              itemBuilder: (context, index) {
                return _buildTransactionItem(context, transaction.items[index]);
              },
            ),
          ),
          
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total (${transaction.totalQuantity} item)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(transaction.total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Delete button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus Transaksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.disabled,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionItem item) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.menuItem?.name ?? 'Menu Item',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${AppFormatters.formatCurrency(item.price)} x ${item.quantity}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.formatCurrency(item.subtotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          if (item.addOns.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...item.addOns.map((addOn) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '+ ${addOn.addOn?.name ?? 'Add-on'} (${addOn.quantity}x)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    AppFormatters.formatCurrency(addOn.totalPrice),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class PaymentMethodDialog extends StatelessWidget {
  final List<PaymentMethod> paymentMethods;

  const PaymentMethodDialog({
    super.key,
    required this.paymentMethods,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Metode Pembayaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: paymentMethods.map((method) {
          return ListTile(
            title: Text(method.name),
            subtitle: method.description != null ? Text(method.description!) : null,
            onTap: () => Navigator.of(context).pop(method),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
