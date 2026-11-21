import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/app.dart';

void main() {
  testWidgets('SmartNote app renders its title', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartNoteApp());

    expect(find.text('SmartNote'), findsOneWidget);
  });
}
