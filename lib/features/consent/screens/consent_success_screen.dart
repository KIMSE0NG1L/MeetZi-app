import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/shared/widgets/primary_button.dart';

class ConsentSuccessScreen extends StatelessWidget {
  const ConsentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('?숈쓽 ?꾨즺'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Icon(
                LucideIcons.messageCircle,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '?쒕줈 ?숈쓽媛 ?꾨즺?먯뼱??\n移댁뭅?ㅽ넚?쇰줈 ?대룞?좉쾶??',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '?댁젣 ?듬챸 ??붽? ?꾨땲??n?ㅼ젣 ?곌껐濡??섏뼱媛묐땲??',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              PrimaryButton(
                label: '移댁뭅?ㅽ넚 ?닿린',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('移댁뭅?ㅽ넚 ?대룞? ?곕룞 ???곸슜?⑸땲??')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
