import 'dart:math' as math;

import 'package:dual_screen_hinge/dual_screen_hinge.dart';
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

class ReservedRegionVisualizer extends StatelessWidget {
  const ReservedRegionVisualizer({
    required this.regions,
    required this.viewportSize,
    super.key,
  });

  final List<ReservedRegion> regions;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '${regions.length} iPhone Duo reserved regions',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'iPhone Duo reserved regions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                regions.isEmpty
                    ? 'No regions reported on this display.'
                    : 'Purple divides content · orange occludes content',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 240,
                child: CustomPaint(
                  painter: _ReservedRegionPainter(
                    regions: regions,
                    viewportSize: viewportSize,
                    outline: colors.outlineVariant,
                    division: colors.primary,
                    occlusion: colors.tertiary,
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

class _ReservedRegionPainter extends CustomPainter {
  const _ReservedRegionPainter({
    required this.regions,
    required this.viewportSize,
    required this.outline,
    required this.division,
    required this.occlusion,
  });

  final List<ReservedRegion> regions;
  final Size viewportSize;
  final Color outline;
  final Color division;
  final Color occlusion;

  @override
  void paint(Canvas canvas, Size size) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;
    final scale = math.min(
      size.width / viewportSize.width,
      size.height / viewportSize.height,
    );
    final scaledSize = Size(
      viewportSize.width * scale,
      viewportSize.height * scale,
    );
    final offset = Offset(
      (size.width - scaledSize.width) / 2,
      (size.height - scaledSize.height) / 2,
    );
    final screen = offset & scaledSize;
    canvas.drawRRect(
      RRect.fromRectAndRadius(screen.deflate(1), const Radius.circular(18)),
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final region in regions) {
      final color = switch (region.kind) {
        ReservedRegionKind.division => division,
        ReservedRegionKind.occlusion => occlusion,
        ReservedRegionKind.unknown => outline,
      };
      final bounds = Rect.fromLTRB(
        offset.dx + region.bounds.left * scale,
        offset.dy + region.bounds.top * scale,
        offset.dx + region.bounds.right * scale,
        offset.dy + region.bounds.bottom * scale,
      );
      final visibleBounds = bounds.width == 0
          ? Rect.fromCenter(
              center: bounds.center,
              width: 2,
              height: bounds.height,
            )
          : bounds;
      canvas.drawRect(
        visibleBounds,
        Paint()
          ..color = region.isActive
              ? color.withValues(alpha: .58)
              : color.withValues(alpha: .16)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        visibleBounds,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = region.isActive ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(_ReservedRegionPainter oldDelegate) =>
      oldDelegate.regions != regions ||
      oldDelegate.viewportSize != viewportSize ||
      oldDelegate.outline != outline ||
      oldDelegate.division != division ||
      oldDelegate.occlusion != occlusion;
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
