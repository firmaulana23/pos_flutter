// Example usage of the new menu-specific add-ons functionality
// This file demonstrates how to use the enhanced add-ons API

import '../services/api_service.dart';
import '../providers/menu_provider.dart';

class AddOnsUsageExample {
  
  // Example 1: Get all add-ons for a specific menu item (includes both global and menu-specific)
  static Future<void> exampleGetMenuItemAddOns() async {
    print('=== Example 1: Get Add-ons for Menu Item ===');
    
    try {
      // Get add-ons for Latte (menu item ID 4)
      final addOns = await ApiService.getMenuItemAddOns(4, usePublicEndpoint: true);
      
      print('Found ${addOns.length} add-ons for menu item 4 (Latte):');
      for (final addOn in addOns) {
        final type = addOn.menuItemId == null ? 'Global' : 'Menu-specific';
        print('  - ${addOn.name} (\$${addOn.price}) - $type');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  
  // Example 2: Get only global add-ons (available for all menu items)
  static Future<void> exampleGetGlobalAddOns() async {
    print('\n=== Example 2: Get Global Add-ons ===');
    
    try {
      final globalAddOns = await ApiService.getGlobalAddOns(usePublicEndpoint: true);
      
      print('Found ${globalAddOns.length} global add-ons:');
      for (final addOn in globalAddOns) {
        print('  - ${addOn.name} (\$${addOn.price}) - Available for all items');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  
  // Example 3: Get filtered add-ons for a specific menu item
  static Future<void> exampleGetFilteredAddOns() async {
    print('\n=== Example 3: Get Filtered Add-ons ===');
    
    try {
      // Get available add-ons for menu item 4 using the filtered endpoint
      final filteredAddOns = await ApiService.getFilteredAddOns(
        usePublicEndpoint: true,
        menuItemId: 4,
        available: true,
      );
      
      print('Found ${filteredAddOns.length} available add-ons for menu item 4:');
      for (final addOn in filteredAddOns) {
        final type = addOn.menuItemId == null ? 'Global' : 'Menu-specific';
        print('  - ${addOn.name} (\$${addOn.price}) - $type');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  
  // Example 4: Using MenuProvider methods
  static Future<void> exampleUsingMenuProvider() async {
    print('\n=== Example 4: Using MenuProvider ===');
    
    try {
      final menuProvider = MenuProvider();
      
      // Load all add-ons first
      await menuProvider.loadAddOns(usePublicEndpoint: true);
      print('Loaded ${menuProvider.addOns.length} total add-ons');
      
      // Get global add-ons from loaded data
      final globalAddOns = menuProvider.globalAddOns;
      print('Global add-ons: ${globalAddOns.length}');
      
      // Get available add-ons for a specific menu item
      final availableForLatte = await menuProvider.getAvailableAddOnsForMenuItem(4);
      print('Available add-ons for Latte: ${availableForLatte.length}');
      
      // Load add-ons specifically for a menu item
      final menuItemAddOns = await menuProvider.loadMenuItemAddOns(4);
      print('Add-ons for menu item 4: ${menuItemAddOns.length}');
      
    } catch (e) {
      print('Error: $e');
    }
  }
  
  // Run all examples
  static Future<void> runAllExamples() async {
    print('🍰 Menu-Specific Add-ons Examples');
    print('=' * 50);
    
    await exampleGetMenuItemAddOns();
    await exampleGetGlobalAddOns();
    await exampleGetFilteredAddOns();
    await exampleUsingMenuProvider();
    
    print('\n✅ All examples completed!');
  }
}

/*
Usage in your app:

// In POS screen when user selects a menu item:
final menuItemId = selectedMenuItem.id;
final availableAddOns = await ApiService.getMenuItemAddOns(menuItemId, usePublicEndpoint: true);

// Display add-ons to user for selection
for (final addOn in availableAddOns) {
  final isGlobal = addOn.menuItemId == null;
  final description = isGlobal ? 'Available for all items' : 'Specific to this item';
  
  // Show add-on in UI with name, price, and description
  showAddOnOption(addOn.name, addOn.price, description);
}

// When user adds to cart:
final selectedAddOns = userSelectedAddOns; // List<AddOn>
cartProvider.addItem(selectedMenuItem, quantity: 1, addOns: selectedAddOns);
*/
