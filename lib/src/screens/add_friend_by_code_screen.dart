import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_search_result.dart';
import '../repositories/friends_repository.dart';
import '../services/auth_service.dart';

/// 닉네임 또는 친구 코드로 친구 찾기/추가
class AddFriendByCodeScreen extends StatefulWidget {
  const AddFriendByCodeScreen({super.key});

  @override
  State<AddFriendByCodeScreen> createState() => _AddFriendByCodeScreenState();
}

class _AddFriendByCodeScreenState extends State<AddFriendByCodeScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  String? _myCode;
  List<UserSearchResult> _results = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadMyCode();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMyCode() async {
    final code = await context.read<FriendsRepository>().myFriendCode();
    if (mounted) setState(() => _myCode = code);
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      if (query.trim().isEmpty) {
        setState(() {
          _results = [];
          _searched = false;
        });
        return;
      }
      setState(() => _searching = true);
      try {
        final results =
            await context.read<FriendsRepository>().searchUsers(query);
        if (mounted) setState(() => _results = results);
      } finally {
        if (mounted) {
          setState(() {
            _searching = false;
            _searched = true;
          });
        }
      }
    });
  }

  Future<void> _addFriend(UserSearchResult user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FriendsRepository>().addFriendById(user.id);
      if (!mounted) return;
      setState(() {
        _results = _results
            .map((u) => u.id == user.id ? u.copyWith(alreadyFriend: true) : u)
            .toList();
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('${user.nickname}님을 친구로 추가했어요!'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('친구 추가에 실패했어요')),
      );
    }
  }

  Future<void> _copyCode() async {
    if (_myCode == null) return;
    await Clipboard.setData(ClipboardData(text: _myCode!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('친구 코드를 복사했어요!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _shareCode() async {
    if (_myCode == null) return;
    final me = context.read<AuthService>().user;
    await SharePlus.instance.share(ShareParams(
      text: 'MUSE에서 친구 하자! 🎧\n'
          '${me?.nickname ?? '내'} 친구 코드: $_myCode\n'
          'MUSE 앱 → 친구 찾기 → 코드로 추가에서 입력하면 돼!',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('코드로 친구 추가'),
      ),
      body: Column(
        children: [
          // ── 내 친구 코드 카드 ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), Color(0xFF4527A0)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('내 친구 코드',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _myCode ?? '···',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: '복사',
                      onPressed: _copyCode,
                    ),
                    IconButton(
                      icon: const Icon(Icons.ios_share, size: 20),
                      tooltip: '공유',
                      onPressed: _shareCode,
                    ),
                  ],
                ),
                const Text(
                  '이 코드를 친구에게 알려주면 나를 추가할 수 있어요',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // ── 검색 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: '닉네임 또는 친구 코드 (예: ABC123)',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFF1A1526),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _searched && !_searching
                          ? '검색 결과가 없어요'
                          : '친구의 닉네임이나 코드를 입력해 보세요',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final u = _results[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1526),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Text(u.emoji,
                                style: const TextStyle(fontSize: 18)),
                          ),
                          title: Text(u.nickname,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(u.friendCode,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  letterSpacing: 2)),
                          trailing: u.alreadyFriend
                              ? const Chip(
                                  label: Text('친구',
                                      style: TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                )
                              : FilledButton.tonal(
                                  onPressed: () => _addFriend(u),
                                  child: const Text('친구 추가'),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
