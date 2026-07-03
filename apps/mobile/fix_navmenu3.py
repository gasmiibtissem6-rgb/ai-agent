path = "lib/shared/ideal_ui.dart"
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

# 1. Transformer IdealAppScaffold en ConsumerWidget
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

# 2. Remplacer la liste statique _navItems par une fonction traduite
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
