import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Spotify OAuth 2.0 Authorization Code + PKCE 플로우.
///
/// 사용 전에 https://developer.spotify.com/dashboard 에서 앱을 만들고
/// Redirect URI 로 `soundmate://callback` 을 등록한 뒤
/// [clientId] 를 발급받은 값으로 바꿔야 한다.
class SpotifyAuth {
  static const clientId = '83d360c0439344838b12fa23a893f59c';
  static const redirectUri = 'soundmate://callback';
  static const _scopes = 'user-read-currently-playing user-read-recently-played';

  static const _kAccessToken = 'spotify_access_token';
  static const _kRefreshToken = 'spotify_refresh_token';
  static const _kExpiresAt = 'spotify_expires_at';

  Future<bool> get isConnected async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken) != null;
  }

  /// 브라우저를 띄워 사용자 로그인 → 토큰 저장. 성공 여부 반환.
  Future<bool> connect() async {
    final verifier = _randomString(64);
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');

    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
      'scope': _scopes,
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'soundmate',
    );
    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) return false;

    final res = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': verifier,
      },
    );
    if (res.statusCode != 200) return false;
    await _saveTokens(jsonDecode(res.body) as Map<String, dynamic>);
    return true;
  }

  /// 유효한 액세스 토큰 반환. 만료 시 자동 갱신, 미연동이면 null.
  Future<String?> accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_kRefreshToken);
    if (refresh == null) return null;

    final expiresAt = prefs.getInt(_kExpiresAt) ?? 0;
    final token = prefs.getString(_kAccessToken);
    if (token != null &&
        DateTime.now().millisecondsSinceEpoch < expiresAt - 60000) {
      return token;
    }

    final res = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refresh,
        'client_id': clientId,
      },
    );
    if (res.statusCode != 200) return null;
    await _saveTokens(jsonDecode(res.body) as Map<String, dynamic>);
    return (await SharedPreferences.getInstance()).getString(_kAccessToken);
  }

  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kExpiresAt);
  }

  Future<void> _saveTokens(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, json['access_token'] as String);
    if (json['refresh_token'] != null) {
      await prefs.setString(_kRefreshToken, json['refresh_token'] as String);
    }
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    await prefs.setInt(
      _kExpiresAt,
      DateTime.now().millisecondsSinceEpoch + expiresIn * 1000,
    );
  }

  String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
