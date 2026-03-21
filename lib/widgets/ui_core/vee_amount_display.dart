// lib/widgets/ui_core/vee_amount_display.dart
//
// VeeAmountDisplay — 统一货币金额展示组件
//
// 替代以下散落的"货币代码 + 大号金额"组合：
//   - StatsScreen._buildSummaryCard() 内的 Row + 两个 Text
//   - OcrScreen._ConfirmView.build() 内的 Row + 两个 Text
//   - AddEditTransactionScreen._buildViewBody() 内的金额头部
//   - TransactionsScreen._SummaryCell（汇总卡内收/支金额）
//
// 尺寸档次（size 参数）：
//   VeeAmountSize.hero   → 首屏英雄金额（currencyCode 20sp / amount 40sp）
//   VeeAmountSize.large  → 详情页金额（currencyCode 18sp / amount 32sp）
//   VeeAmountSize.medium → 卡片汇总金额（currencyCode 14sp / amount 20sp）
//   VeeAmountSize.small  → 列表中金额（currencyCode 12sp / amount 16sp）
//
// 使用示例：
//
//   // 首屏总支出
//   VeeAmountDisplay(
//     amount: state.monthExpense,
//     currency: 'JPY',
//     size: VeeAmountSize.hero,
//   )
//
//   // 列表金额（收入绿色）
//   VeeAmountDisplay(
//     amount: txn.amount,
//     currency: txn.currencyCode,
//     size: VeeAmountSize.small,
//     color: txn.type == 'income' ? Colors.green : Colors.red,
//     prefix: txn.type == 'income' ? '+' : '-',
//   )

import 'package:flutter/material.dart';
import '../../utils/currency.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

enum VeeAmountSize { hero, large, medium, small }

class VeeAmountDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final VeeAmountSize size;

  /// 覆盖颜色（如红/绿区分支出/收入）
  final Color? color;

  /// 金额前缀（'+'/'-'/'±' 等）
  final String? prefix;

  /// 是否显示货币代码（JPY → ¥，其他 → 货币代码文字）
  /// 默认 true；设为 false 时只展示数字
  final bool showCurrency;

  /// 是否使用紧凑布局（货币代码与数字不换行，垂直基线对齐）
  /// 默认 true；false 时货币代码在数字上方展示
  final bool inline;

  const VeeAmountDisplay({
    super.key,
    required this.amount,
    required this.currency,
    this.size = VeeAmountSize.medium,
    this.color,
    this.prefix,
    this.showCurrency = true,
    this.inline = true,
  });

  /// 格式化后的数字字符串（带千分位）
  String get _formattedAmount => formatAmount(amount.abs(), currency);

  /// 货币符号展示逻辑：JPY/KRW/VND 用符号，其他用 3 字母代码
  String get _currencyLabel {
    switch (currency.toUpperCase()) {
      case 'JPY': return '¥';
      case 'CNY': return '¥';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'HKD': return 'HK\$';
      default:    return currency;
    }
  }

  String get _fullDisplayText {
    final p = prefix ?? '';
    return '$p$_currencyLabel$_formattedAmount';
  }

  _AmountSizeConfig get _sizeConfig {
    switch (size) {
      case VeeAmountSize.hero:
        return const _AmountSizeConfig(
          currencySize: 20, amountSize: 40,
          currencyWeight: FontWeight.w700, amountWeight: FontWeight.w900,
          spacing: VeeTokens.s8, height: 1.0,
        );
      case VeeAmountSize.large:
        return const _AmountSizeConfig(
          currencySize: 18, amountSize: 32,
          currencyWeight: FontWeight.w600, amountWeight: FontWeight.w800,
          spacing: VeeTokens.s6, height: 1.0,
        );
      case VeeAmountSize.medium:
        return const _AmountSizeConfig(
          currencySize: 14, amountSize: 20,
          currencyWeight: FontWeight.w600, amountWeight: FontWeight.w700,
          spacing: VeeTokens.s4, height: 1.2,
        );
      case VeeAmountSize.small:
        return const _AmountSizeConfig(
          currencySize: 12, amountSize: 16,
          currencyWeight: FontWeight.w500, amountWeight: FontWeight.w600,
          spacing: VeeTokens.s4, height: 1.3,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    final cfg = _sizeConfig;

    // ── 紧凑内联布局（货币在左，数字在右，底部对齐）──────────────────────
    if (inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showCurrency) ...[
            Text(
              _currencyLabel,
              style: TextStyle(
                fontSize: cfg.currencySize,
                fontWeight: cfg.currencyWeight,
                color: effectiveColor,
                height: 1.0,
              ),
            ),
            SizedBox(width: cfg.spacing),
          ],
          Text(
            '${prefix ?? ''}$_formattedAmount',
            style: TextStyle(
              fontSize: cfg.amountSize,
              fontWeight: cfg.amountWeight,
              color: effectiveColor,
              height: cfg.height,
            ),
          ),
        ],
      );
    }

    // ── 堆叠布局（货币在数字上方，居中对齐）─────────────────────────────
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCurrency)
          Text(
            _currencyLabel,
            style: TextStyle(
              fontSize: cfg.currencySize,
              fontWeight: cfg.currencyWeight,
              color: effectiveColor.withOpacity(0.7),
            ),
          ),
        Text(
          '${prefix ?? ''}$_formattedAmount',
          style: TextStyle(
            fontSize: cfg.amountSize,
            fontWeight: cfg.amountWeight,
            color: effectiveColor,
            height: cfg.height,
          ),
        ),
      ],
    );
  }
}

