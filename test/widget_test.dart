import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iot/main.dart';

void main() {
  testWidgets('App loads LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SiagaIrigasiApp());
    await tester.pump();

    expect(find.text('SIAGA IRIGASI'), findsOneWidget);
    expect(find.text('Portal Petugas Lapang'), findsOneWidget);
  });
}
