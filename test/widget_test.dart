import 'package:flutter_test/flutter_test.dart';

import 'package:soundmate/main.dart';

void main() {
  testWidgets('앱이 홈 화면을 렌더링한다', (WidgetTester tester) async {
    await tester.pumpWidget(const SoundmateApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('듣는중 🎧'), findsOneWidget);
    expect(find.text('친구들'), findsOneWidget);
  });
}
