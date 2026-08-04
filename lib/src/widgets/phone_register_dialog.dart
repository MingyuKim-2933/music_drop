import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/friends_repository.dart';
import '../services/contacts_service.dart';

/// 내 전화번호 등록 다이얼로그.
/// 등록 성공 시 true 반환. 번호는 해시로만 서버에 저장된다.
Future<bool?> showPhoneRegisterDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const _PhoneRegisterDialog(),
  );
}

class _PhoneRegisterDialog extends StatefulWidget {
  const _PhoneRegisterDialog();

  @override
  State<_PhoneRegisterDialog> createState() => _PhoneRegisterDialogState();
}

class _PhoneRegisterDialogState extends State<_PhoneRegisterDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final normalized =
        ContactsService.normalizeKoreanPhone(_controller.text);
    if (normalized == null) {
      setState(() => _error = '올바른 휴대폰 번호를 입력해 주세요 (예: 010-1234-5678)');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<FriendsRepository>().registerMyPhone(normalized);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '등록에 실패했어요. 잠시 후 다시 시도해 주세요';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1526),
      title: const Text('내 전화번호 등록'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '번호를 등록하면 연락처에 나를 저장한 친구들이\n'
            'MUSE에서 나를 찾을 수 있어요.\n'
            '번호는 암호화(해시)되어 원본은 저장되지 않아요.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: '휴대폰 번호',
              hintText: '010-1234-5678',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('나중에'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('등록'),
        ),
      ],
    );
  }
}
