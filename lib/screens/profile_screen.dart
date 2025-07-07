import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../utils/permissions.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'printer_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithActions(
        title: 'Profil',
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) {
            return const LoadingWidget(message: 'Memuat profil...');
          }

          return SingleChildScrollView(
            padding: AppStyles.defaultPadding,
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(context, user),
                
                const SizedBox(height: 24),
                
                // Profile Info
                _buildProfileInfo(context, user),
                
                const SizedBox(height: 24),
                
                // Actions
                _buildActions(context, authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return CustomCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 8),
          
          StatusChip(
            text: user.role.toUpperCase(),
            color: _getRoleColor(user.role),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, user) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Akun',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoItem(
            context,
            'Role',
            _getRoleDisplayName(user.role),
            Icons.badge_outlined,
          ),
          
          _buildInfoItem(
            context,
            'Bergabung',
            AppFormatters.formatDate(user.createdAt),
            Icons.calendar_today_outlined,
          ),
          
          _buildInfoItem(
            context,
            'Terakhir diperbarui',
            AppFormatters.formatDateTime(user.updatedAt),
            Icons.update_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Pengaturan'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to settings
                },
              ),
              
              const Divider(height: 1),
              
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Bantuan'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to help
                },
              ),
              
              const Divider(height: 1),
              
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('Pengaturan Printer'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrinterSettingsScreen(),
                    ),
                  );
                },
              ),
              
              const Divider(height: 1),
              
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Tentang Aplikasi'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        ElevatedButton.icon(
          onPressed: authProvider.isLoading ? null : () => _logout(context, authProvider),
          icon: authProvider.isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                  ),
                )
              : const Icon(Icons.logout),
          label: const Text('Keluar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onPrimary,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'manager':
        return AppColors.warning;
      case 'cashier':
        return AppColors.info;
      default:
        return AppColors.disabled;
    }
  }

  String _getRoleDisplayName(String role) {
    return Permissions.getRoleDisplayName(role);
  }

  void _logout(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.logout();
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Coffee POS',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.coffee,
        size: 48,
        color: AppColors.primary,
      ),
      children: [
        const Text(
          'Aplikasi Point of Sale untuk coffee shop yang modern dan mudah digunakan. '
          'Dikembangkan dengan Flutter untuk memberikan pengalaman terbaik.',
        ),
      ],
    );
  }
}
