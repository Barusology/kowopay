import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/formatters.dart';

class TransactionsTab extends ConsumerStatefulWidget {
  const TransactionsTab({super.key});

  @override
  ConsumerState<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<TransactionsTab> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final database = ref.watch(databaseServiceProvider);

    return SafeArea(
      bottom: false,
      child: StreamBuilder<DatabaseEvent>(
        stream: database.getTransactionsStream(user.uid),
        builder: (context, snapshot) {
          final List<Map<String, dynamic>> all = _parse(snapshot.data);
          final List<Map<String, dynamic>> visible = switch (_filter) {
            'Money in' => all.where((t) => t['isCredit'] == true).toList(),
            'Money out' => all.where((t) => t['isCredit'] != true).toList(),
            _ => all,
          };

          double totalIn = 0;
          double totalOut = 0;
          for (final Map<String, dynamic> item in all) {
            final double amount = (item['amount'] as num?)?.toDouble() ?? 0;
            if (item['isCredit'] == true) {
              totalIn += amount;
            } else {
              totalOut += amount;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Money in',
                        amount: totalIn,
                        icon: Icons.south_west_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Money out',
                        amount: totalOut,
                        icon: Icons.north_east_rounded,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final String option in const [
                      'All',
                      'Money in',
                      'Money out'
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option),
                          selected: _filter == option,
                          onSelected: (_) => setState(() => _filter = option),
                          showCheckmark: false,
                          selectedColor: AppColors.purple,
                          backgroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.outline),
                          labelStyle: TextStyle(
                            color: _filter == option
                                ? AppColors.white
                                : AppColors.inkMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : visible.isEmpty
                        ? _empty()
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(20, 10, 20, 132),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _TransactionCard(item: visible[index]),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 50),
        Icon(Icons.receipt_long_outlined,
            size: 72, color: AppColors.lilac),
        SizedBox(height: 18),
        Text(
          'No transactions yet',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'Deposits, withdrawals and payments will show up here in real time.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkMuted),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _parse(DatabaseEvent? event) {
    final Object? value = event?.snapshot.value;
    if (value is! Map) return <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> list = value.values
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList();
    list.sort((a, b) {
      final int ta = (a['timestamp'] as num?)?.toInt() ??
          parseTimestamp(a['date'])?.millisecondsSinceEpoch ??
          0;
      final int tb = (b['timestamp'] as num?)?.toInt() ??
          parseTimestamp(b['date'])?.millisecondsSinceEpoch ??
          0;
      return tb.compareTo(ta);
    });
    return list;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  formatNaira(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final bool isCredit = item['isCredit'] == true;
    final double amount = (item['amount'] as num?)?.toDouble() ?? 0;
    final String title = (item['title'] as String?) ?? 'Transaction';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isCredit ? AppColors.success : AppColors.purple)
                  .withValues(alpha: 0.10),
            ),
            child: Icon(
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: isCredit ? AppColors.success : AppColors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(item['timestamp'] ?? item['date'])} · '
                  '${formatTime(item['timestamp'] ?? item['date'])}',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${formatNaira(amount)}',
            style: TextStyle(
              color: isCredit ? AppColors.success : AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
