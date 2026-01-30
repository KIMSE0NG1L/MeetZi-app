import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nearo_app/features/photo/data/photo_repository.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  final _repository = PhotoRepository();
  final _photoIdController = TextEditingController();
  final _storageKeyController = TextEditingController();
  final _visibilityController = TextEditingController(text: 'PRIVATE');
  String _result = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _photoIdController.dispose();
    _storageKeyController.dispose();
    _visibilityController.dispose();
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
      appBar: AppBar(
        title: const Text('사진 API'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              TextField(
                controller: _photoIdController,
                decoration: const InputDecoration(
                  labelText: 'Photo ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _storageKeyController,
                decoration: const InputDecoration(
                  labelText: 'Storage Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _visibilityController,
                decoration: const InputDecoration(
                  labelText: 'Visibility (PUBLIC/PRIVATE)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: '내 사진 조회',
                isLoading: _isLoading,
                onPressed: () => _run(_repository.getMyPhotos),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '사진 업로드',
                isLoading: _isLoading,
                onPressed: () => _run(
                  () => _repository.uploadPhoto(
                    storageKey: _storageKeyController.text.trim(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '사진 삭제',
                isLoading: _isLoading,
                onPressed: () => _run(
                  () => _repository.deletePhoto(
                    photoId: _photoIdController.text.trim(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '공개 설정 변경',
                isLoading: _isLoading,
                onPressed: () => _run(
                  () => _repository.updateVisibility(
                    photoId: _photoIdController.text.trim(),
                    visibility: _visibilityController.text.trim(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '대표 사진 설정',
                isLoading: _isLoading,
                onPressed: () => _run(
                  () => _repository.setPrimary(
                    photoId: _photoIdController.text.trim(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _result,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
