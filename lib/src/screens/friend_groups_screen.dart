import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../models/friend_group.dart';
import '../repositories/friends_repository.dart';

/// 친구 그룹 관리 (생성/삭제/멤버 편집)
class FriendGroupsScreen extends StatefulWidget {
  const FriendGroupsScreen({super.key, required this.friends});

  final List<Friend> friends;

  @override
  State<FriendGroupsScreen> createState() => _FriendGroupsScreenState();
}

class _FriendGroupsScreenState extends State<FriendGroupsScreen> {
  List<FriendGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await context.read<FriendsRepository>().fetchGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _loading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _GroupFormDialog(),
    );
    if (result == null || !mounted) return;
    await context
        .read<FriendsRepository>()
        .createGroup(name: result.$1, emoji: result.$2);
    await _load();
  }

  Future<void> _editMembers(FriendGroup group) async {
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: const Color(0xFF1A1526),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MemberPicker(
        friends: widget.friends,
        initial: group.memberIds,
        groupName: group.name,
      ),
    );
    if (selected == null || !mounted) return;
    await context.read<FriendsRepository>().setGroupMembers(group.id, selected);
    await _load();
  }

  Future<void> _deleteGroup(FriendGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1526),
        title: const Text('그룹 삭제'),
        content: Text('"${group.name}" 그룹을 삭제할까요?\n(친구 관계는 유지돼요)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<FriendsRepository>().deleteGroup(group.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('친구 그룹'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGroup,
        icon: const Icon(Icons.add),
        label: const Text('새 그룹'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '그룹을 만들면 홈에서 친구 피드를\n그룹별로 나눠 볼 수 있어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, height: 1.6),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: _groups.length,
                  itemBuilder: (context, i) {
                    final g = _groups[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1526),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Text(g.emoji,
                              style: const TextStyle(fontSize: 18)),
                        ),
                        title: Text(g.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${g.memberIds.length}명',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white38),
                          onPressed: () => _deleteGroup(g),
                        ),
                        onTap: () => _editMembers(g),
                      ),
                    );
                  },
                ),
    );
  }
}

class _MemberPicker extends StatefulWidget {
  const _MemberPicker({
    required this.friends,
    required this.initial,
    required this.groupName,
  });

  final List<Friend> friends;
  final Set<String> initial;
  final String groupName;

  @override
  State<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends State<_MemberPicker> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.groupName} 멤버 선택',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (widget.friends.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text('먼저 친구를 추가해 주세요',
                      style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final f in widget.friends)
                      CheckboxListTile(
                        value: _selected.contains(f.id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(f.id);
                          } else {
                            _selected.remove(f.id);
                          }
                        }),
                        title: Text(f.nickname),
                        secondary: Text(f.emoji,
                            style: const TextStyle(fontSize: 20)),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text('저장 (${_selected.length}명)'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _GroupFormDialog extends StatefulWidget {
  const _GroupFormDialog();

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  final _name = TextEditingController();
  String _emoji = '👥';
  static const _emojis = ['👥', '🏫', '💼', '🏋️', '🎮', '🍻', '💜', '🎓'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1526),
      title: const Text('새 그룹'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '그룹 이름',
              hintText: '예) 대학 친구',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _emojis)
                GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: CircleAvatar(
                    backgroundColor:
                        _emoji == e ? const Color(0xFF7C4DFF) : Colors.white10,
                    child: Text(e),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((name, _emoji));
          },
          child: const Text('만들기'),
        ),
      ],
    );
  }
}
