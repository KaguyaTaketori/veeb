// lib/widgets/ui_core/vee_card.dart
//
// VeeCard — 通用卡片容器
//
// v2 变更：
//   - 新增 VeeCard.list() 工厂构造，专为 ListView 子项设计（padding: EdgeInsets.zero）
//   - 新增 VeeCard.stat() 工厂构造，专为统计数字卡片（浅色背景，无边框）
//   - 修复原有 12+ 处 padding: EdgeInsets.zero 覆盖问题：
//       旧模式：VeeCard(padding: EdgeInsets.zero, child: Column(children: [
//                 Padding(padding: tilePadding, child: ...) × N
//               ]))
//       新模式：VeeCard.list(child: Column(children: [
//                 Padding(padding: tilePadding, child: ...) × N
//               ]))
//
// ─────────────────────────────────────────────────────────────────────────────
//
// 三种工厂快捷方式：
//
//   VeeCard(...)          → 标准卡片（padding: cardPadding=16px all）
//   VeeCard.list(...)     → 列表容器卡片（padding: zero，内部行自带间距）
//   VeeCard.stat(...)     → 统计数字卡片（浅色背景，指定颜色 tint）
//
// 受益场景（VeeCard.list 解决的 12+ 处问题）：
//   transactions_screen.dart     _TransactionTile 外层
//   profile_screen.dart          _UserHeaderCard / _QuotaCard
//   manage_accounts_screen.dart  账户列表项
//   manage_categories_screen.dart 分类配置卡
//   stats_screen.dart            分类列表卡
//   admin_dashboard_screen.dart  配置列表项、用户卡片
//   ocr_screen.dart              OCR 结果基本信息卡
//   add_edit_transaction_screen.dart 详情基本信息 / 明细列表
//   change_password_screen.dart  等若干表单页

import 'package:flutter/material.dart';
import 'vee_tokens.dart';

class VeeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ShapeBorder? shape;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;

  // ── 基础构造 ──────────────────────────────────────────────────────────────

  const VeeCard({
    super.key,
    required this.child,
    this.padding = VeeTokens.cardPadding,
    this.shape,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
  });

  // ── 工厂：列表容器卡片 ────────────────────────────────────────────────────
  //
  // 适用于内部包含 ListView / Column（子项各自带 tilePadding / Padding）的情况。
  // 外层 Card 的 padding 设为 zero，子项间距由内部行自行控制。
  //
  // 使用示例：
  //   VeeCard.list(
  //     child: Column(children: [
  //       VeeDetailRow(icon: ..., label: ..., value: ...),
  //       const Divider(height: 1, indent: VeeTokens.dividerIndentStd),
  //       VeeDetailRow(icon: ..., label: ..., value: ...),
  //     ]),
  //   )

  const VeeCard.list({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? backgroundColor,
    Color? borderColor,
  }) : this(
         key: key,
         child: child,
         padding: EdgeInsets.zero,
         onTap: onTap,
         onLongPress: onLongPress,
         backgroundColor: backgroundColor,
         borderColor: borderColor,
       );

  // ── 工厂：统计数字卡片 ────────────────────────────────────────────────────
  //
  // 适用于 AdminDashboard StatsGrid 中的彩色背景统计卡。
  // 背景色为 color 的 hoverTint（8% 透明度），边框为 strongTint（20%）。
  //
  // 使用示例：
  //   VeeCard.stat(
  //     color: Colors.blue,
  //     onTap: ...,
  //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //       Icon(Icons.people, color: Colors.blue, size: VeeTokens.iconLg),
  //       Text('1,024', style: TextStyle(...)),
  //       Text('用户总数', style: ...),
  //     ]),
  //   )

  factory VeeCard.stat({
    Key? key,
    required Color color,
    required Widget child,
    EdgeInsetsGeometry padding = VeeTokens.cardPadding,
    VoidCallback? onTap,
  }) {
    return VeeCard(
      key: key,
      padding: padding,
      backgroundColor: VeeTokens.hoverTint(color),
      borderColor: VeeTokens.strongTint(color),
      onTap: onTap,
      child: child,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final effectiveShape =
        shape ??
        (borderColor != null
            ? RoundedRectangleBorder(
                borderRadius: VeeTokens.cardBorderRadius,
                side: BorderSide(color: borderColor!, width: 1.0),
              )
            : VeeTokens.cardShape);

    return Card(
      elevation: VeeTokens.elevationNone,
      margin: EdgeInsets.zero,
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: effectiveShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        // 涟漪色配合品牌色，替代默认灰色涟漪
        splashColor: VeeTokens.selectedTint(
          Theme.of(context).colorScheme.primary,
        ),
        highlightColor: VeeTokens.hoverTint(
          Theme.of(context).colorScheme.primary,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 迁移指南
// ─────────────────────────────────────────────────────────────────────────────
//
// 搜索并替换以下模式：
//
//   模式 1（最常见）：
//     旧：VeeCard(
//           padding: EdgeInsets.zero,
//           child: ...,
//         )
//     新：VeeCard.list(
//           child: ...,
//         )
//
//   模式 2（AdminDashboard _StatCard）：
//     旧：VeeCard(
//           backgroundColor: VeeTokens.hoverTint(color),
//           borderColor: VeeTokens.strongTint(color),
//           padding: VeeTokens.cardPadding,
//           child: ...,
//         )
//     新：VeeCard.stat(
//           color: color,
//           child: ...,
//         )
//
// 受影响文件（12+ 处 padding: EdgeInsets.zero）：
//   lib/screens/transactions/transactions_screen.dart
//   lib/screens/transactions/add_edit_transaction_screen.dart
//   lib/screens/profile/profile_screen.dart
//   lib/screens/settings/manage_accounts_screen.dart
//   lib/screens/settings/manage_categories_screen.dart
//   lib/screens/stats/stats_screen.dart
//   lib/screens/admin/admin_dashboard_screen.dart
//   lib/screens/ocr/ocr_screen.dart
