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
              Expanded(child: _buildMenuGrid(menuProvider)),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) return const SizedBox.shrink();

          return AnimatedScale(
            scale: cartProvider.isEmpty ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showCartBottomSheet(context),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_rounded, size: 24),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
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
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(cartProvider.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchQuery.isNotEmpty
                      ? AppColors.primary
                      : AppColors.inputBorder,
                  width: _searchQuery.isNotEmpty ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari menu favorit Anda...',
                  hintStyle: TextStyle(color: AppColors.disabled, fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _searchQuery.isNotEmpty
                        ? AppColors.primary
                        : AppColors.disabled,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                          tooltip: 'Hapus pencarian',
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 14),
                onSubmitted: (value) {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppStyles.defaultShadow],
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showSearchBar = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.onPrimary,
                size: 20,
              ),
              tooltip: 'Tutup pencarian',
            ),
          ),
        ],
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
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: categoriesWithAll.length,
        itemBuilder: (context, index) {
          final category = categoriesWithAll[index];
          final isSelected = index == _selectedCategoryIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.inputBorder,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index == 0) ...[
                        Icon(
                          Icons.grid_view_rounded,
                          size: 16,
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.onSurface,
                        ),
                        const SizedBox(width: 6),
                      ] else if (isSelected) ...[
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 16,
                          color: AppColors.onPrimary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
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
          .where(
            (item) =>
                item.isAvailable &&
                (item.name.toLowerCase().contains(_searchQuery) ||
                    (item.description?.toLowerCase().contains(_searchQuery) ??
                        false)),
          )
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
        menuItems = menuProvider
            .getMenuItemsByCategory(selectedCategory.id)
            .where((item) => item.isAvailable)
            .toList();
      }
    }

    // Sort menu items alphabetically (A-Z)
    menuItems.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    if (menuItems.isEmpty) {
      String emptyMessage;
      if (_searchQuery.isNotEmpty) {
        emptyMessage =
            'Tidak ada menu yang cocok dengan pencarian "$_searchQuery"';
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

    return Hero(
      tag: 'menu-item-${menuItem.id}',
      child: Card(
        elevation: 3,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _addToCart(menuItem),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.background.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu Item Image with enhanced design
                  Stack(
                    children: [
                      Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: menuItem.imageUrl != null
                              ? Image.network(
                                  menuItem.imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return _buildShimmerImage();
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderImage();
                                  },
                                )
                              : _buildPlaceholderImage(),
                        ),
                      ),
                      // Availability indicator
                      if (!menuItem.isAvailable)
                        Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Habis',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      // Category badge
                      if (showCategory && category != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Menu Item Name
                  Text(
                    menuItem.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (menuItem.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      menuItem.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Price and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppFormatters.formatCurrency(menuItem.price),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: menuItem.isAvailable
                              ? () => _addToCart(menuItem)
                              : null,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: AppColors.onPrimary,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Tambah ke keranjang',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceVariant, AppColors.background],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_rounded, size: 48, color: AppColors.disabled),
            const SizedBox(height: 8),
            Text(
              'Gambar menu',
              style: TextStyle(
                color: AppColors.disabled,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  void _addToCart(MenuItem menuItem) async {
    final menuProvider = context.read<MenuProvider>();

    debugPrint(
      'POSScreen: Adding ${menuItem.name} to cart, id: ${menuItem.id}',
    );

    try {
      // Load add-ons specific to this menu item
      debugPrint('POSScreen: Loading add-ons for menu item ${menuItem.id}');
      await menuProvider.loadMenuItemAddOns(
        menuItem.id,
        usePublicEndpoint: true,
      );
      final availableAddOns = menuProvider.menuItemAddOns;

      debugPrint(
        'POSScreen: Found ${availableAddOns.length} add-ons for ${menuItem.name}',
      );

      if (availableAddOns.isNotEmpty) {
        debugPrint('POSScreen: Showing add-on selection dialog');
        _showAddOnSelectionDialog(menuItem, availableAddOns);
      } else {
        debugPrint('POSScreen: No add-ons found, adding item directly to cart');
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
            context.read<CartProvider>().addItem(
              menuItem,
              addOns: selectedAddOns,
            );
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
                  if (addOn.description != null &&
                      addOn.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      addOn.description!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
            final selectedAddOns = _selectedAddOns.entries.map((entry) {
              final addOn = widget.addOns.firstWhere((a) => a.id == entry.key);
              return CartAddOn(addOn: addOn, quantity: entry.value);
            }).toList();

            widget.onConfirm(selectedAddOns);
            Navigator.of(context).pop();
          },
          child: const Text('Tambah ke Keranjang'),
        ),
      ],
    );
  }
}

class CartBottomSheet extends StatefulWidget {
  const CartBottomSheet({super.key});

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  final _discountController = TextEditingController();
  final _memberController = TextEditingController();
  final _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cartProvider = context.read<CartProvider>();
    _discountController.text = cartProvider.manualDiscountPercentage
        .toStringAsFixed(0);
  }

  @override
  void dispose() {
    _discountController.dispose();
    _memberController.dispose();
    _promoController.dispose();
    super.dispose();
  }

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

  Widget _buildCartItem(
    BuildContext context,
    CartProvider cartProvider,
    int index,
  ) {
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
                onIncrement: () =>
                    cartProvider.updateItemQuantity(index, item.quantity + 1),
                onDecrement: () =>
                    cartProvider.updateItemQuantity(index, item.quantity - 1),
              ),
            ],
          ),

          if (item.addOns.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...item.addOns.map(
              (addOn) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+ ${addOn.addOn.name} (${addOn.quantity * item.quantity}x)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      AppFormatters.formatCurrency(
                        addOn.totalPrice * item.quantity,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                    AppFormatters.formatCurrency(
                      cartProvider.subtotal + cartProvider.addOnsTotal,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Member & Promo Section
              _buildMemberPromoSection(context, cartProvider),

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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
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
                  const Text('Diskon Manual'),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _discountController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        suffixText: '%',
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

              // Applied Discounts
              if (cartProvider.memberDiscount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diskon Member (${cartProvider.member?.fullName})'),
                      Text(
                        '- ${AppFormatters.formatCurrency(cartProvider.memberDiscount)}',
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ],
                  ),
                ),

              if (cartProvider.promoDiscount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diskon Promo (${cartProvider.promo?.name})'),
                      Text(
                        '- ${AppFormatters.formatCurrency(cartProvider.promoDiscount)}',
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ],
                  ),
                ),

              if (cartProvider.discount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diskon Manual'),
                      Text(
                        '- ${AppFormatters.formatCurrency(cartProvider.discount)}',
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ],
                  ),
                ),

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

  Widget _buildMemberPromoSection(
    BuildContext context,
    CartProvider cartProvider,
  ) {
    return Column(
      children: [
        if (cartProvider.member == null)
          _buildCodeInput(
            context,
            controller: _memberController,
            hintText: 'Kode Member',
            onApply: () async {
              if (_memberController.text.isNotEmpty) {
                final success = await cartProvider.applyMember(
                  _memberController.text,
                );
                if (success) {
                  _memberController.clear();
                }
              }
            },
            isLoading: cartProvider.isLoading,
          )
        else
          _buildAppliedCodeInfo(
            context,
            title: 'Member: ${cartProvider.member!.fullName}',
            subtitle: 'Points: ${cartProvider.member!.points}',
            onRemove: () => cartProvider.removeMember(),
          ),

        if (cartProvider.promo == null)
          _buildCodeInput(
            context,
            controller: _promoController,
            hintText: 'Kode Promo',
            onApply: () async {
              if (_promoController.text.isNotEmpty) {
                final success = await cartProvider.applyPromo(
                  _promoController.text,
                );
                if (success) {
                  _promoController.clear();
                }
              }
            },
            isLoading: cartProvider.isLoading,
          )
        else
          _buildAppliedCodeInfo(
            context,
            title: cartProvider.promo!.name,
            subtitle:
                'Diskon ${AppFormatters.formatCurrency(cartProvider.promoDiscount)} diterapkan',
            onRemove: () => cartProvider.removePromo(),
          ),

        if (cartProvider.validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              cartProvider.validationError!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCodeInput(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onApply,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: isLoading ? null : onApply,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedCodeInfo(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onRemove,
  }) {
    return ListTile(
      leading: const Icon(Icons.check_circle, color: AppColors.success),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle, color: AppColors.error),
        onPressed: onRemove,
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
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

    final transaction = await cartProvider.saveTransaction(
      customerName: customerName.trim(),
    );

    if (transaction != null && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaksi ${AppFormatters.formatTransactionId(transaction.id!)} disimpan',
          ),
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
        uangDiterima =
            await showDialog<double>(
              context: context,
              builder: (context) {
                final TextEditingController controller =
                    TextEditingController();
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
                          onPressed:
                              (double.tryParse(controller.text) ?? 0.0) >= total
                              ? () => Navigator.pop(
                                  context,
                                  double.tryParse(controller.text) ?? 0.0,
                                )
                              : null,
                          child: const Text('Bayar'),
                        ),
                      ],
                    );
                  },
                );
              },
            ) ??
            0.0;
        kembalian = (uangDiterima - cartProvider.total).clamp(
          0.0,
          double.infinity,
        );
        if (uangDiterima < cartProvider.total) return;
      } else {
        uangDiterima = cartProvider.total;
        kembalian = 0.0;
      }

      // First create the transaction through cart provider
      final transaction = await cartProvider.saveTransaction(
        customerName: customerName.trim(),
      );

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
              content: Text(
                'Pembayaran ${AppFormatters.formatTransactionId(transaction.id!)} berhasil',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal memproses pembayaran: ${transactionProvider.error ?? 'Error tidak diketahui'}',
              ),
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

  const PaymentMethodDialog({super.key, required this.paymentMethods});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Metode Pembayaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: paymentMethods.map((method) {
          return ListTile(
            title: Text(method.name),
            subtitle: method.description != null
                ? Text(method.description!)
                : null,
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
