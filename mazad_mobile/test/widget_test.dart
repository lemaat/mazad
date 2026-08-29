import 'package:flutter_test/flutter_test.dart';
import 'package:mazad_mobile/core/app.dart';

void main() {
  testWidgets('MazadApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MazadApp());
    expect(find.byType(MazadApp), findsOneWidget);
  });
}
