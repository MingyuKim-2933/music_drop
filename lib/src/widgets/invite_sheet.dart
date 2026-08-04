import 'package:flutter/material.dart';

import '../services/contacts_service.dart';
import '../services/invite_service.dart';

/// 초대 방법 선택 바텀시트.
/// [contact]가 있으면 문자에 수신자 번호를 채워준다.
Future<void> showInviteSheet(
  BuildContext context, {
  PhoneContact? contact,
  String? myNickname,
  String? myUserId,
}) {
  final invite = InviteService();

  Future<void> run(
    BuildContext sheetContext,
    Future<void> Function() action, {
    String? doneMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(sheetContext).pop();
    try {
      await action();
      if (doneMessage != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(doneMessage), duration: const Duration(seconds: 2)),
        );
      }
    } catch (_) {
      // 카카오 키 미등록/앱 미설치 등 → 시스템 공유 시트로 폴백
      await invite.shareViaSystem(
        fromNickname: myNickname,
        toName: contact?.name,
        referrerId: myUserId,
      );
    }
  }

  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1526),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact != null ? '${contact.name}님 초대하기' : '친구 초대하기',
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '같이 들을 친구에게 초대 링크를 보내요',
              style: Theme.of(sheetContext)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            _InviteOption(
              emoji: '💬',
              color: const Color(0xFFFEE500),
              title: '카카오톡',
              onTap: () => run(
                sheetContext,
                () => invite.shareViaKakao(
                    fromNickname: myNickname, referrerId: myUserId),
              ),
            ),
            _InviteOption(
              emoji: '📸',
              color: const Color(0xFFE1306C),
              title: '인스타그램 DM',
              subtitle: '초대 메시지를 복사한 뒤 DM 화면을 열어요',
              onTap: () => run(
                sheetContext,
                () => invite.shareViaInstagramDm(
                    fromNickname: myNickname, referrerId: myUserId),
                doneMessage: '초대 메시지를 복사했어요. DM에 붙여넣기 해주세요!',
              ),
            ),
            _InviteOption(
              emoji: '✉️',
              color: const Color(0xFF34C759),
              title: '문자 메시지',
              subtitle: contact?.phone,
              onTap: () => run(
                sheetContext,
                () => invite.shareViaSms(
                  phone: contact?.phone,
                  fromNickname: myNickname,
                  toName: contact?.name,
                  referrerId: myUserId,
                ),
              ),
            ),
            _InviteOption(
              emoji: '🔗',
              color: Colors.white24,
              title: '초대 링크 복사',
              onTap: () => run(
                sheetContext,
                () => invite.copyLink(
                    fromNickname: myNickname, referrerId: myUserId),
                doneMessage: '초대 링크를 복사했어요!',
              ),
            ),
            _InviteOption(
              emoji: '📤',
              color: Colors.white24,
              title: '다른 앱으로 공유',
              onTap: () => run(
                sheetContext,
                () => invite.shareViaSystem(
                  fromNickname: myNickname,
                  toName: contact?.name,
                  referrerId: myUserId,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

class _InviteOption extends StatelessWidget {
  const _InviteOption({
    required this.emoji,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      onTap: onTap,
    );
  }
}
