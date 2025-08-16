import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/menu_provider.dart';
import '../models/menu.dart';
import '../widgets/common_widgets.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? selectedCategory;
  MenuItem? _selectedMenuItem;
  
  // Search functionality
  final TextEditingController _menuSearchController = TextEditingController();
  final TextEditingController _addOnSearchController = TextEditingController();
  String _menuSearchQuery = '';
  String _addOnSearchQuery = '';
  bool _showMenuSearch = false;
  bool _showAddOnSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Trigger rebuild when tab changes
      });
    });
    
    // Add listeners for search functionality
    _menuSearchController.addListener(() {
      setState(() {
        _menuSearchQuery = _menuSearchController.text.toLowerCase();
      });
    });
    
    _addOnSearchController.addListener(() {
      setState(() {
        _addOnSearchQuery = _addOnSearchController.text.toLowerCase();
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _menuSearchController.dispose();
    _addOnSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    await menuProvider.loadCategories(usePublicEndpoint: true);
    await menuProvider.loadMenuItems(usePublicEndpoint: true);
    await menuProvider.loadAddOns(usePublicEndpoint: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: Icon(_tabController.index == 0 
                ? (_showMenuSearch ? Icons.close : Icons.search)
                : (_showAddOnSearch ? Icons.close : Icons.search)),
            onPressed: () {
              setState(() {
                if (_tabController.index == 0) {
                  _showMenuSearch = !_showMenuSearch;
                  if (!_showMenuSearch) {
                    _menuSearchController.clear();
                    _menuSearchQuery = '';
                  }
                } else {
                  _showAddOnSearch = !_showAddOnSearch;
                  if (!_showAddOnSearch) {
                    _addOnSearchController.clear();
                    _addOnSearchQuery = '';
                  }
                }
              });
            },
            tooltip: 'Search',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Categories & Items'),
            Tab(text: 'Add-ons'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showMenuSearch && _tabController.index == 0) _buildMenuSearchBar(),
          if (_showAddOnSearch && _tabController.index == 1) _buildAddOnSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(),
                _buildAddOnsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: TextField(
        controller: _menuSearchController,
        decoration: InputDecoration(
          hintText: 'Search menu items and categories...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _menuSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _menuSearchController.clear();
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
      ),
    );
  }

  Widget _buildAddOnSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: TextField(
        controller: _addOnSearchController,
        decoration: InputDecoration(
          hintText: 'Search add-ons...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _addOnSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _addOnSearchController.clear();
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
      ),
    );
  }

  Widget _buildMenuTab() {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.isLoading) {
          return const LoadingWidget();
        }

        if (menuProvider.error != null) {
          return AppErrorWidget(
            message: menuProvider.error!,
            onRetry: _loadData,
          );
        }

        return Row(
          children: [
            // Categories sidebar
            Container(
              width: 200,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _showCategoryDialog(),
                          tooltip: 'Add Category',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        // Filter categories by search query
                        final filteredCategories = _menuSearchQuery.isEmpty
                            ? menuProvider.categories
                            : menuProvider.categories.where((category) {
                                final nameMatch = category.name.toLowerCase().contains(_menuSearchQuery);
                                final descriptionMatch = category.description?.toLowerCase().contains(_menuSearchQuery) ?? false;
                                return nameMatch || descriptionMatch;
                              }).toList();
                        
                        if (filteredCategories.isEmpty && _menuSearchQuery.isNotEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No categories match your search',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            final isSelected = selectedCategory == category.id;

                            return ListTile(
                              title: Text(category.name),
                              subtitle: Text('${category.description}'),
                              selected: isSelected,
                              selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              onTap: () {
                                setState(() {
                                  selectedCategory = isSelected ? null : category.id;
                                });
                              },
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showCategoryDialog(category: category);
                                  } else if (value == 'delete') {
                                    _deleteCategory(category);
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedCategory != null
                                ? 'Menu Items - ${menuProvider.categories.firstWhere((c) => c.id == selectedCategory).name}'
                                : 'Menu Items - All Categories',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateMenuItemDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildMenuItemsList(menuProvider),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItemsList(MenuProvider menuProvider) {
    List<MenuItem> filteredItems;
    
    // First filter by category if selected
    if (selectedCategory != null) {
      filteredItems = menuProvider.menuItems
          .where((item) => item.categoryId == selectedCategory)
          .toList();
    } else {
      filteredItems = menuProvider.menuItems;
    }
    
    // Then filter by search query if provided
    if (_menuSearchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        final nameMatch = item.name.toLowerCase().contains(_menuSearchQuery);
        final descriptionMatch = item.description?.toLowerCase().contains(_menuSearchQuery) ?? false;
        final categoryMatch = menuProvider.getCategoryById(item.categoryId)?.name.toLowerCase().contains(_menuSearchQuery) ?? false;
        return nameMatch || descriptionMatch || categoryMatch;
      }).toList();
    }

    if (filteredItems.isEmpty) {
      String emptyMessage;
      if (_menuSearchQuery.isNotEmpty) {
        emptyMessage = 'No items match your search "$_menuSearchQuery"';
      } else if (selectedCategory != null) {
        emptyMessage = 'No items in this category';
      } else {
        emptyMessage = 'Select a category to view items';
      }
      
      return EmptyStateWidget(
        icon: Icons.restaurant_menu,
        message: emptyMessage,
        actionText: selectedCategory != null && _menuSearchQuery.isEmpty ? 'Add Item' : null,
        onAction: selectedCategory != null && _menuSearchQuery.isEmpty ? () => _showMenuItemDialog() : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return CustomCard(
          child: Container(
            decoration: BoxDecoration(
              border: _selectedMenuItem?.id == item.id
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              selected: _selectedMenuItem?.id == item.id,
              leading: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.coffee),
                  ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description?.isNotEmpty == true)
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    PriceTag(price: AppFormatters.formatCurrency(item.price)),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: item.isAvailable ? 'Available' : 'Unavailable',
                      color: item.isAvailable ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(item.isAvailable ? Icons.visibility_off : Icons.visibility),
                      const SizedBox(width: 8),
                      Text(item.isAvailable ? 'Make Unavailable' : 'Make Available'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showMenuItemDialog(item: item);
                } else if (value == 'toggle') {
                  _toggleItemAvailability(item);
                } else if (value == 'delete') {
                  _deleteMenuItem(item);
                }
              },
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOnsTab() {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.isLoading) {
          return const LoadingWidget();
        }

        if (menuProvider.error != null) {
          return AppErrorWidget(
            message: menuProvider.error!,
            onRetry: _loadData,
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add-ons',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showCreateAddOnDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Add-on'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_selectedMenuItem != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Selected: ${_selectedMenuItem!.name}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildAddOnsList(menuProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddOnsList(MenuProvider menuProvider) {
    // Filter add-ons based on selected filter
    List<AddOn> filteredAddOns = menuProvider.addOns;
    
    // Apply search filter if search query exists
    if (_addOnSearchQuery.isNotEmpty) {
      filteredAddOns = filteredAddOns.where((addOn) {
        final nameMatch = addOn.name.toLowerCase().contains(_addOnSearchQuery);
        final descriptionMatch = addOn.description?.toLowerCase().contains(_addOnSearchQuery) ?? false;
        return nameMatch || descriptionMatch;
      }).toList();
    }

    if (filteredAddOns.isEmpty) {
      String emptyMessage;
      if (_addOnSearchQuery.isNotEmpty) {
        emptyMessage = 'No add-ons match your search "$_addOnSearchQuery"';
      } else {
        emptyMessage = 'No add-ons available';
      }
      
      return EmptyStateWidget(
        icon: Icons.extension,
        message: emptyMessage,
        actionText: _addOnSearchQuery.isEmpty ? 'Add Add-on' : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAddOns.length,
      itemBuilder: (context, index) {
        final addOn = filteredAddOns[index];
        return CustomCard(
          child: ListTile(
            title: Text(
              addOn.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (addOn.description?.isNotEmpty == true) ...[
                  Text(addOn.description!),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    PriceTag(price: AppFormatters.formatCurrency(addOn.price)),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: addOn.isAvailable ? 'Available' : 'Unavailable',
                      color: addOn.isAvailable ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(addOn.isAvailable ? Icons.visibility_off : Icons.visibility),
                      const SizedBox(width: 8),
                      Text(addOn.isAvailable ? 'Make Unavailable' : 'Make Available'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditAddOnDialog(addOn);
                } else if (value == 'toggle') {
                  _toggleAddOnAvailability(addOn);
                } else if (value == 'delete') {
                  _deleteAddOn(addOn);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (nameController.text.trim().isEmpty) return;

              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              
              if (category == null) {
                await menuProvider.createCategory(
                  nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );
              } else {
                await menuProvider.updateCategory(
                  category.id,
                  nameController.text.trim(),
                  descriptionController.text.trim(),
                );
              }

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(category == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showMenuItemDialog({MenuItem? item}) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    
    if (menuProvider.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a category first')),
      );
      return;
    }

    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    int? selectedCategoryId = item?.categoryId ?? selectedCategory ?? menuProvider.categories.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'Add Menu Item' : 'Edit Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: menuProvider.categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
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
                if (nameController.text.trim().isEmpty ||
                    selectedCategoryId == null ||
                    priceController.text.trim().isEmpty) {
                  return;
                }

                final price = double.tryParse(priceController.text.trim());
                if (price == null || price < 0) return;

                if (item == null) {
                  await menuProvider.createMenuItem(
                    name: nameController.text.trim(),
                    categoryId: selectedCategoryId!,
                    description: descriptionController.text.trim(),
                    price: price,
                    cogs: price * 0.3, // Simplified COGS calculation
                  );
                } else {
                  await menuProvider.updateMenuItem(
                    item.id,
                    nameController.text.trim(),
                    selectedCategoryId!,
                    descriptionController.text.trim(),
                    price,
                    item.isAvailable,
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(item == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }


  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This will also delete all items in this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              await menuProvider.deleteCategory(category.id);
              
              if (selectedCategory == category.id) {
                setState(() {
                  selectedCategory = null;
                });
              }
              
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteMenuItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              await menuProvider.deleteMenuItem(item.id);
              
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAddOn(AddOn addOn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Add-on'),
        content: Text('Are you sure you want to delete "${addOn.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              await menuProvider.deleteAddOn(addOn.id);
              
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleItemAvailability(MenuItem item) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    await menuProvider.updateMenuItem(
      item.id,
      item.name,
      item.categoryId,
      item.description ?? '',
      item.price,
      !item.isAvailable,
    );
  }

  void _toggleAddOnAvailability(AddOn addOn) async {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    await menuProvider.updateAddOn(
      addOn.id,
      addOn.name,
      addOn.description ?? '',
      addOn.price,
      addOn.cogs ?? 0.0,
      !addOn.isAvailable,
    );
  }

  void _showCreateMenuItemDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateMenuItemDialog(
        categories: context.read<MenuProvider>().categories,
        onCreateMenuItem: _createMenuItem,
      ),
    );
  }

  void _showCreateAddOnDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateAddOnDialog(
        onCreateAddOn: _createAddOn,
      ),
    );
  }

  void _showEditAddOnDialog(AddOn addOn) {
    showDialog(
      context: context,
      builder: (context) => EditAddOnDialog(
        addOn: addOn,
        onUpdateAddOn: _updateAddOn,
        onAddMenuItems: _addMenuItemsToAddOn,
        onRemoveMenuItems: _removeMenuItemsFromAddOn,
      ),
    );
  }

  void _createMenuItem({
    required String name,
    required double price,
    required double cogs,
    required int categoryId,
    String? description,
    String? imageUrl,
  }) async {
    final menuProvider = context.read<MenuProvider>();
    try {
      await menuProvider.createMenuItem(
        name: name,
        price: price,
        cogs: cogs,
        categoryId: categoryId,
        description: description,
        imageUrl: imageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu item "$name" created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create menu item: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _createAddOn({
    required String name,
    required double price,
    required double cogs,
    required List<int> menuItemIds,
    String? description,
  }) async {
    final menuProvider = context.read<MenuProvider>();
    try {
      final success = await menuProvider.createAddOn(
        name: name,
        price: price,
        cogs: cogs,
        menuItemIds: menuItemIds,
        description: description,
      );
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(menuProvider.error ?? 'Failed to create add-on'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add-on "$name" created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create add-on: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _updateAddOn({
    required int id,
    required String name,
    required double price,
    required double cogs,
    String? description,
    bool? isAvailable,
  }) async {
    final menuProvider = context.read<MenuProvider>();
    try {
      await menuProvider.updateAddOn(
        id,
        name,
        description ?? '',
        price,
        cogs,
        isAvailable ?? true,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add-on "$name" updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating add-on: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _addMenuItemsToAddOn({
    required int addOnId,
    required List<int> menuItemIds,
  }) async {
    final menuProvider = context.read<MenuProvider>();
    try {
      final success = await menuProvider.addMenuItemsToAddOn(addOnId, menuItemIds);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Menu items added to add-on successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(menuProvider.error ?? 'Failed to add menu items'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding menu items: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeMenuItemsFromAddOn({
    required int addOnId,
    required List<int> menuItemIds,
  }) async {
    final menuProvider = context.read<MenuProvider>();
    try {
      final success = await menuProvider.removeMenuItemsFromAddOn(addOnId, menuItemIds);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Menu items removed from add-on successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(menuProvider.error ?? 'Failed to remove menu items'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing menu items: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class CreateMenuItemDialog extends StatefulWidget {
  final List<Category> categories;
  final Function({
    required String name,
    required double price,
    required double cogs,
    required int categoryId,
    String? description,
    String? imageUrl,
  }) onCreateMenuItem;

  const CreateMenuItemDialog({
    super.key,
    required this.categories,
    required this.onCreateMenuItem,
  });

  @override
  State<CreateMenuItemDialog> createState() => _CreateMenuItemDialogState();
}

class _CreateMenuItemDialogState extends State<CreateMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cogsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  int? _selectedCategoryId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cogsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Menu Item'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category dropdown
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Price field
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // COGS field
                TextFormField(
                  controller: _cogsController,
                  decoration: const InputDecoration(
                    labelText: 'Cost of Goods Sold (COGS) *',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                    helperText: 'Cost to make this item',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'COGS is required';
                    }
                    final cogs = double.tryParse(value);
                    if (cogs == null || cogs < 0) {
                      return 'Please enter a valid COGS';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Image URL field
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text);
      final cogs = double.parse(_cogsController.text);
      final categoryId = _selectedCategoryId!;
      final description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();
      final imageUrl = _imageUrlController.text.trim().isEmpty 
          ? null 
          : _imageUrlController.text.trim();

      widget.onCreateMenuItem(
        name: name,
        price: price,
        cogs: cogs,
        categoryId: categoryId,
        description: description,
        imageUrl: imageUrl,
      );

      Navigator.of(context).pop();
    }
  }
}

class CreateAddOnDialog extends StatefulWidget {
  final Function({
    required String name,
    required double price,
    required double cogs,
    required List<int> menuItemIds,
    String? description,
  }) onCreateAddOn;

  const CreateAddOnDialog({
    super.key,
    required this.onCreateAddOn,
  });

  @override
  State<CreateAddOnDialog> createState() => _CreateAddOnDialogState();
}

class _CreateAddOnDialogState extends State<CreateAddOnDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cogsController = TextEditingController();
  List<int> _selectedMenuItemIds = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cogsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Add-on'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Price field
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // COGS field
                TextFormField(
                  controller: _cogsController,
                  decoration: const InputDecoration(
                    labelText: 'Cost of Goods Sold (COGS) *',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                    helperText: 'Cost to make this add-on',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'COGS is required';
                    }
                    final cogs = double.tryParse(value);
                    if (cogs == null || cogs < 0) {
                      return 'Please enter a valid COGS';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Menu Items Selection
                Consumer<MenuProvider>(
                  builder: (context, menuProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assign to Menu Items *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (menuProvider.menuItems.isEmpty)
                          const Text(
                            'No menu items available. Please create menu items first.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView.builder(
                              itemCount: menuProvider.menuItems.length,
                              itemBuilder: (context, index) {
                                final menuItem = menuProvider.menuItems[index];
                                final isSelected = _selectedMenuItemIds.contains(menuItem.id);
                                
                                return CheckboxListTile(
                                  title: Text(menuItem.name),
                                  subtitle: Text('${menuItem.category?.name ?? 'No Category'} - ${AppFormatters.formatCurrency(menuItem.price)}'),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedMenuItemIds.add(menuItem.id);
                                      } else {
                                        _selectedMenuItemIds.remove(menuItem.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedMenuItemIds.length} menu item(s) selected',
                          style: TextStyle(
                            color: _selectedMenuItemIds.isEmpty ? Colors.red : Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Validate menu item selection
      if (_selectedMenuItemIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one menu item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text);
      final cogs = double.parse(_cogsController.text);
      final description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();

      widget.onCreateAddOn(
        name: name,
        price: price,
        cogs: cogs,
        menuItemIds: _selectedMenuItemIds,
        description: description,
      );

      Navigator.of(context).pop();
    }
  }
}

class EditAddOnDialog extends StatefulWidget {
  final AddOn addOn;
  final Function({
    required int id,
    required String name,
    required double price,
    required double cogs,
    String? description,
    bool? isAvailable,
  }) onUpdateAddOn;
  final Function({
    required int addOnId,
    required List<int> menuItemIds,
  }) onAddMenuItems;
  final Function({
    required int addOnId,
    required List<int> menuItemIds,
  }) onRemoveMenuItems;

  const EditAddOnDialog({
    super.key,
    required this.addOn,
    required this.onUpdateAddOn,
    required this.onAddMenuItems,
    required this.onRemoveMenuItems,
  });

  @override
  State<EditAddOnDialog> createState() => _EditAddOnDialogState();
}

class _EditAddOnDialogState extends State<EditAddOnDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _cogsController;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.addOn.name);
    _descriptionController = TextEditingController(text: widget.addOn.description ?? '');
    _priceController = TextEditingController(text: widget.addOn.price.toString());
    _cogsController = TextEditingController(text: widget.addOn.cogs?.toString() ?? '0.0');
    _isAvailable = widget.addOn.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cogsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Add-on: ${widget.addOn.name}'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Price field
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // COGS field
                TextFormField(
                  controller: _cogsController,
                  decoration: const InputDecoration(
                    labelText: 'Cost of Goods Sold (COGS) *',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'COGS is required';
                    }
                    final cogs = double.tryParse(value);
                    if (cogs == null || cogs < 0) {
                      return 'Please enter a valid COGS';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Availability toggle
                SwitchListTile(
                  title: const Text('Available'),
                  subtitle: Text(_isAvailable ? 'This add-on is available for selection' : 'This add-on is not available for selection'),
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Menu Items Management Section
                const Divider(),
                Row(
                  children: [
                    Icon(Icons.restaurant_menu, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Menu Items Management',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Current menu items (if any from API response)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Assigned Menu Items:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This add-on is currently assigned to menu items. Use the buttons below to manage assignments.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons for menu item management
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddMenuItemsDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Menu Items'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRemoveMenuItemsDialog(),
                        icon: const Icon(Icons.remove, size: 16),
                        label: const Text('Remove Menu Items'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text);
      final cogs = double.parse(_cogsController.text);
      final description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();

      widget.onUpdateAddOn(
        id: widget.addOn.id,
        name: name,
        price: price,
        cogs: cogs,
        description: description,
        isAvailable: _isAvailable,
      );

      Navigator.of(context).pop();
    }
  }

  void _showAddMenuItemsDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMenuItemsToAddOnDialog(
        addOnId: widget.addOn.id,
        addOnName: widget.addOn.name,
        onAddMenuItems: (menuItemIds) {
          widget.onAddMenuItems(
            addOnId: widget.addOn.id,
            menuItemIds: menuItemIds,
          );
        },
      ),
    );
  }

  void _showRemoveMenuItemsDialog() {
    showDialog(
      context: context,
      builder: (context) => RemoveMenuItemsFromAddOnDialog(
        addOnId: widget.addOn.id,
        addOnName: widget.addOn.name,
        onRemoveMenuItems: (menuItemIds) {
          widget.onRemoveMenuItems(
            addOnId: widget.addOn.id,
            menuItemIds: menuItemIds,
          );
        },
      ),
    );
  }
}

class AddMenuItemsToAddOnDialog extends StatefulWidget {
  final int addOnId;
  final String addOnName;
  final Function(List<int> menuItemIds) onAddMenuItems;

  const AddMenuItemsToAddOnDialog({
    super.key,
    required this.addOnId,
    required this.addOnName,
    required this.onAddMenuItems,
  });

  @override
  State<AddMenuItemsToAddOnDialog> createState() => _AddMenuItemsToAddOnDialogState();
}

class _AddMenuItemsToAddOnDialogState extends State<AddMenuItemsToAddOnDialog> {
  List<int> _selectedMenuItemIds = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Menu Items to "${widget.addOnName}"'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Consumer<MenuProvider>(
          builder: (context, menuProvider, child) {
            if (menuProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (menuProvider.menuItems.isEmpty) {
              return const Center(
                child: Text('No menu items available'),
              );
            }

            return Column(
              children: [
                Text(
                  'Select menu items to add to this add-on:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuProvider.menuItems.length,
                    itemBuilder: (context, index) {
                      final menuItem = menuProvider.menuItems[index];
                      final isSelected = _selectedMenuItemIds.contains(menuItem.id);
                      
                      return CheckboxListTile(
                        title: Text(menuItem.name),
                        subtitle: Text('${menuItem.category?.name ?? 'No Category'} - ${AppFormatters.formatCurrency(menuItem.price)}'),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedMenuItemIds.add(menuItem.id);
                            } else {
                              _selectedMenuItemIds.remove(menuItem.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedMenuItemIds.length} menu item(s) selected',
                  style: TextStyle(
                    color: _selectedMenuItemIds.isEmpty ? Colors.grey : Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedMenuItemIds.isEmpty ? null : _submitSelection,
          child: const Text('Add Selected'),
        ),
      ],
    );
  }

  void _submitSelection() {
    if (_selectedMenuItemIds.isNotEmpty) {
      widget.onAddMenuItems(_selectedMenuItemIds);
      Navigator.of(context).pop();
    }
  }
}

class RemoveMenuItemsFromAddOnDialog extends StatefulWidget {
  final int addOnId;
  final String addOnName;
  final Function(List<int> menuItemIds) onRemoveMenuItems;

  const RemoveMenuItemsFromAddOnDialog({
    super.key,
    required this.addOnId,
    required this.addOnName,
    required this.onRemoveMenuItems,
  });

  @override
  State<RemoveMenuItemsFromAddOnDialog> createState() => _RemoveMenuItemsFromAddOnDialogState();
}

class _RemoveMenuItemsFromAddOnDialogState extends State<RemoveMenuItemsFromAddOnDialog> {
  List<int> _selectedMenuItemIds = [];
  bool _isLoading = true;
  List<MenuItem> _currentMenuItems = [];

  @override
  void initState() {
    super.initState();
    // TODO: In a real implementation, you'd fetch the current menu items for this add-on
    // For now, we'll show all menu items (user needs to know which ones are currently assigned)
    _loadCurrentMenuItems();
  }

  void _loadCurrentMenuItems() {
    // Placeholder: In real implementation, you'd call an API to get menu items for this add-on
    // For now, we'll use all menu items as a demo
    final menuProvider = context.read<MenuProvider>();
    setState(() {
      _currentMenuItems = menuProvider.menuItems;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Remove Menu Items from "${widget.addOnName}"'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select menu items to remove from this add-on. Note: An add-on must be assigned to at least one menu item.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_currentMenuItems.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No menu items currently assigned to this add-on'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _currentMenuItems.length,
                      itemBuilder: (context, index) {
                        final menuItem = _currentMenuItems[index];
                        final isSelected = _selectedMenuItemIds.contains(menuItem.id);
                        
                        return CheckboxListTile(
                          title: Text(menuItem.name),
                          subtitle: Text('${menuItem.category?.name ?? 'No Category'} - ${AppFormatters.formatCurrency(menuItem.price)}'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedMenuItemIds.add(menuItem.id);
                              } else {
                                _selectedMenuItemIds.remove(menuItem.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedMenuItemIds.length} menu item(s) selected for removal',
                  style: TextStyle(
                    color: _selectedMenuItemIds.isEmpty ? Colors.grey : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedMenuItemIds.isEmpty ? null : _submitSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Remove Selected'),
        ),
      ],
    );
  }

  void _submitSelection() {
    if (_selectedMenuItemIds.isNotEmpty) {
      widget.onRemoveMenuItems(_selectedMenuItemIds);
      Navigator.of(context).pop();
    }
  }
}
