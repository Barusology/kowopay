import 'package:flutter/material.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _InsuranceCard(
            title: 'Life Insurance',
            icon: Icons.favorite,
            color: Colors.redAccent,
            onTap: () {},
          ),
          _InsuranceCard(
            title: 'Health Insurance',
            icon: Icons.health_and_safety,
            color: Colors.green,
            onTap: () {},
          ),
          _InsuranceCard(
            title: 'Vehicle Insurance',
            icon: Icons.directions_car,
            color: Colors.blue,
            onTap: () {},
          ),
          _InsuranceCard(
            title: 'Home Insurance',
            icon: Icons.home_work,
            color: Colors.orange,
            onTap: () {},
          ),
          _InsuranceCard(
            title: 'Travel Insurance',
            icon: Icons.flight,
            color: Colors.purple,
            onTap: () {},
          ),
          _InsuranceCard(
            title: 'Education Insurance',
            icon: Icons.school,
            color: Colors.teal,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _InsuranceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
