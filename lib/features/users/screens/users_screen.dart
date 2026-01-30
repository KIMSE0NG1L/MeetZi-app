import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/features/users/data/users_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _repository = UsersRepository();
  final _nicknameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _genderController = TextEditingController(text: 'MALE');
  final _baseTypeController = TextEditingController(text: 'default');
  final _matchIdController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthYearController.dispose();
    _genderController.dispose();
    _baseTypeController.dispose();
    _matchIdController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<dynamic> Function() task) async {
    setState(() => _isLoading = true);
    try {
      final response = await task();
      setState(() => _result = response.toString());
    } on DioException catch (error) {
      setState(
        () => _result = error.response?.data.toString() ?? '요청 실패',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('유저 API')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '출생년도',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _genderController,
                decoration: const InputDecoration(
                  labelText: '성별 (MALE/FEMALE)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _baseTypeController,
                decoration: const InputDecoration(
                  labelText: '베이스 타입',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '프로필 생성',
                isLoading: _isLoading,
                onPressed: () => _run(
                  () => _repository.createProfile(
                    nickname: _nicknameController.text.trim(),
                    gender: _genderController.text.trim(),
                    birthYear: int.tryParse(_birthYearController.text.trim()) ?? 0,
                    baseType: _baseTypeController.text.trim(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _matchIdController,
                decoration: const InputDecoration(
                  labelText: '매칭 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '상대 프로필 조회',
                isLoading: _isLoading,
                onPressed: () => _run(
                  () => _repository.getPartnerProfile(
                    matchId: _matchIdController.text.trim(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_result, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
