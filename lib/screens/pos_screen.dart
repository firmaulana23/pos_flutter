import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/menu.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = context.read<MenuProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      
      menuProvider.loadAllMenuData(usePublicEndpoint: true);
      transactionProvider.loadPaymentMethods(usePublicEndpoint: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithActions(
        title: 'Point of Sale',
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => _showCartBottomSheet(context),
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<MenuProvider>(
        builder: (context, menuProvider, child) {
          if (menuProvider.isLoading) {
            return const LoadingWidget(message: 'Memuat menu...');
          }

          if (menuProvider.error != null) {
            return AppErrorWidget(
              message: menuProvider.error!,
              onRetry: _loadData,
            );
          }

          final categories = menuProvider.categoriesWithFallback;
          if (categories.isEmpty) {
            return const EmptyStateWidget(
              title: 'Tidak ada kategori',
              subtitle: 'Belum ada kategori menu yang tersedia',
              icon: Icons.category_outlined,
            );
          }

          return Column(
            children: [
              _buildCategoryTabs(categories),
              Expanded(
                child: _buildMenuGrid(menuProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => _showCartBottomSheet(context),
            icon: const Icon(Icons.shopping_cart),
            label: Text(AppFormatters.formatCurrency(cartProvider.total)),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(List<Category> categories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == _selectedCategoryIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid(MenuProvider menuProvider) {
    final categories = menuProvider.categoriesWithFallback;
    if (categories.isEmpty) return const SizedBox.shrink();

    final selectedCategory = categories[_selectedCategoryIndex];
    final menuItems = menuProvider.getMenuItemsByCategory(selectedCategory.id)
        .where((item) => item.isAvailable)
        .toList();

    if (menuItems.isEmpty) {
      return EmptyStateWidget(
        title: 'Tidak ada menu',
        subtitle: 'Belum ada menu di kategori ${selectedCategory.name}',
        icon: Icons.restaurant_menu_outlined,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return _buildMenuItemCard(menuItems[index]);
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem menuItem) {
    return CustomCard(
      onTap: () => _addToCart(menuItem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu Item Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: menuItem.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      menuItem.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
          
          const SizedBox(height: 12),
          
          // Menu Item Name
          Text(
            menuItem.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (menuItem.description != null) ...[
            const SizedBox(height: 4),
            Text(
              menuItem.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PriceTag(price: AppFormatters.formatCurrency(menuItem.price)),
              const Icon(
                Icons.add_circle,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 40,
          color: AppColors.disabled,
        ),
      ),
    );
  }

  void _addToCart(MenuItem menuItem) {
    final menuProvider = context.read<MenuProvider>();
    final availableAddOns = menuProvider.getAvailableAddOns();

    if (availableAddOns.isNotEmpty) {
      _showAddOnSelectionDialog(menuItem, availableAddOns);
    } else {
      context.read<CartProvider>().addItem(menuItem);
      _showSnackBar('${menuItem.name} ditambahkan ke keranjang');
    }
  }

  void _showAddOnSelectionDialog(MenuItem menuItem, List<AddOn> addOns) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddOnSelectionDialog(
          menuItem: menuItem,
          addOns: addOns,
          onConfirm: (selectedAddOns) {
            context.read<CartProvider>().addItem(menuItem, addOns: selectedAddOns);
            _showSnackBar('${menuItem.name} ditambahkan ke keranjang');
          },
        );
      },
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartBottomSheet(),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class AddOnSelectionDialog extends StatefulWidget {
  final MenuItem menuItem;
  final List<AddOn> addOns;
  final Function(List<CartAddOn>) onConfirm;

  const AddOnSelectionDialog({
    super.key,
    required this.menuItem,
    required this.addOns,
    required this.onConfirm,
  });

  @override
  State<AddOnSelectionDialog> createState() => _AddOnSelectionDialogState();
}

class _AddOnSelectionDialogState extends State<AddOnSelectionDialog> {
  final Map<int, int> _selectedAddOns = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Add-On untuk ${widget.menuItem.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.addOns.map((addOn) {
            final quantity = _selectedAddOns[addOn.id] ?? 0;
            
            return ListTile(
              title: Text(addOn.name),
              subtitle: Text(AppFormatters.formatCurrency(addOn.price)),
              trailing: QuantitySelector(
                quantity: quantity,
                onIncrement: () {
                  setState(() {
                    _selectedAddOns[addOn.id] = quantity + 1;
                  });
                },
                onDecrement: () {
                  if (quantity > 0) {
                    setState(() {
                      if (quantity == 1) {
                        _selectedAddOns.remove(addOn.id);
                      } else {
                        _selectedAddOns[addOn.id] = quantity - 1;
                      }
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final selectedAddOns = _selectedAddOns.entries
                .map((entry) {
                  final addOn = widget.addOns.firstWhere((a) => a.id == entry.key);
                  return CartAddOn(addOn: addOn, quantity: entry.value);
                })
                .toList();
            
            widget.onConfirm(selectedAddOns);
            Navigator.of(context).pop();
          },
          child: const Text('Tambah ke Keranjang'),
        ),
      ],
    );
  }
}

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

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
                  'Keranjang Belanja',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.isEmpty) return const SizedBox.shrink();
                    
                    return TextButton(
                      onPressed: () {
                        cartProvider.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Kosongkan'),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Cart Items
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                if (cartProvider.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'Keranjang Kosong',
                    subtitle: 'Tambahkan menu untuk memulai pesanan',
                    icon: Icons.shopping_cart_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    return _buildCartItem(context, cartProvider, index);
                  },
                );
              },
            ),
          ),
          
          // Summary and Action Buttons
          _buildCartSummary(context),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartProvider cartProvider, int index) {
    final item = cartProvider.items[index];
    
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
                      item.menuItem.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(item.menuItem.price),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              QuantitySelector(
                quantity: item.quantity,
                onIncrement: () => cartProvider.updateItemQuantity(index, item.quantity + 1),
                onDecrement: () => cartProvider.updateItemQuantity(index, item.quantity - 1),
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
                    '+ ${addOn.addOn.name} (${addOn.quantity}x)',
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
          
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(item.total),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.isEmpty) return const SizedBox.shrink();

        return Container(
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
                    'Total (${cartProvider.totalQuantity} item)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(cartProvider.total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _saveTransaction(context, cartProvider),
                      child: const Text('Simpan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _processPayment(context, cartProvider),
                      child: const Text('Bayar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveTransaction(BuildContext context, CartProvider cartProvider) async {
    final transaction = await cartProvider.saveTransaction();
    
    if (transaction != null && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi ${AppFormatters.formatTransactionId(transaction.id!)} disimpan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _processPayment(BuildContext context, CartProvider cartProvider) async {
    final transactionProvider = context.read<TransactionProvider>();
    
    // Try to load payment methods if they're empty
    if (transactionProvider.paymentMethods.isEmpty) {
      await transactionProvider.loadPaymentMethods(usePublicEndpoint: true);
    }
    
    final paymentMethods = transactionProvider.paymentMethods;

    if (paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Metode pembayaran tidak tersedia'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedPaymentMethod = await showDialog<PaymentMethod>(
      context: context,
      builder: (context) => PaymentMethodDialog(paymentMethods: paymentMethods),
    );

    if (selectedPaymentMethod != null) {
      final transaction = await cartProvider.processPayment(selectedPaymentMethod.code);
      
      if (transaction != null && context.mounted) {
        Navigator.pop(context);
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
