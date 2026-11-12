import 'package:flutter/material.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/widgets/app_surfaces.dart';

class BillPayScreen extends StatelessWidget {
  const BillPayScreen({super.key});

  static const List<({String name, IconData icon})> _bills =
      <({String name, IconData icon})>[
    (name: 'Electricity', icon: Icons.lightbulb_outline_rounded),
    (name: 'Cable TV', icon: Icons.tv_outlined),
    (name: 'Internet', icon: Icons.wifi_rounded),
    (name: 'Water', icon: Icons.water_drop_outlined),
    (name: 'School fees', icon: Icons.school_outlined),
    (name: 'Tax', icon: Icons.receipt_long_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      title: 'Pay bills',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Choose a biller'),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: _bills.length,
              itemBuilder: (context, index) {
                final bill = _bills[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${bill.name} — coming soon.')),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lilac,
                        ),
                        child: Icon(bill.icon,
                            color: AppColors.purple, size: 25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bill.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
