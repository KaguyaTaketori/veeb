import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/currency.dart';
import 'ui_core/vee_tokens.dart';

class TransactionItemRow extends StatelessWidget {
  final String name;
  final double amount;
  final String itemType; // 'item' | 'discount' | 'tax'
  final double quantity;
  final String currency;

  const TransactionItemRow({
    super.key,
    required this.name,
    required this.amount,
    this.itemType = 'item',
    this.quantity = 1.0,
    this.currency = 'JPY',
  });

  /// 从 TransactionItem 模型快速构建
  factory TransactionItemRow.fromModel(
    TransactionItem item, {
    String currency = 'JPY',
  }) => TransactionItemRow(
    name: item.name,
    amount: item.amount,
    itemType: item.itemType,
    quantity: item.quantity,
    currency: currency,
  );

  @override
  Widget build(BuildContext context) {
    final isDiscount = itemType == 'discount';
    final isTax = itemType == 'tax';

    final amountStr = formatAmount(amount.abs(), currency);
    final currencySymbol = currency == 'JPY' ? '¥' : '$currency ';

    final Color textColor;
    if (isDiscount) {
      textColor = VeeTokens.error;
    } else if (isTax) {
      textColor = VeeTokens.textSecondaryVal;
    } else {
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    // 数量展示：整数去掉小数点，非整数保留一位小数
    final String qtyLabel;
    if (quantity == quantity.roundToDouble()) {
      qtyLabel = '×${quantity.toInt()}';
    } else {
      qtyLabel = '×${quantity.toStringAsFixed(1)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VeeTokens.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 类型图标 ─────────────────────────────────────────────────
          SizedBox(
            width: VeeTokens.s16,
            child: Text(
              isDiscount
                  ? '➖'
                  : isTax
                  ? '🧾'
                  : '•',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: VeeTokens.s8),

          // ── 商品名称 ─────────────────────────────────────────────────
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 13, color: textColor, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── 数量（≠1 时显示）──────────────────────────────────────────
          if (quantity != 1.0) ...[
            const SizedBox(width: VeeTokens.s4),
            Text(
              '$qtyLabel  ',
              style: TextStyle(fontSize: 12, color: VeeTokens.textSecondaryVal),
            ),
          ],

          // ── 金额 ─────────────────────────────────────────────────────
          Text(
            isDiscount
                ? '-$currencySymbol$amountStr'
                : '$currencySymbol$amountStr',
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
