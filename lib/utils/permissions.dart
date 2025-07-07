class Permissions {
  // Define role-based permissions
  static const Map<String, List<String>> rolePermissions = {
    'admin': [
      'view_dashboard',
      'manage_menu',
      'manage_users',
      'view_transactions',
      'process_payments',
      'manage_settings',
      'view_reports',
    ],
    'manager': [
      'view_dashboard',
      'manage_menu',
      'view_transactions',
      'process_payments',
      'view_reports',
    ],
    'cashier': [
      'view_transactions',
      'process_payments',
    ],
  };

  // Check if user has specific permission
  static bool hasPermission(String userRole, String permission) {
    final permissions = rolePermissions[userRole] ?? [];
    return permissions.contains(permission);
  }

  // Check if user can access menu management
  static bool canManageMenu(String userRole) {
    return hasPermission(userRole, 'manage_menu');
  }

  // Check if user can view dashboard
  static bool canViewDashboard(String userRole) {
    return hasPermission(userRole, 'view_dashboard');
  }

  // Check if user can manage settings
  static bool canManageSettings(String userRole) {
    return hasPermission(userRole, 'manage_settings');
  }

  // Get list of screens available for role
  static List<String> getAvailableScreens(String userRole) {
    final List<String> screens = ['pos', 'transactions', 'profile'];
    
    if (canManageMenu(userRole)) {
      screens.insert(2, 'menu');
    }
    
    if (canViewDashboard(userRole)) {
      screens.insert(screens.length - 1, 'dashboard');
    }
    
    return screens;
  }

  // Check if current user role is valid
  static bool isValidRole(String role) {
    return rolePermissions.containsKey(role);
  }

  // Get role display name
  static String getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Kasir';
      default:
        return 'Unknown';
    }
  }
}
