import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isoko_scooter/main.dart';

void main() {
  testWidgets('shows the sign in screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IsokoApp()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sign in Now'), findsOneWidget);
    expect(find.text('Continue'), findsWidgets);
  });
}
