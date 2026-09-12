import 'dart:ui';

import 'package:dual_screen_hinge/dual_screen_hinge.dart';
import 'package:flutter/material.dart';

import 'fold_visualizer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DualScreenCapabilities _capabilities = const DualScreenCapabilities();
  String? _message;

  @override
  void initState() {
    super.initState();
    _refreshCapabilities();
  }

  Future<void> _refreshCapabilities() async {
    final capabilities = await DualScreenHinge.instance.capabilities();
    if (mounted) setState(() => _capabilities = capabilities);
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
      if (mounted) setState(() => _message = null);
    } on DualScreenException catch (error) {
      if (mounted) setState(() => _message = '${error.code}: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('dual_screen_hinge'),
      actions: [
        IconButton(
          tooltip: 'Refresh capabilities',
          onPressed: _refreshCapabilities,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: StreamBuilder<DualScreenState>(
      stream: DualScreenHinge.instance.events,
      initialData: const DualScreenState(),
      builder: (context, snapshot) {
        final state = snapshot.data ?? const DualScreenState();
        final mediaFeatures = MediaQuery.displayFeaturesOf(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FoldVisualizer(
              angle: state.hingeAngle ?? _fallbackAngle(state.posture),
            ),
            const SizedBox(height: 16),
            ReservedRegionVisualizer(
              regions: state.reservedRegions,
              viewportSize: MediaQuery.sizeOf(context),
            ),
            const SizedBox(height: 12),
            _ReservedRegionCard(regions: state.reservedRegions),
            const SizedBox(height: 12),
            _StateCard(state: state),
            const SizedBox(height: 12),
            _CapabilitiesCard(capabilities: _capabilities),
            const SizedBox(height: 12),
            _FeatureCard(
              pluginFeatures: state.displayFeatures,
              mediaFeatures: mediaFeatures,
            ),
            const SizedBox(height: 12),
            _ControlCard(
              state: state,
              capabilities: _capabilities,
              onStartRear: () =>
                  _run(DualScreenHinge.instance.startRearDisplay),
              onStopRear: () => _run(DualScreenHinge.instance.stopRearDisplay),
              onStartDual: () => _run(
                () => DualScreenHinge.instance.startDualScreen(
                  arguments: const <String>['Hello from the primary display'],
                ),
              ),
              onStopDual: () => _run(DualScreenHinge.instance.stopDualScreen),
            ),
            if (_message case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        );
      },
    ),
  );
}

double _fallbackAngle(HingePosture posture) => switch (posture) {
  HingePosture.closed => 0,
  HingePosture.halfOpened || HingePosture.tent => 95,
  HingePosture.flat => 180,
  HingePosture.unknown => 145,
};

class _StateCard extends StatelessWidget {
  const _StateCard({required this.state});

  final DualScreenState state;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Live state',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip('posture', state.posture.name),
        _Chip('source', state.postureSource),
        _Chip('screen', state.activeScreen.name),
        _Chip('inner', '${state.isInnerScreen ?? 'unknown'}'),
        _Chip('features', '${state.displayFeatures.length}'),
        _Chip('regions', '${state.reservedRegions.length}'),
      ],
    ),
  );
}

class _CapabilitiesCard extends StatelessWidget {
  const _CapabilitiesCard({required this.capabilities});

  final DualScreenCapabilities capabilities;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Runtime capabilities',
    child: Column(
      children:
          {
                'Hinge angle': capabilities.hingeAngleSensor,
                'Layout features': capabilities.layoutFeatures,
                'Reserved regions': capabilities.reservedRegionGeometry,
                'Rear display': capabilities.rearDisplay,
                'Dual-screen presentation': capabilities.dualScreenPresentation,
              }.entries
              .map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  trailing: Icon(
                    entry.value
                        ? Icons.check_circle
                        : Icons.remove_circle_outline,
                  ),
                ),
              )
              .toList(),
    ),
  );
}

class _ReservedRegionCard extends StatelessWidget {
  const _ReservedRegionCard({required this.regions});

  final List<ReservedRegion> regions;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Reserved-region diagnostics',
    child: regions.isEmpty
        ? const Text(
            'Requires iPhone Duo support compiled with the iOS 27.1 SDK.',
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final region in regions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${region.kind.name} · '
                    '${region.isActive ? 'active' : 'inactive'} · '
                    '${region.bounds}',
                  ),
                ),
            ],
          ),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.pluginFeatures,
    required this.mediaFeatures,
  });

  final List<FoldFeature> pluginFeatures;
  final List<DisplayFeature> mediaFeatures;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Plugin vs MediaQuery',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dual_screen_hinge: ${pluginFeatures.length} feature(s), including metadata and angles.',
        ),
        const SizedBox(height: 6),
        Text(
          'MediaQuery.displayFeatures: ${mediaFeatures.length} feature(s) for adaptive Android layout.',
        ),
        if (pluginFeatures.isNotEmpty) ...[
          const Divider(),
          for (final feature in pluginFeatures)
            Text(
              '${feature.type.name} · ${feature.orientation.name} · ${feature.bounds}',
            ),
        ],
      ],
    ),
  );
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.state,
    required this.capabilities,
    required this.onStartRear,
    required this.onStopRear,
    required this.onStartDual,
    required this.onStopDual,
  });

  final DualScreenState state;
  final DualScreenCapabilities capabilities;
  final VoidCallback onStartRear;
  final VoidCallback onStopRear;
  final VoidCallback onStartDual;
  final VoidCallback onStopDual;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Android display modes',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonal(
          onPressed: capabilities.rearDisplay ? onStartRear : null,
          child: const Text('Start rear display'),
        ),
        OutlinedButton(
          onPressed: onStopRear,
          child: const Text('Stop rear display'),
        ),
        FilledButton.tonal(
          onPressed: capabilities.dualScreenPresentation ? onStartDual : null,
          child: const Text('Start dual screen'),
        ),
        OutlinedButton(
          onPressed: onStopDual,
          child: const Text('Stop dual screen'),
        ),
        Text(
          'Rear: ${state.rearDisplay.state.name} · Dual: ${state.dualScreen.state.name}',
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Chip(label: Text('$label · $value'));
}
