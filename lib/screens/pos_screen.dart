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
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
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
              if (_showSearchBar) _buildSearchBar(),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari menu...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          // Focus will be lost automatically, triggering search
        },
      ),
    );
  }

  Widget _buildCategoryTabs(List<Category> categories) {
    // Add "All Categories" as the first option
    final allCategoriesOption = Category(
      id: -1,
      name: 'Semua',
      description: 'Semua kategori menu',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final categoriesWithAll = [allCategoriesOption, ...categories];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoriesWithAll.length,
        itemBuilder: (context, index) {
          final category = categoriesWithAll[index];
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

    List<MenuItem> menuItems;
    
    // If searching, show all matching items regardless of category
    if (_searchQuery.isNotEmpty) {
      menuItems = menuProvider.menuItems
          .where((item) => 
              item.isAvailable && 
              (item.name.toLowerCase().contains(_searchQuery) ||
               (item.description?.toLowerCase().contains(_searchQuery) ?? false)))
          .toList();
    } else {
      // If "All Categories" is selected (index 0), show all menu items
      if (_selectedCategoryIndex == 0) {
        menuItems = menuProvider.menuItems
            .where((item) => item.isAvailable)
            .toList();
      } else {
        // Show items from selected category (adjust index by -1 due to "All Categories")
        final selectedCategory = categories[_selectedCategoryIndex - 1];
        menuItems = menuProvider.getMenuItemsByCategory(selectedCategory.id)
            .where((item) => item.isAvailable)
            .toList();
      }
    }

    if (menuItems.isEmpty) {
      String emptyMessage;
      if (_searchQuery.isNotEmpty) {
        emptyMessage = 'Tidak ada menu yang cocok dengan pencarian "$_searchQuery"';
      } else if (_selectedCategoryIndex == 0) {
        emptyMessage = 'Belum ada menu yang tersedia';
      } else {
        final selectedCategory = categories[_selectedCategoryIndex - 1];
        emptyMessage = 'Belum ada menu di kategori ${selectedCategory.name}';
      }
      
      return EmptyStateWidget(
        title: 'Tidak ada menu',
        subtitle: emptyMessage,
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
    final menuProvider = context.read<MenuProvider>();
    final category = menuProvider.getCategoryById(menuItem.categoryId);
    final showCategory = _selectedCategoryIndex == 0 || _searchQuery.isNotEmpty;
    
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
          
          // Category badge (show when displaying all categories or searching)
          if (showCategory && category != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
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
                color: AppColors.onSurface.withValues(alpha: 0.7),
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

  void _addToCart(MenuItem menuItem) async {
    final menuProvider = context.read<MenuProvider>();
    
    try {
      // Get add-ons specific to this menu item plus global add-ons
      final availableAddOns = await menuProvider.getAvailableAddOnsForMenuItem(menuItem.id);

      if (availableAddOns.isNotEmpty) {
        _showAddOnSelectionDialog(menuItem, availableAddOns);
      } else {
        context.read<CartProvider>().addItem(menuItem);
        _showSnackBar('${menuItem.name} ditambahkan ke keranjang');
      }
    } catch (e) {
      debugPrint('Error loading add-ons for menu item ${menuItem.id}: $e');
      // Fallback: add item without add-ons
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppFormatters.formatCurrency(addOn.price)),
                  if (addOn.description != null && addOn.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      addOn.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: addOn.menuItemId == null 
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      addOn.menuItemId == null ? 'Global' : 'Menu Spesifik',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: addOn.menuItemId == null 
                            ? Colors.blue[700]
                            : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
                    '+ ${addOn.addOn.name} (${addOn.quantity * item.quantity}x)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    AppFormatters.formatCurrency(addOn.totalPrice * item.quantity),
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
              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal (${cartProvider.totalQuantity} item)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    AppFormatters.formatCurrency(cartProvider.subtotal + cartProvider.addOnsTotal),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Tax input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pajak'),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      initialValue: cartProvider.tax.toStringAsFixed(0),
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        prefixText: 'Rp ',
                      ),
                      onChanged: (value) {
                        final tax = double.tryParse(value) ?? 0.0;
                        cartProvider.setTax(tax);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Discount input  
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Diskon'),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      initialValue: cartProvider.discount.toStringAsFixed(0),
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        prefixText: 'Rp ',
                      ),
                      onChanged: (value) {
                        final discount = double.tryParse(value) ?? 0.0;
                        cartProvider.setDiscount(discount);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
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
    // First get customer name
    final customerName = await showDialog<String>(
      context: context,
      builder: (context) => const CustomerNameDialog(),
    );

    if (customerName == null || customerName.trim().isEmpty) {
      return; // User cancelled or didn't enter a name
    }

    final transaction = await cartProvider.saveTransaction(customerName: customerName.trim());
    
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
    
    // First get customer name
    final customerName = await showDialog<String>(
      context: context,
      builder: (context) => const CustomerNameDialog(),
    );

    if (customerName == null || customerName.trim().isEmpty) {
      return; // User cancelled or didn't enter a name
    }
    
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
      double uangDiterima = 0.0;
      double kembalian = 0.0;

      if (selectedPaymentMethod.code.toLowerCase() == 'cash') {
        // Show dialog for uang diterima
        uangDiterima = await showDialog<double>(
          context: context,
          builder: (context) {
            final TextEditingController controller = TextEditingController();
            double change = 0.0;
            return StatefulBuilder(
              builder: (context, setState) {
                double total = cartProvider.total;
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
        kembalian = (uangDiterima - cartProvider.total).clamp(0.0, double.infinity);
        if (uangDiterima < cartProvider.total) return;
      } else {
        uangDiterima = cartProvider.total;
        kembalian = 0.0;
      }

      // First create the transaction through cart provider
      final transaction = await cartProvider.saveTransaction(customerName: customerName.trim());
      
      if (transaction != null) {
        // Then process payment through transaction provider (which includes automatic receipt printing)
        final success = await transactionProvider.payTransaction(
          transaction.id!,
          selectedPaymentMethod.code,
          uangDiterima: uangDiterima,
          kembalian: kembalian,
        );
        
        if (success && context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pembayaran ${AppFormatters.formatTransactionId(transaction.id!)} berhasil'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memproses pembayaran: ${transactionProvider.error ?? 'Error tidak diketahui'}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat transaksi'),
            backgroundColor: AppColors.error,
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

class CustomerNameDialog extends StatefulWidget {
  const CustomerNameDialog({super.key});

  @override
  State<CustomerNameDialog> createState() => _CustomerNameDialogState();
}

class _CustomerNameDialogState extends State<CustomerNameDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nama Pelanggan'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan nama pelanggan untuk transaksi ini:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                hintText: 'Contoh: John Doe',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama pelanggan harus diisi';
                }
                if (value.trim().length < 2) {
                  return 'Nama pelanggan minimal 2 karakter';
                }
                return null;
              },
              onFieldSubmitted: (value) {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop(value.trim());
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Lanjutkan'),
        ),
      ],
    );
  }
}
