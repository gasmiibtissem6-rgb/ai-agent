import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/deals_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class DealDetailsScreen extends StatefulWidget {
  final String dealId;
  const DealDetailsScreen({super.key, required this.dealId});

  @override
  State<DealDetailsScreen> createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends State<DealDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _commentController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  String _inviteRole = 'Partner';

  final List<String> _roles = ['Owner', 'Partner', 'Investor', 'Supplier', 'Client'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'negotiation':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'archived':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _postComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final dealsProvider = Provider.of<DealsProvider>(context, listen: false);
    dealsProvider.addComment(widget.dealId, 'Hamza', text);
    
    _commentController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment posted!')),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Invite Participant'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _inviteEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'partner@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _inviteRole,
                    items: _roles.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _inviteRole = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _inviteEmailController.clear();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final email = _inviteEmailController.text.trim();
                    if (email.isNotEmpty && email.contains('@')) {
                      final dealsProvider = Provider.of<DealsProvider>(ctx, listen: false);
                      dealsProvider.inviteParticipant(widget.dealId, email, _inviteRole);
                      
                      Navigator.of(ctx).pop();
                      _inviteEmailController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invitation sent to $email!')),
                      );
                    }
                  },
                  child: const Text('Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final dealsProvider = Provider.of<DealsProvider>(context);
    
    // Find deal
    final dealIndex = dealsProvider.deals.indexWhere((d) => d.id == widget.dealId);
    if (dealIndex == -1) {
      return ResponsiveScaffold(
        activeRoute: 'deals',
        body: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Deal not found', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/deals'),
                  child: const Text('Back to Deals'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final deal = dealsProvider.deals[dealIndex];
    final statusColor = _getStatusColor(deal.status);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final infoItems = [
      {'title': 'Amount', 'value': deal.amount, 'isPrimary': true},
      {'title': 'Created', 'value': deal.date, 'isPrimary': false},
      {'title': 'Expires', 'value': deal.expirationDate, 'isPrimary': false},
      {'title': 'Participants', 'value': deal.participants.length.toString(), 'isPrimary': false},
    ];

    return ResponsiveScaffold(
      activeRoute: 'deals',
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.go('/deals'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                deal.status[0].toUpperCase() + deal.status.substring(1),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              deal.category,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link shared to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Cards Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: infoItems.length,
                itemBuilder: (context, idx) {
                  final card = infoItems[idx];
                  final isPrimary = card['isPrimary'] as bool;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (card['title'] as String).toUpperCase(),
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['value'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPrimary ? theme.primaryColor : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // TabBar and View Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      labelColor: theme.primaryColor,
                      unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                      indicatorColor: theme.primaryColor,
                      indicatorSize: TabBarIndicatorSize.tab,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Participants'),
                        Tab(text: 'Versions'),
                        Tab(text: 'Activity'),
                        Tab(text: 'Comments'),
                      ],
                    ),
                    const Divider(height: 1),
                    
                    // Tab View Contents
                    Container(
                      padding: const EdgeInsets.all(24),
                      height: 400,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Overview Tab
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(
                                deal.description.isNotEmpty ? deal.description : 'No description provided.',
                                style: const TextStyle(height: 1.5, fontSize: 14),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () => _showInviteDialog(context),
                                icon: const Icon(Icons.people_outline),
                                label: const Text('Invite Participants'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          
                          // Participants Tab
                          ListView.separated(
                            itemCount: deal.participants.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final p = deal.participants[idx];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(p.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(p.role, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                                        const SizedBox(height: 2),
                                        Text(
                                          p.status,
                                          style: TextStyle(
                                            color: p.status == 'active' ? Colors.green : Colors.grey,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          // Versions Tab
                          deal.versions.isNotEmpty
                              ? ListView.separated(
                                  itemCount: deal.versions.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, idx) {
                                    final v = deal.versions[idx];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.description, color: theme.primaryColor, size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Version ${v.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 2),
                                                Text(v.changes, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                const SizedBox(height: 2),
                                                Text('By ${v.creator} on ${v.date}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : const Center(child: Text('No versions created yet.', style: TextStyle(color: Colors.grey))),
                              
                          // Activity Tab
                          deal.activity.isNotEmpty
                              ? ListView.separated(
                                  itemCount: deal.activity.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, idx) {
                                    final a = deal.activity[idx];
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                                          child: Text(
                                            a.author.isNotEmpty ? a.author[0].toUpperCase() : 'U',
                                            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(a.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 2),
                                              Text(a.message, style: const TextStyle(fontSize: 13, height: 1.3)),
                                              const SizedBox(height: 4),
                                              Text(a.time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : const Center(child: Text('No activity yet.', style: TextStyle(color: Colors.grey))),
                              
                          // Comments Tab
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a comment...',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _postComment,
                                    icon: const Icon(Icons.send),
                                    color: theme.primaryColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: deal.activity.where((a) => a.type == 'comment').length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, idx) {
                                    final comments = deal.activity.where((a) => a.type == 'comment').toList();
                                    final c = comments[idx];
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                                          child: Text(
                                            c.author[0].toUpperCase(),
                                            style: TextStyle(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              const SizedBox(height: 2),
                                              Text(c.message, style: const TextStyle(fontSize: 12)),
                                              const SizedBox(height: 4),
                                              Text(c.time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
