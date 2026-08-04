/// 로그인 제공자
enum AuthProvider {
  kakao('카카오'),
  naver('네이버'),
  email('이메일');

  const AuthProvider(this.label);
  final String label;
}

/// 로그인된 사용자
class AppUser {
  final String id;
  final String nickname;
  final AuthProvider provider;
  final String? email;
  final String? profileImageUrl;

  const AppUser({
    required this.id,
    required this.nickname,
    required this.provider,
    this.email,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'provider': provider.name,
        'email': email,
        'profileImageUrl': profileImageUrl,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        provider: AuthProvider.values.byName(json['provider'] as String),
        email: json['email'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
      );
}
