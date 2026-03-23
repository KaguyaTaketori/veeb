import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

enum _VeeRowVariant { display, form }

class VeeRow extends StatelessWidget {
  // ── 共享字段 ────────────────────────────────────────────────────────────────

  /// 左侧图标，null 时省略图标列（labelWidth 从左边缘起算）
  final IconData? icon;

  /// 固定宽度的标签文字
  final String label;

  /// 标签列固定宽度，默认 64px
  /// 旧代码中 VeeDetailRow 默认 70、VeeListTile 默认 72，
  /// 统一为 64 视觉差异极小；如需精确对齐可显式传入
  final double labelWidth;

  final _VeeRowVariant _variant;

  // ── display 专用字段 ────────────────────────────────────────────────────────

  /// 右侧展示文字（display 变体）
  final String? value;

  /// 替换右侧文字的自定义 Widget（如 Switch、Badge 组合）
  /// 传入后 chevron 自动隐藏
  final Widget? customTrailing;

  /// 整行点击回调；非 null 时自动添加 InkWell
  final VoidCallback? onTap;

  /// 是否在右侧显示 chevron_right，默认 true
  /// 仅 onTap != null 且 customTrailing == null 时生效
  final bool showChevron;

  /// value 是占位文字（如"请选择"），显示为 textPlaceholderVal 灰色
  final bool isPlaceholder;

  /// false 时整行半透明且不响应点击（原 VeePickerRow.enabled）
  final bool enabled;

  /// 覆盖 value 文字颜色（原 VeeDetailRow.valueColor）
  final Color? valueColor;

  /// 覆盖 value 文字字重，默认 w500（原 VeeDetailRow.valueWeight）
  final FontWeight valueWeight;

  // ── form 专用字段 ───────────────────────────────────────────────────────────

  /// 右侧可交互 Widget（TextFormField / DropdownButtonFormField 等）
  final Widget? child;

  // ── 展示行构造（替代 VeeDetailRow + VeePickerRow + VeeListTile）─────────────

  const VeeRow.display({
    super.key,
    this.icon,
    required this.label,
    this.value,
    this.customTrailing,
    this.onTap,
    this.showChevron = true,
    this.isPlaceholder = false,
    this.enabled = true,
    this.labelWidth = 64.0,
    this.valueColor,
    this.valueWeight = FontWeight.w500,
  }) : _variant = _VeeRowVariant.display,
       child = null;

  // ── 表单行构造（替代 VeeFormRow）────────────────────────────────────────────

  const VeeRow.form({
    super.key,
    this.icon,
    required this.label,
    required Widget this.child,
    this.labelWidth = 64.0,
  }) : _variant = _VeeRowVariant.form,
       value = null,
       customTrailing = null,
       onTap = null,
       showChevron = false,
       isPlaceholder = false,
       enabled = true,
       valueColor = null,
       valueWeight = FontWeight.w500;

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget inner = Padding(
      padding: VeeTokens.tilePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _buildRowChildren(context),
      ),
    );

    // display 变体：可点击 + 可禁用
    if (_variant == _VeeRowVariant.display) {
      if (onTap != null) {
        final primary = Theme.of(context).colorScheme.primary;
        inner = InkWell(
          onTap: onTap,
          splashColor: VeeTokens.selectedTint(primary),
          highlightColor: VeeTokens.hoverTint(primary),
          child: inner,
        );
      }
      if (!enabled) {
        inner = Opacity(opacity: 0.45, child: inner);
      }
    }

    return inner;
  }

  List<Widget> _buildRowChildren(BuildContext context) {
    return [
      // ── 左侧图标（可选）────────────────────────────────────────────────────
      if (icon != null) ...[
        Icon(icon, size: VeeTokens.iconMd, color: VeeTokens.textSecondaryVal),
        const SizedBox(width: VeeTokens.s12),
      ],

      // ── 固定宽度标签 ────────────────────────────────────────────────────────
      SizedBox(
        width: labelWidth,
        child: Text(
          label,
          style: context.veeText.caption.copyWith(
            color: VeeTokens.textSecondaryVal,
          ),
        ),
      ),

      // ── 右侧内容区 ──────────────────────────────────────────────────────────
      if (_variant == _VeeRowVariant.form)
        Expanded(child: child!)
      else ...[
        Expanded(
          child:
              customTrailing ??
              Text(
                value ?? '',
                style: context.veeText.bodyDefault.copyWith(
                  fontWeight: valueWeight,
                  color: isPlaceholder
                      ? VeeTokens.textPlaceholderVal
                      : (valueColor ?? VeeTokens.textPrimaryVal),
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        ),

        if (onTap != null && showChevron && customTrailing == null) ...[
          const SizedBox(width: VeeTokens.spacingXxs),
          const Icon(
            Icons.chevron_right,
            color: VeeTokens.textPlaceholderVal,
            size: VeeTokens.iconMd,
          ),
        ],
      ],
    ];
  }
}
