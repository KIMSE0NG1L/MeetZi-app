import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nearo_app/core/theme/app_text_styles.dart';
import 'package:nearo_app/core/theme/meetzy_design_tokens.dart';

/// last MeetZyBoard FAB "등록" (px-8 py-4, rounded-full, Plus icon).
class MeetzyPrimaryButton extends StatelessWidget {
  const MeetzyPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? Theme.of(context).colorScheme.primary;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(MeetzyDesignTokens.radiusFull),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(MeetzyDesignTokens.radiusFull),
        child: Padding(
          padding: MeetzyDesignTokens.fabPadding,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.plus, color: Colors.white, size: MeetzyDesignTokens.fabIconSize),
                    const SizedBox(width: MeetzyDesignTokens.space2),
                    Text(label, style: AppTextStyles.fab()),
                  ],
                ),
        ),
      ),
    );
  }
}
