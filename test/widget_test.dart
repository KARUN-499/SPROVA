import 'package:flutter_test/flutter_test.dart';
import 'package:sprova/main.dart';

void main() {
  testWidgets('Sprova app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SprovaApp());
    expect(find.text('SPROVA'), findsOneWidget);
  });
}