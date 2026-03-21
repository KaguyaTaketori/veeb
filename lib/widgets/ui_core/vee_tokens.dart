// lib/widgets/ui_core/vee_tokens.dart
//
// Vee Design System — Single Source of Truth for all design tokens.
//
// 使用规范（强制）：
//   ✅ 所有 padding/margin/SizedBox 使用此文件的常量
//   ✅ 所有透明度叠加使用语义化 tint 方法（*Tint）
//   ✅ 所有文字样式通过 Theme.of(context).textTheme 访问
//   ❌ 禁止硬编码间距数字（如 EdgeInsets.all(16) → EdgeInsets.all(VeeTokens.s16)）
//   ❌ 禁止直接使用 .withOpacity()（用 VeeTokens.selectedTint(color) 等替代）
//   ❌ 禁止在组件内硬编码 fontSize（通过 TextTheme 引用）

import 'package:flutter/material.dart';

class VeeTokens {
  VeeTokens._(); // 不可实例化

  // ─────────────────────────────────────────────────────────────────────────
  // SPACING — 4pt 网格体系
  // 所有间距必须是 4 的倍数，保证视觉节奏一致
  // ─────────────────────────────────────────────────────────────────────────

  static const double s2  =  2.0;
  static const double s4  =  4.0;
  static const double s6  =  6.0;
  static const double s8  =  8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s16 = 16.0;
  static const double s18 = 18.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s56 = 56.0;
  static const double s64 = 64.0;
  static const double s80 = 80.0;

  // ── 语义化间距别名 ────────────────────────────────────────────────────────
  // 用于统一表达"元素间关系"，而非死记具体数值

  /// 极小：图标与文字之间（4pt）
  static const double spacingXxs = s4;

  /// 超小：inline 元素之间（8pt）
  static const double spacingXs  = s8;

  /// 小：同类元素的间隔（12pt）
  static const double spacingSm  = s12;

  /// 中：组件内部标准间距（16pt）
  static const double spacingMd  = s16;

  /// 大：独立组件之间（24pt）
  static const double spacingLg  = s24;

  /// 超大：区块之间（32pt）
  static const double spacingXl  = s32;

  /// 极大：页面底部安全留白（48pt）
  static const double spacingXxl = s48;

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC PADDINGS — 常用 EdgeInsets 预设
  // 优先使用这里的预设，而不是每处手写 EdgeInsets
  // ─────────────────────────────────────────────────────────────────────────

