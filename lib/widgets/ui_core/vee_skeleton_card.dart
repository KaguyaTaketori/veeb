// lib/widgets/ui_core/vee_skeleton_card.dart
//
// VeeSkeletonCard — 加载骨架屏
//
// 提供三种预设变体：
//   VeeSkeletonCard.list()  → 列表行：左圆形 + 两行文字 + 右侧金额块
//   VeeSkeletonCard.card()  → 通用卡片：若干横向色块
//   VeeSkeletonCard.stat()  → 统计数字卡：图标 + 大数字 + 小标签
//
// 动画：pulse（opacity 0.4 ↔ 1.0，1.2s 循环），遵守 prefers-reduced-motion。
//
// 用法：
//   if (state.loading && state.items.isEmpty)
//     Column(children: List.generate(5, (_) => VeeSkeletonCard.list()))
//
//   if (loading) VeeSkeletonCard.stat()

import 'package:flutter/material.dart';
import 'vee_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 公共 Shimmer 基础
// ─────────────────────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // prefers-reduced-motion: 停止动画，仅显示静态占位色
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return widget.child;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_anim),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 色块构建辅助
// ─────────────────────────────────────────────────────────────────────────────

class _Block extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _Block({
    required this.width,
    required this.height,
    this.borderRadius = VeeTokens.rSm,
  });

  const _Block.round(double size, {super.key})
    : width = size,
      height = size,
      borderRadius = size / 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2E2E) : VeeTokens.surfaceSunken,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeSkeletonCard
// ─────────────────────────────────────────────────────────────────────────────

class VeeSkeletonCard extends StatelessWidget {
  final _Variant _variant;

  const VeeSkeletonCard._({required _Variant variant}) : _variant = variant;

  // ── 工厂构造 ────────────────────────────────────────────────────────────

  /// 列表行变体：左圆形头像 + 两行文字 + 右侧金额块
  factory VeeSkeletonCard.list() =>
      const VeeSkeletonCard._(variant: _Variant.list);

  /// 通用卡片变体：三行横向色块，高度随内容估算
  factory VeeSkeletonCard.card({int lines = 3}) =>
      VeeSkeletonCard._(variant: _Variant.card);

  /// 统计数字变体：图标块 + 大数字块 + 小标签块
  factory VeeSkeletonCard.stat() =>
      const VeeSkeletonCard._(variant: _Variant.stat);

  @override
  Widget build(BuildContext context) {
    return _Shimmer(child: _buildInner(context));
  }

  Widget _buildInner(BuildContext context) {
    return switch (_variant) {
      _Variant.list => _buildList(context),
      _Variant.card => _buildCard(context),
      _Variant.stat => _buildStat(context),
    };
  }

  // ── list ──────────────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VeeTokens.s16,
        vertical: VeeTokens.spacingXxs,
      ),
      child: Container(
        padding: VeeTokens.tilePadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: VeeTokens.cardBorderRadius,
          border: Border.all(color: VeeTokens.borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            // 圆形头像占位
            const _Block.round(VeeTokens.touchMin),
            const SizedBox(width: VeeTokens.spacingSm),

            // 两行文字占位
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Block(
                    width: double.infinity,
                    height: 13,
                    borderRadius: VeeTokens.rXs,
                  ),
                  const SizedBox(height: VeeTokens.spacingXxs),
                  _Block(width: 100, height: 10, borderRadius: VeeTokens.rXs),
                ],
              ),
            ),

            const SizedBox(width: VeeTokens.spacingMd),

            // 右侧金额占位
            _Block(width: 64, height: 16, borderRadius: VeeTokens.rXs),
          ],
        ),
      ),
    );
  }

  // ── card ──────────────────────────────────────────────────────────────────

  Widget _buildCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VeeTokens.s16,
        vertical: VeeTokens.spacingXxs,
      ),
      child: Container(
        padding: VeeTokens.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: VeeTokens.cardBorderRadius,
          border: Border.all(color: VeeTokens.borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Block(
              width: double.infinity,
              height: 14,
              borderRadius: VeeTokens.rXs,
            ),
            const SizedBox(height: VeeTokens.spacingXs),
            _Block(
              width: double.infinity,
              height: 12,
              borderRadius: VeeTokens.rXs,
            ),
            const SizedBox(height: VeeTokens.spacingXxs),
            _Block(width: 160, height: 12, borderRadius: VeeTokens.rXs),
          ],
        ),
      ),
    );
  }

  // ── stat ──────────────────────────────────────────────────────────────────

  Widget _buildStat(BuildContext context) {
    return Container(
      padding: VeeTokens.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: VeeTokens.cardBorderRadius,
        border: Border.all(color: VeeTokens.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 图标占位
          const _Block.round(VeeTokens.iconLg),
          const SizedBox(height: VeeTokens.spacingXs),
          // 大数字占位
          _Block(width: 80, height: 22, borderRadius: VeeTokens.rXs),
          const SizedBox(height: VeeTokens.spacingXxs),
          // 标签占位
          _Block(width: 56, height: 10, borderRadius: VeeTokens.rXs),
        ],
      ),
    );
  }
}

enum _Variant { list, card, stat }
