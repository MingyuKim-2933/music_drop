import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/friend.dart';
import '../models/friend_group.dart';
import '../models/reaction.dart';
import '../models/track.dart';
import '../models/user_search_result.dart';
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

    // 매칭은 서버 함수로만 가능 (phone_hash 직접 조회는 차단되어 있음).
    // 내가 보낸 해시와 일치하는 것만 돌려주므로 전체 덤프가 불가능하다.
    final matched = <String, String>{}; // phone_hash → profile id
    final hashes = hashToContact.keys.toList();
    for (var i = 0; i < hashes.length; i += 500) {
      final chunk = hashes.sublist(
          i, i + 500 > hashes.length ? hashes.length : i + 500);
      final rows = await _db.rpc<List<dynamic>>(
        'match_contacts',
        params: {'hashes': chunk},
      );
      for (final r in rows) {
        final row = Map<String, dynamic>.from(r as Map);
        matched[row['phone_hash'] as String] = row['id'] as String;
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
  Future<void> addFriendById(String profileId) async {
    if (profileId == _uid) return;
    await _db.from('friendships').upsert({
      'user_id': _uid,
      'friend_id': profileId,
    });
  }

  @override
  Future<String?> myFriendCode() async {
    final row = await _db
        .from('profiles')
        .select('friend_code')
        .eq('id', _uid)
        .single();
    return row['friend_code'] as String?;
  }

  @override
  Future<List<UserSearchResult>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 친구 코드는 대문자 정확히 일치, 닉네임은 부분 일치
    final rows = await _db
        .from('profiles')
        .select('id, nickname, avatar_emoji, friend_code')
        .or('friend_code.eq.${q.toUpperCase()},nickname.ilike.%$q%')
        .neq('id', _uid)
        .limit(20);

    final friendIds = (await _db
            .from('friendships')
            .select('friend_id')
            .eq('user_id', _uid))
        .map((r) => r['friend_id'] as String)
        .toSet();

    return rows
        .map((r) => UserSearchResult(
              id: r['id'] as String,
              nickname: r['nickname'] as String,
              emoji: r['avatar_emoji'] as String? ?? '🎧',
              friendCode: r['friend_code'] as String? ?? '',
              alreadyFriend: friendIds.contains(r['id'] as String),
            ))
        .toList();
  }

  @override
  Future<bool> isMyPhoneRegistered() async {
    // phone_hash는 조회 권한이 없으므로 등록 여부만 나타내는 파생 컬럼을 읽는다
    final row =
        await _db.from('profiles').select('has_phone').eq('id', _uid).single();
    return row['has_phone'] as bool? ?? false;
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

  // ── 친구 그룹 ──────────────────────────────────────────

  @override
  Future<List<FriendGroup>> fetchGroups() async {
    final rows = await _db
        .from('friend_groups')
        .select('id, name, emoji, friend_group_members(friend_id)')
        .eq('owner_id', _uid)
        .order('sort_order');
    return rows
        .map((r) => FriendGroup(
              id: r['id'] as String,
              name: r['name'] as String,
              emoji: r['emoji'] as String? ?? '👥',
              memberIds: ((r['friend_group_members'] as List?) ?? [])
                  .map((m) => (m as Map)['friend_id'] as String)
                  .toSet(),
            ))
        .toList();
  }

  @override
  Future<FriendGroup> createGroup({
    required String name,
    required String emoji,
  }) async {
    final row = await _db
        .from('friend_groups')
        .insert({'owner_id': _uid, 'name': name, 'emoji': emoji})
        .select()
        .single();
    return FriendGroup(
      id: row['id'] as String,
      name: row['name'] as String,
      emoji: row['emoji'] as String? ?? '👥',
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _db.from('friend_groups').delete().eq('id', groupId);
  }

  @override
  Future<void> setGroupMembers(String groupId, Set<String> friendIds) async {
    await _db.from('friend_group_members').delete().eq('group_id', groupId);
    if (friendIds.isEmpty) return;
    await _db.from('friend_group_members').insert([
      for (final id in friendIds) {'group_id': groupId, 'friend_id': id},
    ]);
  }
}
