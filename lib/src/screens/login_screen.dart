import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../services/auth_service.dart';
import 'email_auth_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인에 실패했어요: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text('🎧', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('MUSE',
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                '친구들이 지금 무슨 노래를 듣는지\n실시간으로 함께 들어요',
                textAlign: TextAlign.center,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
              ),
              const Spacer(flex: 3),
              _LoginButton(
                label: '카카오로 시작하기',
                icon: '💬',
                background: const Color(0xFFFEE500),
                foreground: const Color(0xFF191919),
                onPressed: _busy ? null : () => _run(auth.signInWithKakao),
              ),
              const SizedBox(height: 12),
              _LoginButton(
                label: '네이버로 시작하기',
                icon: 'N',
                background: const Color(0xFF03C75A),
                foreground: Colors.white,
                onPressed: _busy ? null : () => _run(auth.signInWithNaver),
              ),
              const SizedBox(height: 12),
              _LoginButton(
                label: '이메일로 시작하기',
                icon: '✉️',
                background: const Color(0xFF2A2438),
                foreground: Colors.white,
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EmailAuthScreen()),
                        ),
              ),
              const SizedBox(height: 24),
              if (_busy) const CircularProgressIndicator(),
              const Spacer(),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('시작하면 ',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white30)),
                  _LegalLink(
                      label: '서비스 이용약관', url: LegalLinks.terms),
                  Text('과 ',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white30)),
                  _LegalLink(
                      label: '개인정보처리방침', url: LegalLinks.privacy),
                  Text('에 동의하게 돼요',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white30)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 약관/정책 문서로 이동하는 작은 링크
class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white38,
            ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: foreground)),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
