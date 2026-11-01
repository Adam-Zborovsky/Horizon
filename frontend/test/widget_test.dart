import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horizon/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: HorizonApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the title is present.
    expect(find.text('HORIZON'), findsOneWidget);
  });
}
