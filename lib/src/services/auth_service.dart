import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// 로그인 세션 관리.
///
/// 카카오/네이버는 각 공식 SDK로 인증하고, 이메일 가입은 아직 백엔드가 없어
/// 기기 로컬(SharedPreferences)에 계정을 저장하는 목업 구현이다.
/// 백엔드가 붙으면 이메일 계정 저장/검증 부분만 서버 호출로 교체하면 된다.
class AuthService extends ChangeNotifier {
  static const _kSession = 'auth_session';
  static const _kEmailUsers = 'auth_email_users'; // 목업 로컬 계정 DB

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// 앱 시작 시 저장된 세션 복원
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSession);
    if (raw != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_kSession);
      }
    }
    _initialized = true;
    notifyListeners();
  }

  // ── 카카오 ──────────────────────────────────────────────

  Future<void> signInWithKakao() async {
    kakao.OAuthToken token;
    if (await kakao.isKakaoTalkInstalled()) {
      try {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
        // 카카오톡 로그인 취소/실패 시 계정 로그인으로 폴백
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await kakao.UserApi.instance.loginWithKakaoAccount();
    }
    assert(token.accessToken.isNotEmpty);

    final me = await kakao.UserApi.instance.me();
    await _saveSession(AppUser(
      id: 'kakao:${me.id}',
      nickname: me.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
      provider: AuthProvider.kakao,
      email: me.kakaoAccount?.email,
      profileImageUrl: me.kakaoAccount?.profile?.profileImageUrl,
    ));
  }

  // ── 네이버 ──────────────────────────────────────────────

  Future<void> signInWithNaver() async {
    final result = await FlutterNaverLogin.logIn();
    if (result.status != NaverLoginStatus.loggedIn || result.account == null) {
      throw Exception(result.errorMessage ?? '네이버 로그인에 실패했어요');
    }
    final account = result.account!;
    await _saveSession(AppUser(
      id: 'naver:${account.id}',
      nickname: account.nickname ?? account.name ?? '네이버 사용자',
      provider: AuthProvider.naver,
      email: account.email,
      profileImageUrl: account.profileImage,
    ));
  }

  // ── 이메일 (로컬 목업) ──────────────────────────────────

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadEmailUsers(prefs);
    if (users.containsKey(email)) {
      throw Exception('이미 가입된 이메일이에요');
    }
    users[email] = {
      'passwordHash': _hash(password),
      'nickname': nickname,
    };
    await prefs.setString(_kEmailUsers, jsonEncode(users));
    await _saveSession(AppUser(
      id: 'email:$email',
      nickname: nickname,
      provider: AuthProvider.email,
      email: email,
    ));
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadEmailUsers(prefs);
    final record = users[email];
    if (record == null || record['passwordHash'] != _hash(password)) {
      throw Exception('이메일 또는 비밀번호가 올바르지 않아요');
    }
    await _saveSession(AppUser(
      id: 'email:$email',
      nickname: record['nickname'] as String,
      provider: AuthProvider.email,
      email: email,
    ));
  }

  // ── 로그아웃 ────────────────────────────────────────────

  Future<void> signOut() async {
    switch (_user?.provider) {
      case AuthProvider.kakao:
        try {
          await kakao.UserApi.instance.logout();
        } catch (_) {}
      case AuthProvider.naver:
        try {
          await FlutterNaverLogin.logOut();
        } catch (_) {}
      default:
        break;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
    _user = null;
    notifyListeners();
  }

  // ── 내부 헬퍼 ───────────────────────────────────────────

  Future<void> _saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, jsonEncode(user.toJson()));
    _user = user;
    notifyListeners();
  }

  Map<String, dynamic> _loadEmailUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_kEmailUsers);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  String _hash(String password) =>
      sha256.convert(utf8.encode('soundmate:$password')).toString();
}
