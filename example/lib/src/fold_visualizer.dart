import 'dart:math' as math;

import 'package:flutter/material.dart';

class FoldVisualizer extends StatelessWidget {
  const FoldVisualizer({required this.angle, super.key});

  final double angle;

  @override
  Widget build(BuildContext context) {
    final normalized = angle.clamp(0, 180).toDouble();
    final rotation = (180 - normalized) * math.pi / 360;
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Hinge angle ${normalized.toStringAsFixed(1)} degrees',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        colors.primary.withValues(alpha: .22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform(
                    alignment: Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .0018)
                      ..rotateY(rotation),
                    child: _Panel(
                      color: colors.primaryContainer,
                      icon: Icons.animation_rounded,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 158,
                    decoration: BoxDecoration(
                      color: colors.tertiary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: colors.tertiary, blurRadius: 18),
                      ],
                    ),
                  ),
                  Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .0018)
                      ..rotateY(-rotation),
                    child: _Panel(
                      color: colors.secondaryContainer,
                      icon: Icons.data_object_rounded,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 14,
                child: Text(
                  '${normalized.toStringAsFixed(1)}°',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 118,
    height: 158,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Icon(icon, size: 42),
  );
}
