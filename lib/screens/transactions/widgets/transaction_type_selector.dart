import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/ui_core/vee_tokens.dart';
import '../../../widgets/ui_core/vee_text_styles.dart';

class TransactionTypeSelector extends StatelessWidget {
  /// 当前选中的类型：'expense' | 'income' | 'transfer'
  final String currentType;

  /// 类型变更回调；副作用（清空 payee、重置 categoryId）由父级处理
  final ValueChanged<String> onTypeChanged;

  const TransactionTypeSelector({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final types = [
      ('expense', l10n.expense, VeeTokens.error),
      ('income', l10n.income, VeeTokens.success),
      ('transfer', l10n.transfer, VeeTokens.info),
    ];

    return Row(
      children: types.map((t) {
        final (value, label, color) = t;
        final selected = currentType == value;

        return Expanded(
          child: GestureDetector(
            onTap: () => onTypeChanged(value),
            child: AnimatedContainer(
              duration: VeeTokens.durationFast,
              margin: const EdgeInsets.symmetric(
                horizontal: VeeTokens.spacingXxs,
              ),
              padding: const EdgeInsets.symmetric(vertical: VeeTokens.s10),
              decoration: BoxDecoration(
                color: selected
                    ? VeeTokens.selectedTint(color)
                    : VeeTokens.surfaceSunken,
                borderRadius: BorderRadius.circular(VeeTokens.rMd),
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: context.veeText.chipLabel.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? color : VeeTokens.textSecondaryVal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
