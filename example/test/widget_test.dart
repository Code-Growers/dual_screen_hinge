import 'package:dual_screen_hinge_example/src/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard describes both layout APIs', (tester) async {
    await tester.pumpWidget(const HingeExampleApp());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Plugin vs MediaQuery'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Plugin vs MediaQuery'), findsOneWidget);
    expect(find.textContaining('MediaQuery.displayFeatures'), findsOneWidget);
  });
}
