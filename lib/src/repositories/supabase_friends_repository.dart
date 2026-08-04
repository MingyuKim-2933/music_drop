import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/friend.dart';
import '../models/reaction.dart';
import '../models/track.dart';
import '../services/contacts_service.dart';
import 'friends_repository.dart';

/// Supabase 실데이터 친구 리포지토리.
///
/// - 친구 피드: friendships → 친구 프로필 + now_playing 조인
/// - 연락처 매칭: 전화번호를 SHA-256 해시로 변환해 profiles.phone_hash와 대조
///   (원본 번호는 서버로 보내지 않는다)
class SupabaseFriendsRepository implements FriendsRepository {
  SupabaseClient get _db => Supabase.instance.client;
  String get _uid => _db.auth.currentUser!.id;

  /// 전화번호 해시 (등록/매칭 양쪽에서 동일하게 사용)
  static String phoneHash(String e164) =>
      sha256.convert(utf8.encode('muse:phone:$e164')).toString();

  @override
  Future<List<Friend>> fetchFriends() async {
    final rows = await _db
        .from('friendships')
        .select(
            'friend:profiles!friendships_friend_id_fkey(id, nickname, avatar_emoji, now_playing(*))')
        .eq('user_id', _uid);

    return rows.map((r) {
      final p = Map<String, dynamic>.from(r['friend'] as Map);
      // now_playing은 1:1 관계 — 버전에 따라 객체 또는 리스트로 올 수 있음
      final npRaw = p['now_playing'];
      final np = npRaw is List
          ? (npRaw.isEmpty ? null : Map<String, dynamic>.from(npRaw.first as Map))
          : (npRaw == null ? null : Map<String, dynamic>.from(npRaw as Map));
      return Friend(
        id: p['id'] as String,
        nickname: p['nickname'] as String,
        emoji: p['avatar_emoji'] as String? ?? '🎧',
        nowPlaying: np == null
            ? null
            : NowPlaying(
                title: np['title'] as String,
                artist: np['artist'] as String,
                albumArtUrl: null,
                source: MusicSource.values.firstWhere(
                  (s) => s.name == np['source'],
                  orElse: () => MusicSource.unknown,
                ),
                isPlaying: np['is_playing'] as bool? ?? false,
                updatedAt: DateTime.parse(np['updated_at'] as String),
              ),
      );
    }).toList();
  }

  @override
  Future<List<ContactMatch>> matchContacts(List<PhoneContact> contacts) async {
    if (contacts.isEmpty) return [];
    final hashToContact = {
      for (final c in contacts) phoneHash(c.phone): c,
    };

    // in 필터는 URL 길이 제한이 있으므로 나눠서 조회
    final matched = <String, String>{}; // phone_hash → profile id
    final hashes = hashToContact.keys.toList();
    for (var i = 0; i < hashes.length; i += 100) {
      final chunk = hashes.sublist(
          i, i + 100 > hashes.length ? hashes.length : i + 100);
      final rows = await _db
          .from('profiles')
          .select('id, phone_hash')
          .inFilter('phone_hash', chunk)
          .neq('id', _uid);
      for (final r in rows) {
        matched[r['phone_hash'] as String] = r['id'] as String;
      }
    }

    return [
      for (final entry in hashToContact.entries)
        ContactMatch(
          contact: entry.value,
          isAppUser: matched.containsKey(entry.key),
          profileId: matched[entry.key],
        ),
    ];
  }

  @override
  Future<void> addFriend(ContactMatch match) async {
    final profileId = match.profileId;
    if (profileId == null) return;
    await _db.from('friendships').upsert({
      'user_id': _uid,
      'friend_id': profileId,
    });
  }

  @override
  Future<bool> isMyPhoneRegistered() async {
    final row = await _db
        .from('profiles')
        .select('phone_hash')
        .eq('id', _uid)
        .single();
    return row['phone_hash'] != null;
  }

  @override
  Future<void> registerMyPhone(String e164) async {
    await _db
        .from('profiles')
        .update({'phone_hash': phoneHash(e164)}).eq('id', _uid);
  }

  @override
  Future<void> sendReaction({
    required String toUserId,
    String emoji = '🫶',
    String? trackTitle,
  }) async {
    await _db.from('reactions').insert({
      'from_user': _uid,
      'to_user': toUserId,
      'emoji': emoji,
      'track_title': trackTitle,
    });
  }

  @override
  Future<List<Reaction>> fetchReceivedReactions() async {
    final rows = await _db
        .from('reactions')
        .select('id, emoji, track_title, created_at, '
            'sender:profiles!reactions_from_user_fkey(nickname)')
        .eq('to_user', _uid)
        .order('created_at', ascending: false)
        .limit(30);
    return rows
        .map((r) => Reaction(
              id: r['id'] as String,
              fromNickname:
                  (r['sender'] as Map?)?['nickname'] as String? ?? '알 수 없음',
              emoji: r['emoji'] as String? ?? '🫶',
              trackTitle: r['track_title'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
            ))
        .toList();
  }
}
