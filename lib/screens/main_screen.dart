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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    navigationItems.length,
                    (index) => _buildNavItem(
                      index,
                      navigationItems[index].icon as Icon,
                      navigationItems[index].label!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _getScreens(String role) {
    final List<Widget> screens = [
      const POSScreen(),
      const TransactionsScreen(),
      const MenuManagementScreen(),
      const ProfileScreen(),
    ];

    // Menu management for roles with permission
    // if (Permissions.canManageMenu(role)) {
    //   screens.add(const MenuManagementScreen());
    // }

    // Dashboard for roles with permission
    // if (Permissions.canViewDashboard(role)) {
    //   screens.add(const DashboardScreen());
    // }

    // Profile for all users
    // screens.add(const ProfileScreen());

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
      const BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    // Menu management for roles with permission
    // if (Permissions.canManageMenu(role)) {
    //   items.add(
    //     const BottomNavigationBarItem(
    //       icon: Icon(Icons.restaurant_menu),
    //       label: 'Menu',
    //     ),
    //   );
    // }

    // Dashboard for roles with permission  
    // if (Permissions.canViewDashboard(role)) {
    //   items.add(
    //     const BottomNavigationBarItem(
    //       icon: Icon(Icons.dashboard),
    //       label: 'Dashboard',
    //     ),
    //   );
    // }

    // Profile for all users
    // items.add(
    //   const BottomNavigationBarItem(
    //     icon: Icon(Icons.person),
    //     label: 'Profil',
    //   ),
    // );

    return items;
  }

  Widget _buildNavItem(int index, Icon icon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon.icon,
              color: isSelected ? AppColors.onPrimary : AppColors.disabled,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
