// lib/widgets/ui_core/vee_color_grid.dart
//
// VeeColorGrid — 颜色选择器网格
//
// 从以下两处相同的手写 Wrap 实现中提取：
//   - lib/screens/settings/manage_categories_screen.dart  (_AddCategorySheet)
//   - lib/screens/settings/manage_accounts_screen.dart    (_AddAccountSheet)
//
// ─────────────────────────────────────────────────────────────────────────────
//
// 设计规范：
//   - 每个色块：36×36 圆形，选中时加白色 2px border + overlayTint boxShadow
//   - 选中状态：白色 check icon（iconSm=16px），已通过 VeeColors.contrastForeground 验证
//   - 未选中：无 border，无阴影
//   - 间距：Wrap spacing/runSpacing = spacingXs=8px
//   - 整体无内边距，由调用方控制外部间距
//
// 用法示例：
//
//   VeeColorGrid(
//     colors:   _colors,          // List<String>，后端 hex 格式如 '#E85D30'
//     selected: _color,           // 当前选中的 hex 字符串
//     onSelected: (hex) => setState(() => _color = hex),
//   )
//
// 若需要自定义色块大小（如紧凑模式）：
//
//   VeeColorGrid(
//     colors: _colors,
//     selected: _color,
//     onSelected: (hex) => setState(() => _color = hex),
//     size: 28,
//   )

import 'package:flutter/material.dart';
import '../../utils/vee_colors.dart';
import 'vee_tokens.dart';

class VeeColorGrid extends StatelessWidget {
  /// 颜色列表，后端 hex 格式，如 ['#E85D30', '#3B8BD4', ...]
  final List<String> colors;

  /// 当前选中的 hex 字符串，需与 [colors] 中的值完全一致
  final String? selected;

  /// 选中颜色时的回调，传入被点击的 hex 字符串
  final ValueChanged<String> onSelected;

  /// 色块直径，默认 36px
  final double size;

  /// Wrap 的主轴间距，默认 spacingXs=8px
  final double spacing;

  /// Wrap 的交叉轴间距，默认 spacingXs=8px
  final double runSpacing;

  const VeeColorGrid({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
    this.size = 36,
    this.spacing = VeeTokens.spacingXs,
    this.runSpacing = VeeTokens.spacingXs,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: colors.map((hex) {
        final color = VeeColors.fromHex(hex);
        final isSelected = selected == hex;

        return GestureDetector(
          onTap: () => onSelected(hex),
          child: AnimatedContainer(
            duration: VeeTokens.durationFast,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: VeeTokens.overlayTint(color),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: VeeTokens.iconSm,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
