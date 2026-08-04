import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase;

import 'src/config/app_keys.dart';
import 'src/config/supabase_config.dart';
import 'src/repositories/friends_repository.dart';
import 'src/repositories/playlist_repository.dart';
import 'src/repositories/routed_playlist_repository.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/main_shell.dart';
import 'src/services/auth_service.dart';
import 'src/services/now_playing_service.dart';
import 'src/services/spotify_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: AppKeys.kakaoNativeAppKey);
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }
  runApp(const MuseApp());
}

class MuseApp extends StatelessWidget {
  const MuseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SpotifyAuth>(create: (_) => SpotifyAuth()),
        Provider<FriendsRepository>(create: (_) => MockFriendsRepository()),
        Provider<PlaylistRepository>(
            create: (_) => RoutedPlaylistRepository()),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService()..restoreSession(),
        ),
        ChangeNotifierProvider<NowPlayingService>(
          create: (ctx) => NowPlayingService(ctx.read<SpotifyAuth>())..start(),
        ),
      ],
      child: MaterialApp(
        title: 'MUSE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C4DFF),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0E0B16),
          fontFamily: 'Pretendard',
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// 로그인 상태에 따라 로그인 화면 ↔ 홈 화면 전환
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return auth.isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
