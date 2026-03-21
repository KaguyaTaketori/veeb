// lib/widgets/ui_core/vee_picker_row.dart
//
// VeePickerRow — 统一"图标 + 标签 + 值 + 箭头"可点击选择行
//
// 与 VeeFormRow 的分工：
//   VeeFormRow   → 内嵌可输入 Widget（TextFormField / DropdownButtonFormField）
//   VeePickerRow → 整行可点击，展示当前选中值，点击后由调用方触发选择逻辑
//                  (如 showDatePicker / showModalBottomSheet / Navigator.push)
//
// 从以下散落实现中提取：
//   - AddEditTransactionScreen 日期行（InkWell + VeeFormRow + Row）
//   - 未来可替换账户选择行（如需要底部弹窗选择而非 DropdownButton）
//
// ─────────────────────────────────────────────────────────────────────────────
//
// 设计规范：
//   - 布局：[icon 20px] [gap 12px] [label 固定宽] [value Expanded 右对齐] [chevron]
//   - 整行 InkWell，splashColor = selectedTint(primary)
//   - value 文字：bodyDefault，右对齐，最多1行截断
//   - chevron：iconMd=20px，textPlaceholderVal 色
//   - disabled 态：整行 opacity 0.45，不响应点击
//
// 用法示例：
//
//   // 日期选择行
//   VeePickerRow(
//     icon:       Icons.calendar_today_outlined,
//     label:      l10n.date,
//     value:      '2025/03/15',
//     onTap:      _pickDate,
//   )
//
//   // 账户选择行（底部弹窗模式）
//   VeePickerRow(
//     icon:       Icons.account_balance_wallet_outlined,
//     label:      l10n.account,
//     value:      selectedAccount?.name ?? l10n.pleaseSelect,
//     isPlaceholder: selectedAccount == null,
//     onTap:      () => _showAccountPicker(context),
//   )
//
//   // 禁用态
//   VeePickerRow(
//     icon:    Icons.transfer_within_a_station_outlined,
//     label:   l10n.to,
//     value:   l10n.notApplicable,
//     enabled: false,
//     onTap:   null,
//   )

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeePickerRow extends StatelessWidget {
  final IconData icon;
  final String label;

  /// 当前选中值的展示文字
  final String value;

  /// 值为空/未选时传 true，文字会用 placeholder 色显示
  final bool isPlaceholder;

  /// 标签列固定宽度，默认 64px
  final double labelWidth;

  /// 是否可交互，false 时整行半透明且不响应点击
  final bool enabled;

  /// 点击回调（整行 InkWell）
  final VoidCallback? onTap;

  /// 是否显示右侧 chevron_right 箭头，默认 true
  final bool showChevron;

  const VeePickerRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
    this.labelWidth = 64.0,
    this.enabled = true,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final valueStyle = context.veeText.bodyDefault.copyWith(
      color: isPlaceholder
          ? VeeTokens.textPlaceholderVal
          : VeeTokens.textPrimaryVal,
    );

    Widget row = Padding(
      padding: VeeTokens.tilePadding,
      child: Row(
        children: [
          // ── 图标 ──────────────────────────────────────────────────────────
          Icon(icon, size: VeeTokens.iconMd, color: VeeTokens.textSecondaryVal),
          const SizedBox(width: VeeTokens.s12),

          // ── 标签（固定宽度）────────────────────────────────────────────────
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
          ),

          // ── 值（自适应宽度，右对齐）────────────────────────────────────────
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Chevron ──────────────────────────────────────────────────────
          if (showChevron && onTap != null) ...[
            const SizedBox(width: VeeTokens.spacingXxs),
            Icon(
              Icons.chevron_right,
              color: VeeTokens.textPlaceholderVal,
              size: VeeTokens.iconMd,
            ),
          ],
        ],
      ),
    );

    // InkWell 包裹（仅在 enabled 且有回调时）
    if (enabled && onTap != null) {
      row = InkWell(
        onTap: onTap,
        splashColor: VeeTokens.selectedTint(primary),
        highlightColor: VeeTokens.hoverTint(primary),
        child: row,
      );
    }

    // 禁用态：半透明
    if (!enabled) {
      row = Opacity(opacity: 0.45, child: row);
    }

    return row;
  }
}
