import 'package:flutter/material.dart';
import 'vee_tokens.dart';

class VeeEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const VeeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VeeTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: VeeTokens.s16),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VeeTokens.textSecondary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: VeeTokens.s8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: VeeTokens.textPlaceholder),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: VeeTokens.s24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ]
          ],
        ),
      ),
    );
  }
}