path = "lib/shared/ideal_ui.dart"
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

# 1. Ajouter les imports necessaires
old_imports = """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';"""
new_imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';
import '../core/locale/app_strings.dart';
import '../core/locale/locale_provider.dart';"""
assert old_imports in src, "imports marker introuvable"
src = src.replace(old_imports, new_imports, 1)

# 2. Transformer IdealAppScaffold en ConsumerWidget
old_class = """class IdealAppScaffold extends StatelessWidget {
  final String activeRoute;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  const IdealAppScaffold({
    super.key,
    required this.activeRoute,
    required this.body,
    this.actions = const [],
    this.showBack = false,
  });
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final navItems = _navItems;"""
new_class = """class IdealAppScaffold extends ConsumerWidget {
  final String activeRoute;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  const IdealAppScaffold({
    super.key,
    required this.activeRoute,
    required this.body,
    this.actions = const [],
    this.showBack = false,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final lang = ref.watch(localeProvider).languageCode;
    final navItems = _buildNavItems(lang);"""
assert old_class in src, "classe marker introuvable"
src = src.replace(old_class, new_class, 1)

# 3. Remplacer la liste statique _navItems par une fonction de construction traduite
old_list = """const _navItems = <_NavItem>[
  _NavItem(
    'contracts',
    'Contracts',
    Icons.description_outlined,
    AppRoutes.contracts,
  ),
  _NavItem(
    'notifications',
    'Notifications',
    Icons.notifications_outlined,
    AppRoutes.notifications,
  ),
  _NavItem('documents', 'Documents', Icons.document_scanner, '/documents'),_NavItem('mycontracts', 'Mes Contrats', Icons.assignment_turned_in, AppRoutes.myContracts),
    _NavItem('chat', 'AI Assistant', Icons.smart_toy_outlined, AppRoutes.chat),
  _NavItem('settings', 'Settings', Icons.settings_outlined, AppRoutes.settings),
];"""
new_list = """List<_NavItem> _buildNavItems(String lang) => [
  _NavItem(
    'contracts',
    AppStrings.get(lang, 'nav_contracts'),
    Icons.description_outlined,
    AppRoutes.contracts,
  ),
  _NavItem(
    'notifications',
    AppStrings.get(lang, 'nav_notifications'),
    Icons.notifications_outlined,
    AppRoutes.notifications,
  ),
  _NavItem('documents', AppStrings.get(lang, 'nav_documents'), Icons.document_scanner, '/documents'),
  _NavItem('mycontracts', AppStrings.get(lang, 'nav_mycontracts'), Icons.assignment_turned_in, AppRoutes.myContracts),
  _NavItem('chat', AppStrings.get(lang, 'nav_chat'), Icons.smart_toy_outlined, AppRoutes.chat),
  _NavItem('settings', AppStrings.get(lang, 'nav_settings'), Icons.settings_outlined, AppRoutes.settings),
];"""
assert old_list in src, "liste marker introuvable"
src = src.replace(old_list, new_list, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("OK - menu de navigation traduit")
