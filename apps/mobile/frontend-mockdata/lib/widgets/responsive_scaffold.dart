import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String activeRoute;
  final bool hideNavigation;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.activeRoute = 'home',
    this.hideNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final isDark = appProvider.isDarkMode;
    
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    // Check if path is an auth path
    final bool isAuthRoute = const ['splash', 'login', 'register', 'verify-email'].contains(activeRoute);
    final bool showNav = !hideNavigation && !isAuthRoute;

    // Nav destinations
    final List<Map<String, dynamic>> navItems = [
      {'label': 'Home', 'icon': Icons.home, 'route': '/'},
      {'label': 'Deals', 'icon': Icons.business_center, 'route': '/deals'},
      {'label': 'Contracts', 'icon': Icons.description, 'route': '/contracts'},
      {'label': 'Notifications', 'icon': Icons.notifications, 'route': '/notifications'},
      {'label': 'Settings', 'icon': Icons.settings, 'route': '/settings'},
    ];

    Widget? bottomNavBar;
    if (showNav && !isDesktop) {
      int activeIndex = navItems.indexWhere((item) {
        if (activeRoute == 'home' && item['route'] == '/') return true;
        if (activeRoute == 'deals' && item['route'] == '/deals') return true;
        if (activeRoute == 'contracts' && item['route'] == '/contracts') return true;
        if (activeRoute == 'notifications' && item['route'] == '/notifications') return true;
        if (activeRoute == 'settings' && item['route'] == '/settings') return true;
        return false;
      });
      if (activeIndex == -1) activeIndex = 0;

      bottomNavBar = Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: activeIndex,
          onTap: (index) {
            context.go(navItems[index]['route']);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon'] as IconData),
              label: item['label'] as String,
            );
          }).toList(),
        ),
      );
    }

    // Build Desktop Header / Normal AppBar
    AppBar buildAppBar() {
      return AppBar(
        automaticallyImplyLeading: isAuthRoute ? false : true,
        title: InkWell(
          onTap: () => context.go('/'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 34,
                width: 34,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF02529C), Color(0xFF00B4D8)],
                ).createShader(bounds),
                child: const Text(
                  'IDEAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (showNav && isDesktop)
            ...navItems.map((item) {
              final isSelected = activeRoute == item['label'].toLowerCase() || 
                  (activeRoute == 'home' && item['label'] == 'Home');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextButton(
                  onPressed: () => context.go(item['route']),
                  style: TextButton.styleFrom(
                    foregroundColor: isSelected ? theme.primaryColor : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  child: Text(
                    item['label'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => appProvider.toggleTheme(),
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: theme.primaryColor,
            ),
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 12),
        ],
      );
    }

    return Scaffold(
      appBar: buildAppBar(),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavBar,
    );
  }
}
