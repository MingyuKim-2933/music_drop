/// 외부 서비스 키 모음.
///
/// - 카카오: https://developers.kakao.com → 앱 생성 → 네이티브 앱 키
///   ⚠️ android/app/src/main/AndroidManifest.xml 의 "kakao{네이티브앱키}" 스킴도 함께 교체할 것
/// - 네이버: https://developers.naver.com → 애플리케이션 등록 (네이버 로그인)
///   ⚠️ AndroidManifest.xml 의 com.naver.sdk.* meta-data,
///      ios/Runner/Info.plist 의 Nid* 키도 함께 교체할 것
class AppKeys {
  static const kakaoNativeAppKey = '3404dd9da9878ef06a402c36795cb1c0';
  static const naverClientId = 'NAVER_CLIENT_ID';
  static const naverClientSecret = 'NAVER_CLIENT_SECRET';
  static const naverClientName = '듣는중';
}
