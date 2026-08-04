import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/friend.dart';
import '../models/friend_group.dart';
import '../models/reaction.dart';
import '../services/contacts_service.dart';
import 'friends_repository.dart';
import 'supabase_friends_repository.dart';

/// Supabase 설정 + 로그인 세션이 있으면 실데이터, 아니면 목업.
class RoutedFriendsRepository implements FriendsRepository {
  final _mock = MockFriendsRepository();
  final _remote = SupabaseFriendsRepository();

  FriendsRepository get _active {
    if (SupabaseConfig.isConfigured &&
        Supabase.instance.client.auth.currentUser != null) {
      return _remote;
    }
    return _mock;
  }

  @override
  Future<List<Friend>> fetchFriends() => _active.fetchFriends();

  @override
  Future<List<ContactMatch>> matchContacts(List<PhoneContact> contacts) =>
      _active.matchContacts(contacts);

  @override
  Future<void> addFriend(ContactMatch match) => _active.addFriend(match);

  @override
  Future<bool> isMyPhoneRegistered() => _active.isMyPhoneRegistered();

  @override
  Future<void> registerMyPhone(String e164) => _active.registerMyPhone(e164);

  @override
  Future<void> sendReaction({
    required String toUserId,
    String emoji = '🫶',
    String? trackTitle,
  }) =>
      _active.sendReaction(
          toUserId: toUserId, emoji: emoji, trackTitle: trackTitle);

  @override
  Future<List<Reaction>> fetchReceivedReactions() =>
      _active.fetchReceivedReactions();

  @override
  Future<List<FriendGroup>> fetchGroups() => _active.fetchGroups();

  @override
  Future<FriendGroup> createGroup(
          {required String name, required String emoji}) =>
      _active.createGroup(name: name, emoji: emoji);

  @override
  Future<void> deleteGroup(String groupId) => _active.deleteGroup(groupId);

  @override
  Future<void> setGroupMembers(String groupId, Set<String> friendIds) =>
      _active.setGroupMembers(groupId, friendIds);
}
