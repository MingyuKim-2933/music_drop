import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'package:muse/main.dart';
import 'package:muse/src/config/supabase_config.dart';

/// 남은 지연 Future를 흘려보내고 트리를 해제해서
/// Provider들이 dispose되도록 한다 (주기 타이머 정리).
Future<void> tearDownTree(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('미로그인 상태에서는 로그인 화면을 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(const MuseApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
    expect(find.text('이메일로 시작하기'), findsOneWidget);

    await tearDownTree(tester);
  });

  testWidgets('로그인된 세션이 있으면 홈 화면을 보여준다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_session':
          '{"id":"email:test@test.com","nickname":"테스터","provider":"email",'
              '"email":"test@test.com","profileImageUrl":null}',
    });

    await tester.pumpWidget(const MuseApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('MUSE 🎧'), findsOneWidget);
    expect(find.text('친구들'), findsOneWidget);

    await tearDownTree(tester);
  });
}
