import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

/// 계정 삭제 확인 다이얼로그.
/// 실수 방지를 위해 "삭제"를 직접 입력해야 진행된다.
Future<bool?> showDeleteAccountDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  static const _keyword = '삭제';

  @override
  void initState() {
    super.initState();
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool get _canDelete => _confirm.text.trim() == _keyword && !_busy;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '삭제에 실패했어요. 잠시 후 다시 시도해 주세요';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1526),
      title: const Text('계정 삭제'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계정을 삭제하면 아래 정보가 모두 사라지고 되돌릴 수 없어요.\n\n'
            '• 프로필과 로그인 정보\n'
            '• 내가 만든 플레이리스트와 담은 곡\n'
            '• 친구 관계, 그룹, 주고받은 반응\n'
            '• 감상 기록과 등록한 전화번호',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirm,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '계속하려면 "$_keyword"를 입력하세요',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            disabledBackgroundColor: Colors.white12,
          ),
          onPressed: _canDelete ? _delete : null,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('영구 삭제'),
        ),
      ],
    );
  }
}
