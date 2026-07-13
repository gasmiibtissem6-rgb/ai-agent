import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/notification_service.dart';
import '../../../shared/ideal_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await NotificationService.list();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationService.markAllRead();
    } catch (_) {}
    await _load();
  }

  Future<void> _markRead(AppNotification item) async {
    try {
      await NotificationService.markRead(item.id);
    } catch (_) {}
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((item) => !item.isRead).toList();
    final earlier = _items.where((item) => item.isRead).toList();

    return IdealAppScaffold(
      activeRoute: 'notifications',
      body: IdealGradientBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                        if (unread.isNotEmpty)
                          TextButton(
                            onPressed: _markAllRead,
                            child: const Text('Mark all as read'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (_error != null)
                      _ErrorNote(error: _error!, onRetry: _load)
                    else if (_items.isEmpty)
                      _EmptyNote()
                    else ...[
                      if (unread.isNotEmpty) ...[
                        const _SectionLabel('UNREAD'),
                        const SizedBox(height: 10),
                        for (final item in unread) ...[
                          _NotificationCard(
                            item: item,
                            highlighted: true,
                            onRead: () => _markRead(item),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 18),
                      ],
                      if (earlier.isNotEmpty) ...[
                        const _SectionLabel('EARLIER'),
                        const SizedBox(height: 10),
                        for (final item in earlier) ...[
                          _NotificationCard(item: item),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final bool highlighted;
  final VoidCallback? onRead;

  const _NotificationCard({
    required this.item,
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
            Text(item.emoji, style: const TextStyle(fontSize: 24)),
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
                  if (item.body != null && item.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.body!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime(item.createdAt),
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
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}

class _EmptyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorNote({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Text(
            'Could not load notifications.\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
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
