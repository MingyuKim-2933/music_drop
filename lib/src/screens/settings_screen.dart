import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/friends_repository.dart';
import '../services/auth_service.dart';
import '../services/media_session_channel.dart';
import '../services/now_playing_service.dart';
import '../services/spotify_auth.dart';
import '../widgets/phone_register_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  late Future<bool> _phoneRegistered;

  @override
  void initState() {
    super.initState();
    _phoneRegistered = context.read<FriendsRepository>().isMyPhoneRegistered();
  }

  Future<void> _connectSpotify() async {
    setState(() => _busy = true);
    try {
      final ok = await context.read<SpotifyAuth>().connect();
      if (!mounted) return;
      if (ok) {
        await context.read<NowPlayingService>().refreshConnections();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Spotify 연결 완료!' : 'Spotify 연결에 실패했어요')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결이 취소되었거나 오류가 발생했어요')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NowPlayingService>();
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('계정',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF1A1526),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white10,
                backgroundImage: auth.user?.profileImageUrl != null
                    ? NetworkImage(auth.user!.profileImageUrl!)
                    : null,
                child: auth.user?.profileImageUrl == null
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),
              title: Text(auth.user?.nickname ?? ''),
              subtitle: Text(
                '${auth.user?.provider.label ?? ''} 로그인'
                '${auth.user?.email != null ? ' · ${auth.user!.email}' : ''}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  await context.read<AuthService>().signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
                child: const Text('로그아웃'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('친구 찾기',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF1A1526),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: FutureBuilder<bool>(
              future: _phoneRegistered,
              builder: (context, snapshot) {
                final registered = snapshot.data ?? false;
                return ListTile(
                  leading: const Icon(Icons.phone_iphone,
                      color: Colors.white70),
                  title: const Text('내 전화번호 등록'),
                  subtitle: Text(
                    registered
                        ? '등록됨 · 친구들이 연락처로 나를 찾을 수 있어요'
                        : '등록하면 친구들이 연락처로 나를 찾을 수 있어요',
                  ),
                  trailing: registered
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFF00CD3C))
                      : TextButton(
                          onPressed: () async {
                            final ok =
                                await showPhoneRegisterDialog(context);
                            if (ok == true && mounted) {
                              setState(() {
                                _phoneRegistered = context
                                    .read<FriendsRepository>()
                                    .isMyPhoneRegistered();
                              });
                            }
                          },
                          child: const Text('등록'),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('음악 연결',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF1A1526),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.music_note,
                      color: Color(0xFF1DB954)),
                  title: const Text('Spotify'),
                  subtitle: Text(
                    service.spotifyConnected
                        ? '연결됨 · iOS/Android 모두 지원'
                        : '공식 API로 실시간 감상 조회',
                  ),
                  trailing: service.spotifyConnected
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFF1DB954))
                      : TextButton(
                          onPressed: _busy ? null : _connectSpotify,
                          child: const Text('연결'),
                        ),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading:
                      const Icon(Icons.phone_android, color: Colors.white70),
                  title: const Text('멜론 · 지니 · FLO · 유튜브뮤직'),
                  subtitle: Text(
                    MediaSessionChannel.isSupported
                        ? (service.androidPermissionGranted
                            ? '알림 접근 허용됨 · 재생 자동 감지 중'
                            : '알림 접근 권한을 허용하면 자동 감지돼요')
                        : 'iOS에서는 지원되지 않아요 (공식 API 없음)',
                  ),
                  trailing: !MediaSessionChannel.isSupported
                      ? null
                      : service.androidPermissionGranted
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF00CD3C))
                          : TextButton(
                              onPressed: () async {
                                await MediaSessionChannel
                                    .openPermissionSettings();
                              },
                              child: const Text('허용하기'),
                            ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('안내',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          const Card(
            color: Color(0xFF1A1526),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '멜론, 지니뮤직, FLO는 외부에 감상 기록 API를 제공하지 않아요.\n'
                '그래서 Android에서는 알림 접근 권한으로 기기에서 직접 '
                '재생 정보를 읽고, iOS에서는 Spotify 계정 연동으로 동작해요.\n\n'
                '수집된 정보는 친구에게 "지금 듣는 곡"을 보여주는 데만 사용돼요.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
