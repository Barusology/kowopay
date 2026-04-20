import 'package:flutter/material.dart';

class BillPayScreen extends StatelessWidget {
  const BillPayScreen({super.key});

  // FIX: static const — previously declared as a final instance field on a
  // StatelessWidget, meaning the list was reconstructed on every rebuild.
  static const List<Map<String, dynamic>> _bills = [
    {'name': 'Electricity', 'icon': Icons.lightbulb},
    {'name': 'Cable TV', 'icon': Icons.tv},
    {'name': 'Internet', 'icon': Icons.wifi},
    {'name': 'Water', 'icon': Icons.water_drop},
    {'name': 'School Fees', 'icon': Icons.school},
    {'name': 'Tax', 'icon': Icons.receipt_long},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Bills'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _bills.length,
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // TODO: navigate to a bill-specific payment form.
                // Each bill type needs its own account-number field and
                // amount entry — replace this SnackBar when implemented.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${bill['name']} payment — coming soon'),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    bill['icon'] as IconData,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bill['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
