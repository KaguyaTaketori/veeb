// lib/widgets/ui_core/vee_category_grid.dart

import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VeeCategoryGrid — 主组件（分类列表模式）
// ─────────────────────────────────────────────────────────────────────────────

class VeeCategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int>? onSelected;
  final bool canDelete;
  final void Function(Category cat)? onDelete;
  final int crossAxisCount;
  final bool shrinkWrap;

  const VeeCategoryGrid({
    super.key,
    required this.categories,
    this.selectedId,
    this.onSelected,
    this.canDelete = false,
    this.onDelete,
    this.crossAxisCount = 4,
    this.shrinkWrap = true,
  }) : assert(
         canDelete == false || onDelete != null,
         'VeeCategoryGrid: canDelete=true requires onDelete callback',
       );

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(VeeTokens.s24),
        child: Center(
          child: Text(
            '暂无分类',
            style: context.veeText.caption.copyWith(
              color: VeeTokens.textPlaceholderVal,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: VeeTokens.s12,
        crossAxisSpacing: VeeTokens.s12,
        childAspectRatio: 0.9,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) => _CategoryCell(
        category: categories[i],
        isSelected: categories[i].id == selectedId,
        canDelete: canDelete,
        onTap: onSelected != null ? () => onSelected!(categories[i].id) : null,
        onDelete: onDelete != null ? () => onDelete!(categories[i]) : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeEmojiGrid
// ─────────────────────────────────────────────────────────────────────────────

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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: VeeTokens.spacingXs,
        crossAxisSpacing: VeeTokens.spacingXs,
        childAspectRatio: 1.0,
      ),
      itemCount: emojis.length,
      itemBuilder: (_, i) {
        final emoji = emojis[i];
        final selected = emoji == selectedEmoji;

        return GestureDetector(
          onTap: () => onSelected(emoji),
          child: AnimatedContainer(
            duration: VeeTokens.durationFast,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? VeeTokens.selectedTint(primary)
                  : VeeTokens.surfaceSunken,
              borderRadius: BorderRadius.circular(VeeTokens.rSm),
              border: Border.all(
                color: selected ? primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CategoryCell — 单个分类单元格
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCell extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final bool canDelete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _CategoryCell({
    required this.category,
    required this.isSelected,
    required this.canDelete,
    this.onTap,
    this.onDelete,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF9E9E9E);
    var clean = hex.trim().toUpperCase();
    if (clean.startsWith('#')) clean = clean.substring(1);
    if (clean.length == 3) {
      clean =
          '${clean[0]}${clean[0]}${clean[1]}${clean[1]}${clean[2]}${clean[2]}';
    }
    if (clean.length != 6) return const Color(0xFF9E9E9E);
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final color = _parseColor(category.color);

    return Stack(
      clipBehavior: Clip.none,
      // ✅ 修复：原默认 Alignment.topLeft，Column 在格子内靠左，图标视觉偏移。
      // 改为 Alignment.center 后，Column 在格子水平居中，图标和名称对齐格子中线。
      alignment: Alignment.center,
      children: [
        // ── 主体 Cell ──────────────────────────────────────────────────
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 圆形图标容器
                AnimatedContainer(
                  duration: VeeTokens.durationFast,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VeeTokens.pressedTint(color)
                        : VeeTokens.hoverTint(color),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: color, width: 2.0)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: VeeTokens.spacingXxs),

                // 分类名称
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    category.name,
                    style: context.veeText.micro.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? color : VeeTokens.textSecondaryVal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 删除角标 ────────────────────────────────────────────────────
        if (canDelete && onDelete != null)
          Positioned(
            top: -2,
            right: -2,
            child: GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: VeeTokens.error,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close,
                  size: VeeTokens.iconXs,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // ── 选中勾 ──────────────────────────────────────────────────────
        if (isSelected && !canDelete)
          Positioned(
            bottom: 14,
            right: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
