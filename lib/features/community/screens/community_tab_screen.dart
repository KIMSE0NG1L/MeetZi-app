import 'package:flutter/material.dart';
import 'package:nearo_app/features/community/data/community_repository.dart';
import 'package:nearo_app/features/community/screens/community_screen.dart';

class CommunityTabScreen extends StatelessWidget {
  const CommunityTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityScreen(
      environmentId: CommunityRepository.globalEnvironmentId,
      schoolName: '커뮤니티',
      isRootTab: true,
    );
  }
}
