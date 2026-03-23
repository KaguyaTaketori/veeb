import 'package:flutter/material.dart';
import '../../../widgets/ui_core/vee_tokens.dart';

/// 支持的货币列表（与原版一致）
const _kCurrencies = ['JPY', 'CNY', 'USD', 'EUR', 'HKD'];

class TransactionAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;

  /// 是否自动聚焦金额输入框；新建 Sheet 传 true，编辑 Screen 传 false
  final bool autofocus;

  /// 金额变更时触发（用于父级 setState 刷新"保存"按钮可用性）
  final VoidCallback? onAmountChanged;

  const TransactionAmountInput({
    super.key,
    required this.controller,
    required this.currencyCode,
    required this.onCurrencyChanged,
    this.autofocus = false,
    this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── 货币下拉 ────────────────────────────────────────────────────
        DropdownButton<String>(
          value: currencyCode,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down, size: VeeTokens.iconSm),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: _kCurrencies
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) onCurrencyChanged(v);
          },
        ),
        const SizedBox(width: VeeTokens.spacingXs),

        // ── 金额输入（自适应宽度）────────────────────────────────────────
        IntrinsicWidth(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            autofocus: autofocus,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            onChanged: (_) => onAmountChanged?.call(),
          ),
        ),
      ],
    );
  }
}
