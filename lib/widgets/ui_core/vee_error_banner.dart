import 'package:flutter/material.dart';
import 'vee_tokens.dart';

class VeeErrorBanner extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry margin;

  const VeeErrorBanner({
    super.key,
    required this.message,
    this.margin = const EdgeInsets.only(bottom: VeeTokens.s16),
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(VeeTokens.s12),
      decoration: BoxDecoration(
        color: VeeTokens.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(VeeTokens.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Icon(Icons.error_outline, size: 18, color: VeeTokens.error),
          const SizedBox(width: VeeTokens.s8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: VeeTokens.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}