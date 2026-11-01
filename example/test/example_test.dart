import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum_example/main.dart';

void main() {
  testWidgets('chrome, keys and content all render, and all switch together', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // Chrome from gen-l10n, a key resolved through the host extension, and
    // content carrying its own translations -- three paths, one locale.
    expect(find.text('Welcome'), findsWidgets);
    expect(find.text('3 items'), findsNWidgets(2));
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('A red apple'), findsOneWidget);

    await tester.tap(find.text('Switch language'));
    await tester.pumpAndSettle();

    expect(find.text('Vítejte'), findsWidgets);
    expect(find.text('3 položky'), findsNWidgets(2));
    expect(find.text('Jablko'), findsOneWidget);
    expect(find.text('Červené jablko'), findsOneWidget);
  });
}
