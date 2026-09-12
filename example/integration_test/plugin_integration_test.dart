import 'package:dual_screen_hinge/dual_screen_hinge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ordinary devices return a safe snapshot', (tester) async {
    final state = await DualScreenHinge.instance.currentState();
    final capabilities = await DualScreenHinge.instance.capabilities();
    expect(state.schemaVersion, 1);
    expect(capabilities.platformSupported, isA<bool>());
  });
}
