import 'package:flutter/material.dart';

/// 全局设计令牌 (Design Tokens)
class VeeTokens {
  // ── 间距 (Spacings) ──
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;

  // ── 圆角 (Border Radius) ──
  static const double r8 = 8.0;
  static const double r12 = 12.0;   // 内部元素、按钮、输入框
  static const double r16 = 16.0;   // 列表卡片
  static const double r20 = 20.0;   // 大模块底层卡片

  // ── 语义化色彩 (Semantic Colors) ──
  // 建议未来将这些颜色融入 ThemeData.colorScheme 中，这里暂作快速引用
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF1C40F);
  static const Color info = Color(0xFF3B8BD4);
  
  static Color get border => Colors.grey.withOpacity(0.2);
  static Color get background => Colors.grey.shade50;
  static Color get textSecondary => Colors.grey.shade600;
  static Color get textPlaceholder => Colors.grey.shade400;
}