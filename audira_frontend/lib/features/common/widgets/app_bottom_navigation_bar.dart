import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int? selectedIndex;

  const AppBottomNavigationBar({
    super.key,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final userRole = authProvider.currentUser?.role;

    return NavigationBar(
      selectedIndex: selectedIndex ?? 0,
      onDestinationSelected: (index) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
          arguments: index,
        );
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        const NavigationDestination(
          icon: Icon(Icons.store_outlined),
          selectedIcon: Icon(Icons.store),
          label: 'Tienda',
        ),
        if (isAuthenticated)
          const NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Biblioteca',
          ),
        const NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'Carrito',
        ),
        if (isAuthenticated && userRole == 'ARTIST')
          const NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Studio',
          ),
        if (isAuthenticated && userRole == 'ADMIN')
          const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        if (isAuthenticated)
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
      ],
      backgroundColor: AppTheme.surfaceBlack,
      indicatorColor: selectedIndex == null
          ? Colors.transparent
          : AppTheme.primaryBlue.withValues(alpha: 0.2),
    );
  }
}
