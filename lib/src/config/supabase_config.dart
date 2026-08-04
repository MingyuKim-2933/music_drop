/// Supabase 프로젝트 설정.
///
/// https://supabase.com/dashboard → 프로젝트 생성 →
/// Settings > API Keys 에서 Project URL과 Publishable key를 복사해 붙여넣는다.
/// (구형 프로젝트의 anon public 키를 넣어도 동작한다)
/// 이 키는 RLS(Row Level Security)로 보호되므로 앱에 포함해도 안전하다.
class SupabaseConfig {
  static const url = 'YOUR_SUPABASE_URL'; // 예: https://xxxx.supabase.co
  static const publishableKey =
      'YOUR_SUPABASE_PUBLISHABLE_KEY'; // sb_publishable_... 또는 anon 키

  static bool get isConfigured =>
      !url.contains('YOUR_') && !publishableKey.contains('YOUR_');
}
