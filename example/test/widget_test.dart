import 'package:flutter_test/flutter_test.dart';

import 'package:linkzly_flutter_sdk_example/main.dart';

void main() {
  testWidgets('LinkzlyExampleApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LinkzlyExampleApp());
    await tester.pump();
    expect(find.text('Linkzly Flutter SDK'), findsWidgets);
  });
}
