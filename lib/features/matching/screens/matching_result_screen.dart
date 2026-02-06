import 'package:flutter/material.dart';
import 'package:nearo_app/app/app_routes.dart';
import 'package:nearo_app/features/matching/data/matching_repository.dart';
import 'package:nearo_app/features/messages/data/chat_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class MatchingResultScreen extends StatefulWidget {
  const MatchingResultScreen({super.key});

  @override
  State<MatchingResultScreen> createState() => _MatchingResultScreenState();
}

class _MatchingResultScreenState extends State<MatchingResultScreen> {
  final _matchingRepository = MatchingRepository();
  final _chatRepository = ChatRepository();
  bool _isLoading = false;

  Future<void> _openChatRoom() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final active = await _matchingRepository.getActiveMatch();
      final matchId = active['matchId']?.toString();
      if (matchId == null || matchId.isEmpty) {
        throw Exception('matchId가 없습니다.');
      }

      final room = await _chatRepository.createRoom(matchId: matchId);
      if (!mounted) return;

      Navigator.of(context).pushNamed(
        AppRoutes.chatRoom,
        arguments: {
          'roomId': room['roomId']?.toString(),
          'partnerNickname': room['partnerNickname']?.toString(),
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 생성 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 완료'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.favorite,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '매칭이 성사됐어요!\n익명 대화로 먼저 연결돼요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '상호 동의 전까지는\n프로필 사진이 공개되지 않아요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              PrimaryButton(
                label: '대화방으로 이동',
                isLoading: _isLoading,
                onPressed: _openChatRoom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
