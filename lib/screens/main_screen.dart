import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../utils/permissions.dart';
import 'pos_screen.dart';
import 'transactions_screen.dart';
import 'menu_management_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Get role-based screens and navigation items
        final screens = _getScreens(user.role);
        final navigationItems = _getNavigationItems(user.role);

        // Ensure current index is valid for the role
        if (_currentIndex >= screens.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentIndex = 0; // Reset to first tab
            });
          });
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: navigationItems,
          ),
        );
      },
    );
  }

  List<Widget> _getScreens(String role) {
    final List<Widget> screens = [
      const POSScreen(),
      const TransactionsScreen(),
    ];

    // Menu management for roles with permission
    if (Permissions.canManageMenu(role)) {
      screens.add(const MenuManagementScreen());
    }

    // Dashboard for roles with permission
    if (Permissions.canViewDashboard(role)) {
      screens.add(const DashboardScreen());
    }

    // Profile for all users
    screens.add(const ProfileScreen());

    return screens;
  }

  List<BottomNavigationBarItem> _getNavigationItems(String role) {
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale),
        label: 'POS',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long),
        label: 'Transaksi',
      ),
    ];

    // Menu management for roles with permission
    if (Permissions.canManageMenu(role)) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
      );
    }

    // Dashboard for roles with permission  
    if (Permissions.canViewDashboard(role)) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      );
    }

    // Profile for all users
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil',
      ),
    );

    return items;
  }
}
