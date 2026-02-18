import 'package:flutter/material.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data for now
    final transactions = List.generate(10, (index) => {
      'title': index % 2 == 0 ? 'Deposit' : 'Withdrawal',
      'amount': index % 2 == 0 ? '+ ₦5,000' : '- ₦2,000',
      'date': 'Oct ${index + 1}, 2024',
      'isCredit': index % 2 == 0,
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isCredit = tx['isCredit'] as bool;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            title: Text(tx['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(tx['date'] as String),
            trailing: Text(
              tx['amount'] as String,
              style: TextStyle(
                color: isCredit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
