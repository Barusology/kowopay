import 'package:flutter/material.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/widgets/app_surfaces.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

  static const List<({String title, IconData icon, String caption})> _plans =
      <({String title, IconData icon, String caption})>[
    (title: 'Life', icon: Icons.favorite_outline, caption: 'Family cover'),
    (
      title: 'Health',
      icon: Icons.health_and_safety_outlined,
      caption: 'Hospital bills'
    ),
    (
      title: 'Vehicle',
      icon: Icons.directions_car_outlined,
      caption: 'Comprehensive auto'
    ),
    (title: 'Home', icon: Icons.home_work_outlined, caption: 'Property cover'),
    (title: 'Travel', icon: Icons.flight_takeoff_outlined, caption: 'Trips'),
    (title: 'Education', icon: Icons.school_outlined, caption: 'School fees'),
  ];

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      title: 'Insurance',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.softGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      color: AppColors.purple, size: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Protect what matters with cover built for how you live.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${plan.title} cover — coming soon.'),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.buttonGradient,
                        ),
                        child: Icon(plan.icon,
                            color: AppColors.white, size: 25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${plan.title} insurance',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        plan.caption,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 10.5,
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
