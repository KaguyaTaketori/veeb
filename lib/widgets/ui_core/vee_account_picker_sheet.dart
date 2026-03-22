import 'package:flutter/material.dart';
import 'package:vee_app/widgets/ui_core/vee_tokens.dart';

class AccountPickerSheet extends StatelessWidget {
  final List<dynamic> accounts;
  const AccountPickerSheet({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: VeeTokens.s12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: VeeTokens.borderColor,
            borderRadius: BorderRadius.circular(VeeTokens.s2),
          ),
        ),
        const SizedBox(height: VeeTokens.spacingMd),
        ...accounts.map(
          (a) => ListTile(
            leading: Text(
              a.typeIcon as String,
              style: const TextStyle(fontSize: VeeTokens.iconLg),
            ),
            title: Text(a.name as String),
            subtitle: Text(
              '${a.typeLabel}  ·  ${a.currencyCode}',
              style: TextStyle(fontSize: 12, color: VeeTokens.textSecondaryVal),
            ),
            onTap: () => Navigator.pop(context, a.id as int),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).padding.bottom + VeeTokens.spacingMd,
        ),
      ],
    );
  }
}
