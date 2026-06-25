import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/ideal_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotificationItem> _items = [
    _NotificationItem(
      title: 'New invitation received',
      message: 'You have been invited to "Marketing Partnership" deal',
      time: '2 hours ago',
      icon: '📨',
    ),
    _NotificationItem(
      title: 'Contract approved',
      message: '"Software Implementation" has been approved by Ahmed Hassan',
      time: '5 hours ago',
      icon: '✅',
    ),
    _NotificationItem(
      title: 'Deal updated',
      message: 'Sarah created a new version of "Service Agreement"',
      time: '1 day ago',
      icon: '📝',
      read: true,
    ),
    _NotificationItem(
      title: 'New message',
      message: 'Ahmed commented: "Can we discuss the timeline?"',
      time: '2 days ago',
      icon: '💬',
      read: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((item) => !item.read).toList();
    final earlier = _items.where((item) => item.read).toList();

    return IdealAppScaffold(
      activeRoute: 'notifications',
      body: _MockupPage(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PageTitle('Notifications'),
                    const SizedBox(height: 4),
                    Text(
                      'You have ${unread.length} unread notifications',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (final item in _items) {
                        item.read = true;
                      }
                    });
                  },
                  child: const Text('Mark all as read'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (unread.isNotEmpty) ...[
              const _SectionLabel('UNREAD'),
              const SizedBox(height: 10),
              for (final item in unread) ...[
                _NotificationCard(
                  item: item,
                  highlighted: true,
                  onRead: () => setState(() => item.read = true),
                  onDelete: () => setState(() => _items.remove(item)),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 18),
            ],
            if (earlier.isNotEmpty) ...[
              const _SectionLabel('EARLIER'),
              const SizedBox(height: 10),
              for (final item in earlier) ...[
                _NotificationCard(
                  item: item,
                  onDelete: () => setState(() => _items.remove(item)),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  final bool highlighted;
  final VoidCallback? onRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.item,
    required this.onDelete,
    this.highlighted = false,
    this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: highlighted ? 1 : 0.72,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onRead != null)
              IconButton(
                onPressed: onRead,
                icon: const Icon(Icons.check_circle_outline),
                color: AppColors.primary,
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String message;
  final String time;
  final String icon;
  bool read;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    this.read = false,
  });
}

class _MockupPage extends StatelessWidget {
  final Widget child;

  const _MockupPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceAlt],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String text;

  const _PageTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}
