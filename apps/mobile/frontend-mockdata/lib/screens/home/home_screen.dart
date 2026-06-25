import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deals_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final authProvider = Provider.of<AuthProvider>(context);
    final dealsProvider = Provider.of<DealsProvider>(context);

    final fullName = authProvider.userProfile['fullName'] ?? 'Hamza';

    // Stats calculations
    final int activeDeals = dealsProvider.deals.where((d) => d.status == 'negotiation' || d.status == 'draft').length;
    final int approvedContracts = dealsProvider.contracts.where((c) => c.status == 'approved').length;
    final int pendingApprovals = dealsProvider.contracts.where((c) => c.status == 'pending').length;
    const int receivedInvitations = 2; // Simulated

    final List<Map<String, dynamic>> stats = [
      {
        'label': 'Active Deals',
        'value': activeDeals.toString(),
        'icon': '📊',
        'colors': [const Color(0xFF00B4D8), const Color(0xFF02529C)]
      },
      {
        'label': 'Approved Contracts',
        'value': approvedContracts.toString(),
        'icon': '✅',
        'colors': [const Color(0xFF34D399), const Color(0xFF059669)]
      },
      {
        'label': 'Pending Approvals',
        'value': pendingApprovals.toString(),
        'icon': '⏳',
        'colors': [const Color(0xFFFBBF24), const Color(0xFFD97706)]
      },
      {
        'label': 'Received Invitations',
        'value': receivedInvitations.toString(),
        'icon': '📨',
        'colors': [const Color(0xFFC084FC), const Color(0xFF7C3AED)]
      },
    ];

    final List<Map<String, String>> recentActivity = [
      {
        'type': 'invitation',
        'title': 'New invitation received',
        'description': 'You received an invite to "Marketing Partnership" from John Smith',
        'time': '2 hours ago',
        'icon': '📨'
      },
      {
        'type': 'approved',
        'title': 'Contract approved',
        'description': '"Software Implementation" has been approved by all parties',
        'time': '5 hours ago',
        'icon': '✅'
      },
      {
        'type': 'version',
        'title': 'New contract version created',
        'description': 'Sarah created v2.0 of "Service Agreement"',
        'time': '1 day ago',
        'icon': '📝'
      },
      {
        'type': 'message',
        'title': 'New message received',
        'description': 'Ahmed commented on "Partnership Agreement"',
        'time': '2 days ago',
        'icon': '💬'
      },
    ];

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return ResponsiveScaffold(
      activeRoute: 'home',
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0B1220), const Color(0xFF121C2F)]
                  : [const Color(0xFFF3F7FA), const Color(0xFFD6E2EE)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                Text(
                  'Welcome back, $fullName!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's what's happening with your deals today.",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 28),

                // Stats Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : (size.width > 550 ? 2 : 1),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, idx) {
                    final item = stats[idx];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: item['colors'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item['icon'] as String,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item['value'] as String,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/create'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Create Deal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Start a new deal agreement',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.87),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/deals'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.business_center, color: theme.primaryColor, size: 28),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'View Deals',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'See all your active deals',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: theme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Icon Grid Buttons
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildIconActionButton(
                      context: context,
                      label: 'Notifications',
                      icon: Icons.notifications,
                      onTap: () => context.go('/notifications'),
                    ),
                    _buildIconActionButton(
                      context: context,
                      label: 'Profile',
                      icon: Icons.person,
                      onTap: () => context.go('/profile'),
                    ),
                    _buildIconActionButton(
                      context: context,
                      label: 'Messages',
                      icon: Icons.forum,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Messages feature is coming soon!')),
                        );
                      },
                    ),
                    _buildIconActionButton(
                      context: context,
                      label: 'Settings',
                      icon: Icons.settings,
                      onTap: () => context.go('/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Recent Activity Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.go('/notifications'),
                      child: Row(
                        children: [
                          Text('View All', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                          Icon(Icons.chevron_right, color: theme.primaryColor, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Activity List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentActivity.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item = recentActivity[idx];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['icon']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['description']!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['time']!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
