// lib/widgets/ui_core/vee_chip.dart
//
// VeeChip — 统一筛选 Chip / 标签 Chip
//
// 替代以下散落实现：
//   - TransactionsScreen._buildTypeFilter() 的手写 GestureDetector+Container
//   - AdminDashboard._FilterChip（同名但独立实现）
//   - ManageAccountsScreen 货币/类型选择器
//   - ManageCategoriesScreen 收支类型 SegmentedButton
//
// 使用示例：
//
//   // 单选筛选栏（横向滚动）
//   SingleChildScrollView(
//     scrollDirection: Axis.horizontal,
//     child: Row(children: [
//       VeeChip(label: '全部', selected: filter == null, onTap: () => setState(() => filter = null)),
//       VeeChip(label: '支出', selected: filter == 'expense', onTap: () => ...),
//     ]),
//   )
//
//   // 带颜色强调的危险 chip（如"已封禁"标签）
//   VeeChip(label: '已封禁', selected: true, accentColor: Colors.red, onTap: ...)
//
//   // 禁用态
//   VeeChip(label: '未启用', selected: false, enabled: false, onTap: null)

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeChip extends StatelessWidget {
  final String label;
  final bool selected;

  /// 选中态的强调色，默认为 Theme.colorScheme.primary
  final Color? accentColor;

  /// 未选中态的文字色，默认 textSecondaryVal
  final Color? unselectedLabelColor;

  /// 是否可交互（false → 置灰，不响应点击）
  final bool enabled;

  final VoidCallback? onTap;

  /// 是否在标签前显示图标
  final IconData? icon;

  const VeeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentColor,
    this.unselectedLabelColor,
    this.enabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = accentColor ?? Theme.of(context).colorScheme.primary;
    final effectiveEnabled = enabled && onTap != null;

    final Color bgColor;
    final Color labelColor;
    final Color borderColor;

    if (!effectiveEnabled) {
      bgColor     = VeeTokens.surfaceSunken;
      labelColor  = VeeTokens.textDisabledVal;
      borderColor = Colors.transparent;
    } else if (selected) {
      bgColor     = VeeTokens.selectedTint(primary);
      labelColor  = primary;
      borderColor = primary;
    } else {
      bgColor     = VeeTokens.surfaceSunken;
      labelColor  = unselectedLabelColor ?? VeeTokens.textSecondaryVal;
      borderColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: effectiveEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: VeeTokens.durationFast,
        padding: VeeTokens.chipPadding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(VeeTokens.rFull),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: VeeTokens.iconXs, color: labelColor),
              const SizedBox(width: VeeTokens.spacingXxs),
            ],
            Text(
              label,
              style: context.veeText.chipLabel.copyWith(
                color: labelColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeChipGroup — 多选/单选 chip 组，自动处理间距和滚动
// ─────────────────────────────────────────────────────────────────────────────

/// 一组筛选 Chip，自动横向布局。
///
/// 使用示例（单选）：
/// ```dart
/// VeeChipGroup<String?>(
///   items: const [null, 'expense', 'income', 'transfer'],
///   labelBuilder: (v) => switch (v) {
///     'expense'  => l10n.expense,
///     'income'   => l10n.income,
///     'transfer' => l10n.transfer,
///     _          => l10n.total,
///   },
///   selected: _typeFilter,
///   onChanged: (v) {
///     setState(() => _typeFilter = v);
///     _load(refresh: true);
///   },
/// )
/// ```
class VeeChipGroup<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) labelBuilder;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color? Function(T item)? accentColorBuilder;
  final IconData? Function(T item)? iconBuilder;
  final EdgeInsets? padding;
  final bool scrollable;

  const VeeChipGroup({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.selected,
    required this.onChanged,
    this.accentColorBuilder,
    this.iconBuilder,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = items.map((item) => Padding(
      padding: const EdgeInsets.only(right: VeeTokens.spacingXs),
      child: VeeChip(
        label:       labelBuilder(item),
        selected:    item == selected,
        accentColor: accentColorBuilder?.call(item),
        icon:        iconBuilder?.call(item),
        onTap:       () => onChanged(item),
      ),
    )).toList();

    final row = Row(
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: chips,
    );

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding ?? EdgeInsets.zero,
        child: row,
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: row,
    );
  }
}