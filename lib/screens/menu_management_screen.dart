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
  String _addOnFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Trigger rebuild to update FloatingActionButton
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories & Items'),
            Tab(text: 'Add-ons'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildAddOnsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateMenuItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Menu'),
              tooltip: 'Create New Menu Item',
            )
          : FloatingActionButton.extended(
              onPressed: () => _showCreateAddOnDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Add-on'),
              tooltip: 'Create New Add-on',
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
                    child: ListView.builder(
                      itemCount: menuProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = menuProvider.categories[index];
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
                          onPressed: selectedCategory != null
                              ? () => _showMenuItemDialog()
                              : null,
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
    final filteredItems = selectedCategory != null
        ? menuProvider.menuItems.where((item) => item.categoryId == selectedCategory).toList()
        : menuProvider.menuItems;

    if (filteredItems.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.restaurant_menu,
        message: selectedCategory != null
            ? 'No items in this category'
            : 'Select a category to view items',
        actionText: selectedCategory != null ? 'Add Item' : null,
        onAction: selectedCategory != null ? () => _showMenuItemDialog() : null,
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
              onTap: () => _selectMenuItem(item),
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
                            onPressed: () => _showAddOnDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Global Add-on'),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: _selectedMenuItem == null 
                                ? 'Select a menu item from "Categories & Items" tab first'
                                : 'Add add-on specific to ${_selectedMenuItem!.name}',
                            child: ElevatedButton.icon(
                              onPressed: _selectedMenuItem != null 
                                  ? () => _showAddOnDialog(menuItemId: _selectedMenuItem!.id)
                                  : null,
                              icon: const Icon(Icons.add_box),
                              label: const Text('Add Menu-Specific'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _addOnFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter Add-ons',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Add-ons')),
                            DropdownMenuItem(value: 'global', child: Text('Global Add-ons')),
                            DropdownMenuItem(value: 'menu-specific', child: Text('Menu-Specific Add-ons')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _addOnFilter = value ?? 'all';
                            });
                          },
                        ),
                      ),
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
    List<AddOn> filteredAddOns = menuProvider.addOns.where((addOn) {
      switch (_addOnFilter) {
        case 'global':
          return addOn.menuItemId == null;
        case 'menu-specific':
          return addOn.menuItemId != null;
        default:
          return true; // 'all'
      }
    }).toList();

    if (filteredAddOns.isEmpty) {
      String emptyMessage;
      switch (_addOnFilter) {
        case 'global':
          emptyMessage = 'No global add-ons available';
          break;
        case 'menu-specific':
          emptyMessage = 'No menu-specific add-ons available';
          break;
        default:
          emptyMessage = 'No add-ons available';
      }
      
      return EmptyStateWidget(
        icon: Icons.extension,
        message: emptyMessage,
        actionText: 'Add Add-on',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: addOn.menuItemId == null 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: addOn.menuItemId == null 
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        addOn.menuItemId == null ? 'Global' : 'Menu-Specific',
                        style: TextStyle(
                          color: addOn.menuItemId == null 
                              ? Colors.blue[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (addOn.menuItemId != null) ...[
                  const SizedBox(height: 4),
                  FutureBuilder<MenuItem?>(
                    future: _getMenuItemById(addOn.menuItemId!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          'For: ${snapshot.data!.name}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
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
                  _showAddOnDialog(addOn: addOn);
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

  void _showAddOnDialog({AddOn? addOn, int? menuItemId}) {
    final nameController = TextEditingController(text: addOn?.name ?? '');
    final descriptionController = TextEditingController(text: addOn?.description ?? '');
    final priceController = TextEditingController(text: addOn?.price.toString() ?? '');
    final cogsController = TextEditingController(text: addOn?.cogs?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(addOn == null 
            ? (menuItemId != null ? 'Add Menu-Specific Add-on' : 'Add Global Add-on')
            : 'Edit Add-on'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (menuItemId != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'This add-on will be specific to: ${_selectedMenuItem?.name ?? "Selected menu item"}',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Add-on Name',
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
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cogsController,
                decoration: const InputDecoration(
                  labelText: 'Cost of Goods Sold (COGS)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  helperText: 'Cost to make this add-on',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  priceController.text.trim().isEmpty) {
                return;
              }

              final price = double.tryParse(priceController.text.trim());
              final cogs = double.tryParse(cogsController.text.trim()) ?? 0.0;
              if (price == null || price < 0) return;

              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              
              if (addOn == null) {
                await menuProvider.createAddOn(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  price: price,
                  cogs: cogs,
                  menuItemId: menuItemId,
                );
              } else {
                await menuProvider.updateAddOn(
                  addOn.id,
                  nameController.text.trim(),
                  descriptionController.text.trim(),
                  price,
                  cogs,
                  addOn.isAvailable,
                );
              }

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(addOn == null ? 'Add' : 'Update'),
          ),
        ],
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

  Future<MenuItem?> _getMenuItemById(int menuItemId) async {
    final menuProvider = context.read<MenuProvider>();
    return menuProvider.menuItems.firstWhere(
      (item) => item.id == menuItemId,
      orElse: () => throw StateError('Menu item not found'),
    );
  }

  void _selectMenuItem(MenuItem? menuItem) {
    debugPrint('Selecting menu item: ${menuItem?.name ?? 'null'}');
    setState(() {
      _selectedMenuItem = menuItem;
    });
    
    // Load add-ons for the selected menu item
    if (menuItem != null) {
      context.read<MenuProvider>().loadMenuItemAddOns(menuItem.id);
    }
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
    String? description,
  }) async {
    final menuProvider = context.read<MenuProvider>();
    try {
      await menuProvider.createAddOn(
        name: name,
        price: price,
        cogs: cogs,
        description: description,
      );
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
      final description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();

      widget.onCreateAddOn(
        name: name,
        price: price,
        cogs: cogs,
        description: description,
      );

      Navigator.of(context).pop();
    }
  }
}
