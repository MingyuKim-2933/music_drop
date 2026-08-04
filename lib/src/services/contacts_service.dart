import 'package:flutter_contacts/flutter_contacts.dart';

/// 주소록의 연락처 한 건 (전화번호 정규화 완료)
class PhoneContact {
  final String name;
  final String phone; // 예: +821012345678

  const PhoneContact({required this.name, required this.phone});
}

/// 기기 주소록 접근 + 전화번호 정규화.
class ContactsService {
  /// 연락처 권한을 요청하고 전화번호가 있는 연락처만 반환.
  /// 권한 거부 시 null.
  Future<List<PhoneContact>?> fetchContacts() async {
    final status =
        await FlutterContacts.permissions.request(PermissionType.read);
    if (status != PermissionStatus.granted &&
        status != PermissionStatus.limited) {
      return null;
    }

    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.phone},
    );
    final result = <PhoneContact>[];
    final seen = <String>{};

    for (final c in contacts) {
      for (final p in c.phones) {
        final normalized = normalizeKoreanPhone(p.number);
        if (normalized == null || !seen.add(normalized)) continue;
        final name = c.displayName;
        result.add(PhoneContact(
          name: (name == null || name.isEmpty) ? normalized : name,
          phone: normalized,
        ));
      }
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// 한국 휴대폰 번호를 E.164(+82...)로 정규화. 휴대폰이 아니면 null.
  static String? normalizeKoreanPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+82')) {
      digits = '0${digits.substring(3)}';
    }
    if (!RegExp(r'^01[016789][0-9]{7,8}$').hasMatch(digits)) return null;
    return '+82${digits.substring(1)}';
  }
}
