import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/friends_repository.dart';
import '../services/auth_service.dart';
import '../services/contacts_service.dart';
import '../widgets/invite_sheet.dart';
import '../widgets/phone_register_dialog.dart';
import 'add_friend_by_code_screen.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final _contactsService = ContactsService();

  bool _loading = true;
  bool _permissionDenied = false;
  bool _phoneRegistered = true; // 확인 전에는 배너 숨김
  List<ContactMatch> _matches = [];
  final Set<String> _addedPhones = {};

  @override
  void initState() {
    super.initState();
    _load();
    _checkPhone();
  }

  Future<void> _checkPhone() async {
    final registered =
        await context.read<FriendsRepository>().isMyPhoneRegistered();
    if (mounted) setState(() => _phoneRegistered = registered);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });
    final contacts = await _contactsService.fetchContacts();
    if (!mounted) return;
    if (contacts == null) {
      setState(() {
        _loading = false;
        _permissionDenied = true;
      });
      return;
    }
    final matches =
        await context.read<FriendsRepository>().matchContacts(contacts);
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _loading = false;
    });
  }

  Future<void> _addFriend(ContactMatch match) async {
    await context.read<FriendsRepository>().addFriend(match);
    if (!mounted) return;
    setState(() => _addedPhones.add(match.contact.phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${match.contact.name}님을 친구로 추가했어요!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _invite(ContactMatch match) async {
    final me = context.read<AuthService>().user;
    await showInviteSheet(
      context,
      contact: match.contact,
      myNickname: me?.nickname,
      myUserId: me?.id,
    );
  }

  /// 닉네임·코드로 친구 추가 진입 카드
  Widget _codeEntryCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1526),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C4DFF), width: 1),
      ),
      child: ListTile(
        leading: const Text('🔎', style: TextStyle(fontSize: 22)),
        title: const Text('닉네임 · 코드로 추가',
            style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('연락처에 없어도 친구를 찾을 수 있어요',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddFriendByCodeScreen()),
          );
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUsers = _matches
        .where((m) => m.isAppUser && !_addedPhones.contains(m.contact.phone))
        .toList();
    final others = _matches.where((m) => !m.isAppUser).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('친구 찾기'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _permissionDenied
              // 연락처 권한이 없어도 코드로는 친구를 추가할 수 있어야 한다
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _codeEntryCard(),
                    ),
                    Expanded(child: _PermissionDenied(onRetry: _load)),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _codeEntryCard(),
                      const SizedBox(height: 10),
                      // 연락처와 무관하게 링크로 바로 초대
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF4527A0)],
                          ),
                        ),
                        child: ListTile(
                          leading: const Text('🎧',
                              style: TextStyle(fontSize: 24)),
                          title: const Text('초대 링크 보내기',
                              style:
                                  TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: const Text('카카오톡 · 인스타 DM · 문자',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            final me = context.read<AuthService>().user;
                            showInviteSheet(
                              context,
                              myNickname: me?.nickname,
                              myUserId: me?.id,
                            );
                          },
                        ),
                      ),
                      if (!_phoneRegistered)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF1A1526),
                            border: Border.all(
                                color: const Color(0xFF7C4DFF), width: 1),
                          ),
                          child: ListTile(
                            leading: const Text('📱',
                                style: TextStyle(fontSize: 22)),
                            title: const Text('내 번호를 등록해 보세요',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: const Text(
                                '친구들이 연락처로 나를 찾을 수 있어요',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            trailing: TextButton(
                              onPressed: () async {
                                final ok =
                                    await showPhoneRegisterDialog(context);
                                if (ok == true) _checkPhone();
                              },
                              child: const Text('등록'),
                            ),
                          ),
                        ),
                      if (appUsers.isNotEmpty) ...[
                        _SectionTitle('MUSE를 쓰고 있는 친구 (${appUsers.length})'),
                        for (final m in appUsers)
                          _ContactTile(
                            match: m,
                            trailing: FilledButton.tonal(
                              onPressed: () => _addFriend(m),
                              child: const Text('친구 추가'),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                      _SectionTitle('초대하기 (${others.length})'),
                      if (others.isEmpty && appUsers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('연락처에서 휴대폰 번호를 찾지 못했어요',
                                style: TextStyle(color: Colors.white54)),
                          ),
                        ),
                      for (final m in others)
                        _ContactTile(
                          match: m,
                          trailing: OutlinedButton(
                            onPressed: () => _invite(m),
                            child: const Text('초대'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.match, required this.trailing});

  final ContactMatch match;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1526),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white10,
            child: Text(
              match.contact.name.characters.first,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.contact.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  match.contact.phone,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white38),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📇', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('연락처 권한이 필요해요'),
          const SizedBox(height: 4),
          const Text(
            '친구를 찾으려면 설정에서 연락처 접근을 허용해 주세요',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
