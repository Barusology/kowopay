import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/formatters.dart';
import 'package:kowopay/utils/secure_logger.dart';

class NotificationsTab extends ConsumerWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final database = ref.watch(databaseServiceProvider);

    return SafeArea(
      bottom: false,
      child: StreamBuilder<DatabaseEvent>(
        stream: database.getNotificationsStream(user.uid),
        builder: (context, snapshot) {
          final List<_NotificationItem> items = _parse(snapshot.data);
          final int unread = items.where((item) => !item.read).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      TextButton(
                        onPressed: () => _markAllRead(ref, user.uid, items),
                        child: const Text('Mark all read'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 132),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _NotificationCard(
                              item: items[index],
                              onTap: () => _open(ref, user.uid, items[index]),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 60),
        Icon(Icons.notifications_none_rounded,
            size: 72, color: AppColors.lilac),
        SizedBox(height: 18),
        Text(
          'You are all caught up',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'Payment confirmations, loan updates and security alerts will land '
          'here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkMuted),
        ),
      ],
    );
  }

  Future<void> _markAllRead(
    WidgetRef ref,
    String uid,
    List<_NotificationItem> items,
  ) async {
    final database = ref.read(databaseServiceProvider);
    for (final _NotificationItem item in items.where((i) => !i.read)) {
      try {
        await database.markNotificationRead(uid, item.id);
      } catch (e) {
        SecureLog.error('Mark notification read', e);
      }
    }
  }

  Future<void> _open(
    WidgetRef ref,
    String uid,
    _NotificationItem item,
  ) async {
    if (!item.read) {
      try {
        await ref
            .read(databaseServiceProvider)
            .markNotificationRead(uid, item.id);
      } catch (e) {
        SecureLog.error('Mark notification read', e);
      }
    }
  }

  List<_NotificationItem> _parse(DatabaseEvent? event) {
    final Object? value = event?.snapshot.value;
    if (value is! Map) return <_NotificationItem>[];
    final List<_NotificationItem> items = <_NotificationItem>[];
    value.forEach((Object? key, Object? data) {
      if (data is Map) {
        items.add(_NotificationItem(
          id: key.toString(),
          title: (data['title'] as String?) ?? 'Notification',
          body: (data['body'] as String?) ?? '',
          type: (data['type'] as String?) ?? 'system',
          read: data['read'] == true,
          timestamp: data['timestamp'] ?? data['createdAt'],
        ));
      }
    });
    items.sort((a, b) {
      final DateTime? ta = parseTimestamp(a.timestamp);
      final DateTime? tb = parseTimestamp(b.timestamp);
      if (ta == null || tb == null) return 0;
      return tb.compareTo(ta);
    });
    return items;
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final Object? timestamp;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (item.type) {
      'payment' => (Icons.payments_outlined, AppColors.success),
      'loan' => (Icons.account_balance_wallet_outlined, AppColors.purple),
      'security' => (Icons.shield_outlined, AppColors.danger),
      _ => (Icons.notifications_none_rounded, AppColors.violet),
    };

    return Material(
      color: item.read
          ? AppColors.white.withValues(alpha: 0.72)
          : AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.read ? AppColors.outline : AppColors.lilac,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.read
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!item.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.violet,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${formatDate(item.timestamp)} · ${formatTime(item.timestamp)}',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10.5,
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
