import 'package:flutter/material.dart';

import 'dashboard_page.dart';

class HingeExampleApp extends StatelessWidget {
  const HingeExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'dual_screen_hinge',
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.system,
    theme: hingeTheme(Brightness.light),
    darkTheme: hingeTheme(Brightness.dark),
    home: const DashboardPage(),
  );
}

ThemeData hingeTheme(Brightness brightness) => ThemeData(
  brightness: brightness,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xff00a9a5),
    brightness: brightness,
  ),
  cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  useMaterial3: true,
);

class SecondaryDisplayApp extends StatelessWidget {
  const SecondaryDisplayApp({required this.arguments, super.key});

  final List<String> arguments;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: hingeTheme(Brightness.dark),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cast_connected_rounded, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Secondary Flutter engine',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(arguments.join('\n'), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
}
