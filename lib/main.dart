import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/repositories/friends_repository.dart';
import 'src/screens/home_screen.dart';
import 'src/services/now_playing_service.dart';
import 'src/services/spotify_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SoundmateApp());
}

class SoundmateApp extends StatelessWidget {
  const SoundmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SpotifyAuth>(create: (_) => SpotifyAuth()),
        Provider<FriendsRepository>(create: (_) => MockFriendsRepository()),
        ChangeNotifierProvider<NowPlayingService>(
          create: (ctx) => NowPlayingService(ctx.read<SpotifyAuth>())..start(),
        ),
      ],
      child: MaterialApp(
        title: '듣는중',
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
        home: const HomeScreen(),
      ),
    );
  }
}
