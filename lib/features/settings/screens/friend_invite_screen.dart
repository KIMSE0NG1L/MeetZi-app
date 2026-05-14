import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/features/settings/screens/widgets/friend_invite_widget.dart';

/// 친구초대 전용 화면
class FriendInviteScreen extends StatelessWidget {
  const FriendInviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFFF4F7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFFFF4D94)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '친구초대',
          style: TextStyle(
            color: Color(0xFFFF4D94),
            fontWeight: FontWeight.bold,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFFFECF3), height: 1),
        ),
      ),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: FriendInviteWidget(),
      ),
    );
  }
}
