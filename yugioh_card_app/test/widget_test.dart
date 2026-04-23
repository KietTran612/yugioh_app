import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yugioh_card_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: YugiohApp()));

    // App bar title should be present
    expect(find.text('Yu-Gi-Oh! Cards'), findsOneWidget);
  });
}
