import 'package:flutter/widgets.dart';

import 'src/app.dart';

void main() => runApp(const HingeExampleApp());

@pragma('vm:entry-point')
void dualScreenSecondaryMain(List<String> arguments) {
  runApp(SecondaryDisplayApp(arguments: arguments));
}
