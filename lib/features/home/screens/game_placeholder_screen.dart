import 'package:flutter/material.dart';

/// 바텀 탭 "게임" 전용 플레이스홀더. 기능 미구현.
class GamePlaceholderScreen extends StatelessWidget {
  const GamePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '게임',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
