import 'package:flutter/material.dart';

/// 데이터 로딩 실패 시 보여주는 공통 위젯.
/// 무한 로딩 스피너 대신 원인과 재시도 버튼을 제공한다.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.onRetry,
    this.message,
    this.compact = false,
  });

  final VoidCallback onRetry;
  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 24 : 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😵‍💫', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 10),
            Text(
              message ?? '불러오지 못했어요',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            const Text(
              '네트워크 연결을 확인해 주세요',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
