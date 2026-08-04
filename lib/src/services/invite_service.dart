import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 친구 초대 링크 전송 (카카오톡 / 인스타 DM / 문자 / 링크 복사 / 시스템 공유)
class InviteService {
  /// 초대 랜딩 링크. 서비스 도메인이 생기면 교체하고,
  /// ref 파라미터로 추천인 추적(딥링크 어트리뷰션)을 붙인다.
  static const _baseUrl = 'https://github.com/MingyuKim-2933/music_drop';

  String inviteLink({String? referrerId}) => referrerId == null
      ? _baseUrl
      : '$_baseUrl?ref=${Uri.encodeComponent(referrerId)}';

  String inviteMessage({String? fromNickname, String? toName, String? referrerId}) {
    final greeting = toName != null ? '$toName님, ' : '';
    final from = fromNickname != null ? '$fromNickname님이 초대했어요!\n' : '';
    return '$greeting듣는중에서 같이 음악 들어요! 🎧\n'
        '$from지금 무슨 노래 듣는지 친구들과 실시간으로 공유하는 앱이에요.\n'
        '${inviteLink(referrerId: referrerId)}';
  }

  /// 카카오톡 공유. 카카오 SDK 키가 등록되어 있고 카카오톡이 설치된 경우 동작.
  /// 실패 시 예외 → 호출부에서 시스템 공유 시트로 폴백.
  Future<void> shareViaKakao({String? fromNickname, String? referrerId}) async {
    final template = TextTemplate(
      text: '듣는중에서 같이 음악 들어요! 🎧\n'
          '${fromNickname != null ? '$fromNickname님이 초대했어요!' : ''}',
      link: Link(
        webUrl: Uri.parse(inviteLink(referrerId: referrerId)),
        mobileWebUrl: Uri.parse(inviteLink(referrerId: referrerId)),
      ),
      buttonTitle: '듣는중 시작하기',
    );

    if (await ShareClient.instance.isKakaoTalkSharingAvailable()) {
      // shareDefault가 카카오톡 실행까지 처리한다
      await ShareClient.instance.shareDefault(template: template);
    } else {
      // 카카오톡 미설치 → 웹 공유
      final uri = await WebSharerClient.instance.makeDefaultUrl(template: template);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 인스타그램 DM. 공식 API가 프리필 메시지를 지원하지 않아
  /// 링크를 클립보드에 복사한 뒤 인스타 DM 화면을 연다.
  Future<void> shareViaInstagramDm({String? fromNickname, String? referrerId}) async {
    await copyLink(fromNickname: fromNickname, referrerId: referrerId);
    final appUri = Uri.parse('instagram://direct-inbox');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(
        Uri.parse('https://www.instagram.com/direct/inbox/'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// 문자(SMS). [phone]이 있으면 수신자까지 채워서 연다.
  Future<void> shareViaSms({
    String? phone,
    String? fromNickname,
    String? toName,
    String? referrerId,
  }) async {
    final body = inviteMessage(
      fromNickname: fromNickname,
      toName: toName,
      referrerId: referrerId,
    );
    // iOS는 구분자가 & , Android는 ? 를 쓴다
    final separator = Platform.isIOS ? '&' : '?';
    final uri = Uri.parse(
      'sms:${phone ?? ''}${separator}body=${Uri.encodeComponent(body)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> copyLink({String? fromNickname, String? referrerId}) async {
    await Clipboard.setData(ClipboardData(
      text: inviteMessage(fromNickname: fromNickname, referrerId: referrerId),
    ));
  }

  /// 시스템 공유 시트 (그 외 모든 앱)
  Future<void> shareViaSystem({
    String? fromNickname,
    String? toName,
    String? referrerId,
  }) async {
    await SharePlus.instance.share(ShareParams(
      text: inviteMessage(
        fromNickname: fromNickname,
        toName: toName,
        referrerId: referrerId,
      ),
    ));
  }
}
