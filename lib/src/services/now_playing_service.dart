import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/track.dart';
import 'media_session_channel.dart';
import 'spotify_api.dart';
import 'spotify_auth.dart';

/// 내 "지금 듣는 중" 상태를 통합 관리한다.
///
/// 우선순위:
/// 1. (Android) 기기 내 음악 앱의 MediaSession — 멜론/지니/FLO/유튜브뮤직/스포티파이 전부 감지
/// 2. Spotify Web API 폴링 — iOS 포함 모든 플랫폼에서 동작
class NowPlayingService extends ChangeNotifier {
  NowPlayingService(SpotifyAuth auth) : _spotify = SpotifyApi(auth), _auth = auth;

  final SpotifyApi _spotify;
  final SpotifyAuth _auth;

  NowPlaying? _mine;
  NowPlaying? get mine => _mine;

  bool _spotifyConnected = false;
  bool get spotifyConnected => _spotifyConnected;

  bool _androidPermissionGranted = false;
  bool get androidPermissionGranted => _androidPermissionGranted;

  StreamSubscription<NowPlaying?>? _nativeSub;
  Timer? _spotifyTimer;
  NowPlaying? _fromNative;
  NowPlaying? _fromSpotify;

  Future<void> start() async {
    _spotifyConnected = await _auth.isConnected;

    if (MediaSessionChannel.isSupported) {
      _androidPermissionGranted = await MediaSessionChannel.hasPermission();
      _nativeSub = MediaSessionChannel.nowPlayingStream().listen((np) {
        _fromNative = np;
        _recompute();
      });
    }

    _spotifyTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollSpotify(),
    );
    await _pollSpotify();
    notifyListeners();
  }

  Future<void> refreshConnections() async {
    _spotifyConnected = await _auth.isConnected;
    if (MediaSessionChannel.isSupported) {
      _androidPermissionGranted = await MediaSessionChannel.hasPermission();
    }
    await _pollSpotify();
    notifyListeners();
  }

  Future<void> _pollSpotify() async {
    if (!_spotifyConnected) return;
    try {
      _fromSpotify = await _spotify.fetchNowPlaying();
    } catch (_) {
      // 네트워크 오류는 조용히 넘어가고 다음 폴링에서 재시도
    }
    _recompute();
  }

  void _recompute() {
    // 실제 재생 중인 소스를 우선, 그다음 최신 업데이트 순
    final candidates = [_fromNative, _fromSpotify].whereType<NowPlaying>();
    NowPlaying? best;
    for (final c in candidates) {
      if (best == null) {
        best = c;
        continue;
      }
      if (c.isPlaying && !best.isPlaying) {
        best = c;
      } else if (c.isPlaying == best.isPlaying &&
          c.updatedAt.isAfter(best.updatedAt)) {
        best = c;
      }
    }
    _mine = best;
    notifyListeners();
  }

  @override
  void dispose() {
    _nativeSub?.cancel();
    _spotifyTimer?.cancel();
    super.dispose();
  }
}
