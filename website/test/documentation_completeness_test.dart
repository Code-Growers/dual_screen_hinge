import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('every documented guide exists and has front matter', () {
    const guides = <String>[
      'getting-started',
      'animation-recipes',
      'media-query',
      'android',
      'iphone-duo',
      'display-modes',
      'secondary-entrypoints',
      'testing',
      'troubleshooting',
      'migration',
      'device-matrix',
      'ai-agents',
    ];
    for (final guide in guides) {
      final file = File('content/guides/$guide.md');
      expect(file.existsSync(), isTrue, reason: guide);
      final text = file.readAsStringSync();
      expect(text.startsWith('---\n'), isTrue, reason: guide);
      expect(text, contains('title:'), reason: guide);
      expect(text, contains('description:'), reason: guide);
    }
  });

  test('AI discovery and brand assets are present', () {
    expect(File('web/llms.txt').existsSync(), isTrue);
    expect(File('web/favicon.png').existsSync(), isTrue);
    expect(File('web/assets/logo.png').existsSync(), isTrue);
  });

  test('iPhone Duo guide covers the reserved-region contract', () {
    final text = File('content/guides/iphone-duo.md').readAsStringSync();
    expect(text, contains('Reserved regions'));
    expect(text, contains('division'));
    expect(text, contains('occlusion'));
    expect(text, contains('MediaQuery.paddingOf'));
    expect(text, contains('Split View'));
    expect(text, contains('vertical-bar'));
  });
}
