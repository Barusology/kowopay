import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kowopay/theme/app_theme.dart';

/// Slow-drifting purple aurora painted behind every screen.
///
/// Kept to gradients only (no blur filters) so it stays smooth on low-end
/// Android devices and on Flutter web.
class CinematicBackground extends StatefulWidget {
  const CinematicBackground({
    super.key,
    required this.child,
    this.intense = false,
  });

  final Widget child;
  final bool intense;

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double strength = widget.intense ? 1.0 : 0.55;
    return ColoredBox(
      color: AppColors.white,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: AppColors.softGradient),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final double t = _controller.value * 2 * math.pi;
                  return Stack(
                    children: [
                      _blob(
                        alignment: Alignment(
                          math.cos(t) * 0.55,
                          -0.85 + math.sin(t) * 0.08,
                        ),
                        size: 420,
                        color: AppColors.purple.withValues(
                          alpha: 0.20 * strength,
                        ),
                      ),
                      _blob(
                        alignment: Alignment(
                          -0.9 + math.sin(t) * 0.10,
                          0.55 + math.cos(t) * 0.06,
                        ),
                        size: 360,
                        color: AppColors.violet.withValues(
                          alpha: 0.16 * strength,
                        ),
                      ),
                      _blob(
                        alignment: Alignment(
                          0.95 - math.cos(t) * 0.07,
                          0.95 + math.sin(t) * 0.05,
                        ),
                        size: 300,
                        color: AppColors.lilac.withValues(
                          alpha: 0.75 * strength,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }

  Widget _blob({
    required Alignment alignment,
    required double size,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
