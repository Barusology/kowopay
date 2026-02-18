import 'package:flutter/material.dart';

class BillPayScreen extends StatelessWidget {
  const BillPayScreen({super.key});

  final List<Map<String, dynamic>> _bills = const [
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
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bill Payment Integration Coming Soon')),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(bill['icon'] as IconData, size: 48, color: Colors.deepPurple),
                  const SizedBox(height: 12),
                  Text(bill['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
