import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../repositories/friends_repository.dart';
import '../services/contacts_service.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final _contactsService = ContactsService();

  bool _loading = true;
  bool _permissionDenied = false;
  List<ContactMatch> _matches = [];
  final Set<String> _addedPhones = {};

  @override
  void initState() {
    super.initState();
    _load();
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
    await context.read<FriendsRepository>().addFriend(match.contact);
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
    await SharePlus.instance.share(ShareParams(
      text: '${match.contact.name}님, 듣는중에서 같이 음악 들어요! 🎧\n'
          '지금 무슨 노래 듣는지 실시간으로 공유하는 앱이에요.\n'
          'https://github.com/MingyuKim-2933/music_drop',
    ));
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
              ? _PermissionDenied(onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (appUsers.isNotEmpty) ...[
                        _SectionTitle('듣는중을 쓰고 있는 친구 (${appUsers.length})'),
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
