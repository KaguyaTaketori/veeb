// lib/widgets/ui_core/vee_text_styles.dart
//
// Vee 文字样式系统
//
// 使用方式：
//   1. 在 VeeApp._buildTheme() 中调用 VeeTextStyles.buildTextTheme() 注入全局
//   2. 在组件中通过 Theme.of(context).textTheme.xxx 访问（不要硬编码 fontSize）
//   3. 使用语义扩展 context.veeText.xxx 获得更具可读性的访问方式
//
// 字号层级（针对中文/日文阅读优化，行高 ≥ 1.5）：
//
//   displaySmall  40sp  → 金额主数字（如首屏总支出）
//   headlineSmall 24sp  → 页面大标题、Modal 主标题
//   titleLarge    20sp  → AppBar 标题（由 AppBarTheme 引用）
//   titleMedium   16sp  → 卡片主标题、重要列表项主文字
//   titleSmall    14sp  → 区块副标题、次要卡片标题
//   bodyLarge     16sp  → 大号正文（说明段落）
//   bodyMedium    14sp  → 默认正文（列表描述、表单说明）
//   bodySmall     12sp  → 辅助信息（日期、计数、元数据）
//   labelLarge    15sp  → 按钮文字（FilledButton / OutlinedButton）
//   labelMedium   13sp  → Chip 文字、Tab 标签、小标记
//   labelSmall    11sp  → Badge 文字、角标、极小辅助信息

import 'package:flutter/material.dart';

class VeeTextStyles {
  VeeTextStyles._();

  /// 构建完整的 TextTheme，在 ThemeData 中注入
  static TextTheme buildTextTheme() {
    return const TextTheme(
      // ── Display ─────────────────────────────────────────────────────────
      // 仅用于超大数字（金额主视觉），不用于普通文字内容
      displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -1.0),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -0.5),
      displaySmall:  TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -0.5),

      // ── Headline ─────────────────────────────────────────────────────────
      // 用于页面级标题、Modal 大标题、区块主标题
      headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
      headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),

      // ── Title ─────────────────────────────────────────────────────────────
      // titleLarge  → AppBar 标题（由全局 AppBarTheme 引用）
      // titleMedium → 卡片主标题、商家名、列表主文字
      // titleSmall  → 区块副标题、次要信息标题
      titleLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
      titleSmall:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),

      // ── Body ──────────────────────────────────────────────────────────────
      // 中文/日文需要行高 ≥ 1.5 保证可读性
      bodyLarge:   TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
      bodyMedium:  TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6),
      bodySmall:   TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5),

      // ── Label ─────────────────────────────────────────────────────────────
      // labelLarge  → 按钮（FilledButton / OutlinedButton / TextButton）
      // labelMedium → Chip、NavigationBar label、小标记
      // labelSmall  → Badge、角标、极小辅助文字
      labelLarge:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
      labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TextTheme 语义化扩展
//
// 在 Widget 中使用：
//   Text('支出', style: context.veeText.sectionTitle)
//   Text('¥1,234', style: context.veeText.amountHero)
// ─────────────────────────────────────────────────────────────────────────────

extension VeeTextThemeX on TextTheme {
  // ── 页面结构 ──────────────────────────────────────────────────────────────

  /// AppBar / 页面主标题（20sp w700）
  TextStyle get pageTitle    => titleLarge!;

  /// 区块标题（16sp w600）
  TextStyle get sectionTitle => titleMedium!;

  /// 卡片标题 / 列表主文字（14sp w600）
  TextStyle get cardTitle    => titleSmall!;

  // ── 金额 ──────────────────────────────────────────────────────────────────

  /// 金额主数字，首屏英雄数字（40sp w900）
  TextStyle get amountHero   => displaySmall!;

  /// 金额次要展示（24sp w600）
  TextStyle get amountMedium => headlineSmall!;

  /// 列表中的金额（16sp w600）
  TextStyle get amountSmall  => titleMedium!;

  // ── 正文 ──────────────────────────────────────────────────────────────────

  /// 大号正文（16sp w400，段落说明）
  TextStyle get bodyDefault  => bodyMedium!;

  /// 辅助说明、元数据（12sp w400）
  TextStyle get caption      => bodySmall!;

  /// 极小信息（11sp w500，badge / 角标）
  TextStyle get micro        => labelSmall!;

  // ── 交互元素 ──────────────────────────────────────────────────────────────

  /// 按钮文字（15sp w600）
  TextStyle get buttonLabel  => labelLarge!;

  /// Chip / Tab 文字（13sp w500）
  TextStyle get chipLabel    => labelMedium!;

  // ── 特殊用途 ──────────────────────────────────────────────────────────────

  /// 等宽代码（13sp monospace，用于 config key / 验证码）
  TextStyle get monoLabel => labelMedium!.copyWith(fontFamily: 'monospace');

  /// 等宽验证码（大号，28sp monospace，用于 OTP / 绑定码展示）
  TextStyle get monoCode => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 12,
        fontFamily: 'monospace',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext 快捷扩展
// ─────────────────────────────────────────────────────────────────────────────

extension VeeContextX on BuildContext {
  /// 获取 Vee 文字样式扩展
  TextTheme get veeText => Theme.of(this).textTheme;

  /// 获取 ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 是否为小屏幕（宽度 < 400）
  bool get isSmallScreen => MediaQuery.of(this).size.width < 400;

  /// 底部安全区高度
  double get bottomSafeArea => MediaQuery.of(this).padding.bottom;

  /// 键盘高度
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;
}