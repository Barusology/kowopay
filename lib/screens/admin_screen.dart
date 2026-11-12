import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/formatters.dart';
import 'package:kowopay/widgets/app_surfaces.dart';

/// Admin surface. Two independent guards protect it:
///   1. This screen checks the force-refreshed `admin` custom claim.
///   2. Firebase Rules reject user reads to other users' data without the
///      same claim, so bypassing the UI still returns permission-denied.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Map<String, dynamic>> users =
          await ref.read(databaseServiceProvider).getAllUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not load users. Permission may have been revoked.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    final AsyncValue<bool> admin = ref.watch(adminRoleProvider);

    return CinematicScaffold(
      title: 'Admin console',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: admin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _denied('The admin check failed. Try again.'),
        data: (bool isAdmin) {
          if (!isAdmin || user == null) {
            return _denied('This area is restricted to administrators.');
          }
          if (_loading && _users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return _denied(_error!);
          }

          final double totalBalance = _users.fold<double>(
            0,
            (sum, item) => sum + ((item['balance'] as num?)?.toDouble() ?? 0),
          );

          return ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Users',
                      value: '${_users.length}',
                      icon: Icons.people_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      label: 'Wallet float',
                      value: formatNaira(totalBalance, withDecimals: false),
                      icon: Icons.savings_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionTitle('Accounts'),
              const SizedBox(height: 12),
              if (_users.isEmpty)
                const GlassCard(
                  child: Text(
                    'No user profiles found yet.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                )
              else
                for (final Map<String, dynamic> item in _users)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 21,
                            backgroundColor: AppColors.lilac,
                            child: Text(
                              _initial(item),
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item['name'] as String?) ?? 'Unnamed',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                                Text(
                                  (item['email'] as String?) ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatNaira(
                                  (item['balance'] as num?)?.toDouble() ?? 0,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                formatDate(item['createdAt']),
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  String _initial(Map<String, dynamic> item) {
    final String name = (item['name'] as String?) ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _denied(String message) {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 44, color: AppColors.purple),
            const SizedBox(height: 14),
            const Text(
              'Access denied',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.purple, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
