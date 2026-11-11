import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iot/main.dart';

void main() {
  testWidgets('App loads LoginScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify that the login elements exist
    expect(find.text('Hub Pintar'), findsOneWidget);
  });
}
