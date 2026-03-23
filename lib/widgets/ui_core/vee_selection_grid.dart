// lib/widgets/ui_core/vee_selection_grid.dart
//
// VeeSelectionGrid<T> — 通用选择网格组件
//
// 合并并替代以下两个文件：
//   - vee_color_grid.dart   (VeeColorGrid)
//   - vee_category_grid.dart 内的 VeeEmojiGrid
//
// ─────────────────────────────────────────────────────────────────────────────
//
// 架构分层：
//
//   VeeSelectionGrid<T>          ← 通用核心：GridView + GestureDetector
//     └── cellBuilder(item, isSelected)  ← 调用方自定义单元格渲染
//
//   VeeColorGrid                 ← 薄封装：颜色圆形色块（替代 vee_color_grid.dart）
//   VeeEmojiGrid                 ← 薄封装：Emoji 方块（替代 vee_category_grid.dart 内同名类）
//
//   _ColorCell                   ← VeeColorGrid 专用单元格（私有）
//   _EmojiCell                   ← VeeEmojiGrid 专用单元格（私有）
//
// ─────────────────────────────────────────────────────────────────────────────
//
// VeeColorGrid 迁移说明：
//   原实现用 Wrap 布局，现改为 GridView + SliverGridDelegateWithMaxCrossAxisExtent。
//   maxCrossAxisExtent = size + spacing，效果与 Wrap 等价，视觉无差异。
//
// VeeEmojiGrid 迁移说明：
//   原定义在 vee_category_grid.dart，现迁移至本文件。
//   vee_category_grid.dart 只保留 VeeCategoryGrid 和 _CategoryCell。
//
// ─────────────────────────────────────────────────────────────────────────────
//
// 调用示例（与原版 API 完全兼容）：
//
//   // 颜色选择器（等价于旧 VeeColorGrid）
//   VeeColorGrid(
//     colors:     _colors,
//     selected:   _color,
//     onSelected: (hex) => setState(() => _color = hex),
//   )
//
//   // Emoji 选择器（等价于旧 VeeEmojiGrid）
//   VeeEmojiGrid(
//     emojis:        _emojis,
//     selectedEmoji: _icon,
//     onSelected:    (e) => setState(() => _icon = e),
//     crossAxisCount: 6,
//   )
//
//   // 完全自定义单元格（直接使用 VeeSelectionGrid<T>）
//   VeeSelectionGrid<MyItem>(
//     items:       myList,
//     selected:    currentItem,
//     onSelected:  (item) => setState(() => currentItem = item),
//     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//       crossAxisCount: 4,
//       mainAxisSpacing: 8,
//       crossAxisSpacing: 8,
//     ),
//     cellBuilder: (item, isSelected) => MyCustomCell(item: item, selected: isSelected),
//   )
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../utils/vee_colors.dart';
import 'vee_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VeeSelectionGrid<T>  —  通用核心
// ─────────────────────────────────────────────────────────────────────────────

class VeeSelectionGrid<T> extends StatelessWidget {
  /// 数据列表
  final List<T> items;

  /// 当前选中项（通过 == 判断）
  final T? selected;

  /// 选中回调
  final ValueChanged<T> onSelected;

  /// 单元格渲染，由调用方自定义。
  /// [item]       当前数据项
  /// [isSelected] 是否选中
  final Widget Function(T item, bool isSelected) cellBuilder;

  /// GridView 的布局策略，由 VeeColorGrid / VeeEmojiGrid 各自传入
  final SliverGridDelegate gridDelegate;

  /// 是否收缩至内容高度（嵌入 ListView / Column 时需要 true）
  final bool shrinkWrap;

  const VeeSelectionGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.cellBuilder,
    required this.gridDelegate,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: gridDelegate,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onSelected(item),
          child: cellBuilder(item, isSelected),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeColorGrid  —  颜色圆形色块选择器
// ─────────────────────────────────────────────────────────────────────────────

/// 颜色选择器网格，从以下迁移而来：
///   lib/widgets/ui_core/vee_color_grid.dart → 可删除该文件
///
/// 参数 API 与原版完全一致，布局由 Wrap 改为 GridView（等价效果）。

class VeeColorGrid extends StatelessWidget {
  /// 颜色列表，后端 hex 格式，如 ['#E85D30', '#3B8BD4', ...]
  final List<String> colors;

  /// 当前选中的 hex 字符串，需与 [colors] 中的值完全一致
  final String? selected;

  /// 选中颜色时的回调，传入被点击的 hex 字符串
  final ValueChanged<String> onSelected;

  /// 色块直径，默认 36px
  final double size;

  /// 主轴间距，默认 spacingXs (8px)
  final double spacing;

  /// 交叉轴间距，默认 spacingXs (8px)
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
    // SliverGridDelegateWithMaxCrossAxisExtent 等价于原 Wrap 的 size-based 布局：
    // maxCrossAxisExtent = size + spacing → 每个格子占用的最大宽度 = 色块 + 一个间距
    return VeeSelectionGrid<String>(
      items: colors,
      selected: selected,
      onSelected: onSelected,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: size + spacing,
        mainAxisSpacing: runSpacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      cellBuilder: (hex, isSelected) =>
          _ColorCell(hex: hex, size: size, isSelected: isSelected),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ColorCell  —  单个颜色圆形色块（私有）
// ─────────────────────────────────────────────────────────────────────────────

class _ColorCell extends StatelessWidget {
  final String hex;
  final double size;
  final bool isSelected;

  const _ColorCell({
    required this.hex,
    required this.size,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = VeeColors.fromHex(hex);

    return AnimatedContainer(
      duration: VeeTokens.durationFast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // 选中时：白色边框 + 投影（与原版一致）
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
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
          ? const Icon(Icons.check, color: Colors.white, size: VeeTokens.iconSm)
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeEmojiGrid  —  Emoji 方块选择器
// ─────────────────────────────────────────────────────────────────────────────

/// Emoji 选择器网格，从以下迁移而来：
///   lib/widgets/ui_core/vee_category_grid.dart 内的 VeeEmojiGrid → 删除原定义
///
/// 参数 API 与原版完全一致。

class VeeEmojiGrid extends StatelessWidget {
  final List<String> emojis;
  final String? selectedEmoji;
  final ValueChanged<String> onSelected;
  final int crossAxisCount;

  const VeeEmojiGrid({
    super.key,
    required this.emojis,
    required this.selectedEmoji,
    required this.onSelected,
    this.crossAxisCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return VeeSelectionGrid<String>(
      items: emojis,
      selected: selectedEmoji,
      onSelected: onSelected,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: VeeTokens.spacingXs,
        crossAxisSpacing: VeeTokens.spacingXs,
        childAspectRatio: 1.0,
      ),
      cellBuilder: (emoji, isSelected) =>
          _EmojiCell(emoji: emoji, isSelected: isSelected, primary: primary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmojiCell  —  单个 Emoji 方块（私有）
// ─────────────────────────────────────────────────────────────────────────────

class _EmojiCell extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final Color primary;

  const _EmojiCell({
    required this.emoji,
    required this.isSelected,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: VeeTokens.durationFast,
      decoration: BoxDecoration(
        color: isSelected
            ? VeeTokens.selectedTint(primary)
            : VeeTokens.surfaceSunken,
        borderRadius: BorderRadius.circular(VeeTokens.rSm),
        border: Border.all(
          color: isSelected ? primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}