  /// 页面标准水平内边距 (horizontal: 16)
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: s16);

  /// 页面标准内边距 (h:16, v:8)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: s16, vertical: s8);

  /// 表单 / 登录页 / Modal 内边距 (h:24, v:20)
  static const EdgeInsets formPadding = EdgeInsets.symmetric(horizontal: s24, vertical: s20);

  /// 标准卡片内边距
  static const EdgeInsets cardPadding = EdgeInsets.all(s16);

  /// 大卡片内边距（Summary / Stats 首屏卡）
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(s20);

  /// 列表 Tile 内边距
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(horizontal: s16, vertical: s12);

  /// 水平 Chip / FilterChip 内边距
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: s14, vertical: s6);

  /// Badge 内边距
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: s8, vertical: s2);

  /// 区块标题与内容之间的间距
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.only(left: s4, bottom: s8);

  /// 底部 Sheet 动态内边距（包含键盘 + SafeArea bottom）
  static EdgeInsets sheetPadding(BuildContext context) => EdgeInsets.only(
        left: s24,
        right: s24,
        top: s24,
        bottom: MediaQuery.of(context).viewInsets.bottom + s32,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // BORDER RADIUS — 三档圆角体系
  // ─────────────────────────────────────────────────────────────────────────
  //
  //  小元素 rXs/rSm (6–8pt)   → Badge、图标容器
  //  中等组件 rMd (12pt)       → 按钮、输入框、小型卡片
  //  大卡片 rLg (16pt)         → 列表项卡片、标准内容卡片
  //  大模块 rXl (20pt)         → Summary Card、Modal Sheet
  //  全圆 rFull                → Chip、圆形 FAB

  static const double rXs   =  6.0;
  static const double rSm   =  8.0;
  static const double rMd   = 12.0;
  static const double rLg   = 16.0;
  static const double rXl   = 20.0;
  static const double rFull = 999.0;

  // 向后兼容别名
  static const double r6  = rXs;
  static const double r8  = rSm;
  static const double r12 = rMd;
  static const double r16 = rLg;
  static const double r20 = rXl;

  // ── 预设 BorderRadius ──────────────────────────────────────────────────

  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(rLg));

  static const BorderRadius cardBorderRadiusLg =
      BorderRadius.all(Radius.circular(rXl));

  static const BorderRadius buttonBorderRadius =
      BorderRadius.all(Radius.circular(rMd));

  static const BorderRadius inputBorderRadius =
      BorderRadius.all(Radius.circular(rMd));

  static const BorderRadius sheetBorderRadius =
      BorderRadius.vertical(top: Radius.circular(rXl));

  static const BorderRadius badgeBorderRadius =
      BorderRadius.all(Radius.circular(rXs));

  // ─────────────────────────────────────────────────────────────────────────
  // ICON SIZES
  // ─────────────────────────────────────────────────────────────────────────

  static const double iconXs   = 14.0; // 角标内图标
  static const double iconSm   = 16.0; // 辅助图标
  static const double iconMd   = 20.0; // 列表 leading（大多数场景）
  static const double iconLg   = 24.0; // 默认图标（Material 规范）
  static const double iconXl   = 32.0; // 大图标
  static const double iconXxl  = 48.0; // 空状态图标
  static const double iconHero = 64.0; // 页面英雄图标

  // ─────────────────────────────────────────────────────────────────────────
  // TOUCH TARGETS
  // ─────────────────────────────────────────────────────────────────────────

  /// iOS HIG 最低触控区域（44pt）
  static const double touchMin      = 44.0;

  /// Material / WCAG AA 标准触控区域（48pt）
  static const double touchStandard = 48.0;

  /// 标准按钮高度
  static const double buttonHeight  = 52.0;

  // ─────────────────────────────────────────────────────────────────────────
  // CONTENT CONSTRAINTS
  // ─────────────────────────────────────────────────────────────────────────

  /// 移动端内容最大宽度（防止宽屏过度拉伸）
  static const double maxContentWidth = 680.0;

  /// 表单最大宽度（登录/注册/设置页）
  static const double maxFormWidth    = 400.0;

  // ─────────────────────────────────────────────────────────────────────────
  // COLORS — Brand & Semantic
  // ─────────────────────────────────────────────────────────────────────────

  // Brand
  static const Color brandPrimary     = Color(0xFFE85D30);
  static const Color brandPrimaryDark = Color(0xFFC44A20);

  // Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color error   = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF1C40F);
  static const Color info    = Color(0xFF3B8BD4);

  // Neutral Surface（light mode 固定色 — 深色模式请用 colorScheme）
  static const Color surfaceDefault = Color(0xFFFAFAFA); // grey.shade50
  static const Color surfaceCard    = Color(0xFFFFFFFF);
  static const Color surfaceSunken  = Color(0xFFF5F5F5); // grey.shade100

  // Text（light mode 固定色）
  static const Color textPrimaryVal     = Color(0xFF1A1A1A);
  static const Color textSecondaryVal   = Color(0xFF757575); // grey.shade600
  static const Color textPlaceholderVal = Color(0xFFBDBDBD); // grey.shade400
  static const Color textDisabledVal    = Color(0xFF9E9E9E);

  // Border
  static const Color borderColor = Color(0xFFE0E0E0);

  // ── 动态 getter（向后兼容，新代码建议直接用 colorScheme） ──────────────
  static Color get background      => surfaceDefault;
  static Color get border          => borderColor;
  static Color get textSecondary   => textSecondaryVal;
  static Color get textPlaceholder => textPlaceholderVal;

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC OPACITY TINTS
  // 用于替代所有散落的 .withOpacity() 调用
  //
  // 使用场景速查：
  //   surfaceTint  → 引导卡、品牌提示背景（5%）
  //   hoverTint    → 图标容器背景、悬停态（8%）
  //   selectedTint → Chip selected、Tab indicator（12%）
  //   pressedTint  → 按钮按下反馈（16%）
  //   strongTint   → 强调背景、分隔线（20%）
  //   overlayTint  → 图片遮罩层（45%）
  // ─────────────────────────────────────────────────────────────────────────

  /// 极淡背景着色（引导卡、品牌提示区域）
  static Color surfaceTint(Color base)  => base.withOpacity(0.05);

  /// 图标容器背景 / 悬停态
  static Color hoverTint(Color base)    => base.withOpacity(0.08);

  /// 选中 / 激活态背景（Chip selected, FilterButton active）
  static Color selectedTint(Color base) => base.withOpacity(0.12);

  /// 按下反馈背景
  static Color pressedTint(Color base)  => base.withOpacity(0.16);

  /// 强调背景（突出展示区域）
  static Color strongTint(Color base)   => base.withOpacity(0.20);

  /// 图像遮罩层
  static Color overlayTint(Color base)  => base.withOpacity(0.45);

  // ─────────────────────────────────────────────────────────────────────────
  // BORDER SIDES — 消除散落的 BorderSide(...) 手写调用
  // ─────────────────────────────────────────────────────────────────────────

  /// 默认细灰边框（卡片、输入框 enabled 态）
  static BorderSide get defaultBorder =>
      const BorderSide(color: borderColor, width: 1.0);

  /// 加深灰边框（hover 态）
  static BorderSide get strongBorder =>
      const BorderSide(color: Color(0xFFBDBDBD), width: 1.0);

  /// 品牌色半透明边框（选中高亮卡片背景）
  static BorderSide primaryBorder(Color primary) =>
      BorderSide(color: selectedTint(primary), width: 1.5);

  /// 品牌色实线边框（焦点 / 激活态）
  static BorderSide activeBorder(Color primary) =>
      BorderSide(color: primary, width: 1.5);

  /// 错误边框
  static BorderSide get errorBorder =>
      const BorderSide(color: error, width: 1.5);

  /// 危险操作按钮边框（如：登出、删除）
  static BorderSide dangerBorder(Color dangerColor) =>
      BorderSide(color: dangerColor.withOpacity(0.3), width: 1.0);

  // ─────────────────────────────────────────────────────────────────────────
  // SHAPE BORDERS — RoundedRectangleBorder 预设
  // 消除各页面手写 shape: RoundedRectangleBorder(...)
  // ─────────────────────────────────────────────────────────────────────────

  /// 标准卡片（rLg + 默认灰边框）
  static ShapeBorder get cardShape => RoundedRectangleBorder(
        borderRadius: cardBorderRadius,
        side: defaultBorder,
      );

  /// 大卡片（rXl + 默认灰边框）
  static ShapeBorder get cardShapeLg => RoundedRectangleBorder(
        borderRadius: cardBorderRadiusLg,
        side: defaultBorder,
      );

  /// 选中卡片（rLg + 品牌色实线边框）
  static ShapeBorder cardShapeSelected(Color primary) =>
      RoundedRectangleBorder(
        borderRadius: cardBorderRadius,
        side: activeBorder(primary),
      );

  /// 标准按钮（rMd，无边框）
  static ShapeBorder get buttonShape => const RoundedRectangleBorder(
        borderRadius: buttonBorderRadius,
      );

  /// 底部 Sheet（上半圆角）
  static ShapeBorder get sheetShape => const RoundedRectangleBorder(
        borderRadius: sheetBorderRadius,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // ELEVATION
  // ─────────────────────────────────────────────────────────────────────────

  /// 扁平卡片（用边框代替阴影，Vee 主要风格）
  static const double elevationNone  = 0.0;

  /// Modal / Dialog / BottomSheet 阴影
  static const double elevationModal = 8.0;

  /// SnackBar / Toast 阴影
  static const double elevationToast = 4.0;

  // ─────────────────────────────────────────────────────────────────────────
  // DIVIDER
  // ─────────────────────────────────────────────────────────────────────────

  /// 标准列表分割线缩进（16 padding + 20 icon + 16 gap = 52）
  static const double dividerIndentStd  = 52.0;

  /// 带大 leading 容器的分割线缩进（16 + 24 + 24）
  static const double dividerIndentLg   = 64.0;

  // ─────────────────────────────────────────────────────────────────────────
  // ANIMATION DURATIONS
  // ─────────────────────────────────────────────────────────────────────────

  static const Duration durationFast   = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow   = Duration(milliseconds: 400);
}