/// 尺寸配置内部数据类
class _AmountSizeConfig {
  final double currencySize;
  final double amountSize;
  final FontWeight currencyWeight;
  final FontWeight amountWeight;
  final double spacing;
  final double height;

  const _AmountSizeConfig({
    required this.currencySize,
    required this.amountSize,
    required this.currencyWeight,
    required this.amountWeight,
    required this.spacing,
    required this.height,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeSummaryRow — 收/支/净额 三列摘要行（TransactionsScreen 汇总卡专用）
// ─────────────────────────────────────────────────────────────────────────────
//
// 使用示例：
//   VeeSummaryRow(
//     expense: state.monthExpense,
//     income:  state.monthIncome,
//     currency: 'JPY',
//     count:   state.monthCount,
//   )

class VeeSummaryRow extends StatelessWidget {
  final double expense;
  final double income;
  final String currency;
  final int count;

  const VeeSummaryRow({
    super.key,
    required this.expense,
    required this.income,
    required this.currency,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final net        = income - expense;
    final isPositive = net >= 0;
    final primary    = Theme.of(context).colorScheme.primary;

    return Column(children: [
      // ── 支出/收入并排 ────────────────────────────────────────────────────
      Row(children: [
        Expanded(
          child: _SummaryCell(
            label: _labelOf(context, 'expense'),
            amount: expense,
            currency: currency,
            color: const Color(0xFFE53935), // red.shade600
          ),
        ),
        Container(width: 1, height: VeeTokens.s40, color: VeeTokens.borderColor),
        Expanded(
          child: _SummaryCell(
            label: _labelOf(context, 'income'),
            amount: income,
            currency: currency,
            color: const Color(0xFF43A047), // green.shade600
          ),
        ),
      ]),

      const Divider(height: VeeTokens.s20),

      // ── 净额行 ────────────────────────────────────────────────────────────
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_labelOf(context, 'balance')} ',
            style: context.veeText.caption.copyWith(
              color: VeeTokens.textSecondaryVal,
            ),
          ),
          VeeAmountDisplay(
            amount: net.abs(),
            currency: currency,
            size: VeeAmountSize.medium,
            prefix: isPositive ? '+' : '-',
            color: isPositive
                ? const Color(0xFF43A047)
                : const Color(0xFFE53935),
          ),
          const SizedBox(width: VeeTokens.spacingXs),
          _CountBadge(count: count, primary: primary),
        ],
      ),
    ]);
  }

  String _labelOf(BuildContext context, String key) {
    // 这里直接用汉字字面量，若需 l10n 请在调用方传入
    return switch (key) {
      'expense' => '支出',
      'income'  => '收入',
      'balance' => '结余',
      _         => '',
    };
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;

  const _SummaryCell({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(
          label,
          style: context.veeText.caption.copyWith(
            color: VeeTokens.textSecondaryVal,
          ),
        ),
        const SizedBox(height: VeeTokens.spacingXxs),
        VeeAmountDisplay(
          amount: amount,
          currency: currency,
          size: VeeAmountSize.medium,
          color: color,
        ),
      ]);
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color primary;
  const _CountBadge({required this.count, required this.primary});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VeeTokens.s8,
          vertical:   VeeTokens.s2,
        ),
        decoration: BoxDecoration(
          color: VeeTokens.selectedTint(primary),
          borderRadius: BorderRadius.circular(VeeTokens.rFull),
        ),
        child: Text(
          '$count 笔',
          style: context.veeText.micro.copyWith(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}