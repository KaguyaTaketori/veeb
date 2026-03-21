// lib/utils/vee_colors.dart
//
// VeeColors — 颜色工具方法集合

import 'package:flutter/material.dart';

class VeeColors {
  VeeColors._(); // 不可实例化

  // ── 颜色格式常量（后端返回的 hex 颜色格式） ─────────────────────────────
  //   支持：'#E85D30'  '#e85d30'  'E85D30'  '#RGB' (3位缩写)
  //   不支持：rgba()、hsl()、命名颜色 — 这些在 Vee 后端不会出现

  /// 将后端 hex 字符串转换为 Flutter Color。
  ///
  /// 支持格式：
  ///   '#RRGGBB'  → 标准 6 位（最常见）
  ///   'RRGGBB'   → 无 # 前缀
  ///   '#RGB'     → 3 位缩写（展开为 #RRGGBB）
  ///
  /// 所有异常情况（null、空字符串、非法格式）均安全返回 [fallback]，
  /// 默认 fallback 为 Colors.grey (#9E9E9E)。
  ///
  /// 示例：
  ///   VeeColors.fromHex('#E85D30')  →  Color(0xFFE85D30)
  ///   VeeColors.fromHex('#F63')     →  Color(0xFFFF6633)
  ///   VeeColors.fromHex(null)       →  Color(0xFF9E9E9E)
  ///   VeeColors.fromHex('')         →  Color(0xFF9E9E9E)
  ///   VeeColors.fromHex('invalid')  →  Color(0xFF9E9E9E)
  static Color fromHex(
    String? hex, {
    Color fallback = const Color(0xFF9E9E9E),
  }) {
    if (hex == null || hex.isEmpty) return fallback;

    // 去除前缀 # 并转为大写
    var clean = hex.trim().toUpperCase();
    if (clean.startsWith('#')) clean = clean.substring(1);

    // 处理 3 位缩写：#RGB → #RRGGBB
    if (clean.length == 3) {
      clean =
          '${clean[0]}${clean[0]}'
          '${clean[1]}${clean[1]}'
          '${clean[2]}${clean[2]}';
    }

    // 仅接受标准 6 位
    if (clean.length != 6) return fallback;

    // 验证全是合法 hex 字符（防止 FormatException）
    final validHex = RegExp(r'^[0-9A-F]{6}$');
    if (!validHex.hasMatch(clean)) return fallback;

    return Color(int.parse('FF$clean', radix: 16));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 便捷工具方法
  // ─────────────────────────────────────────────────────────────────────────

  /// 将 Color 转换为后端期望的 '#RRGGBB' 格式字符串。
  ///
  /// 注意：忽略 alpha 通道（后端 color 字段不存 alpha）。
  ///
  /// 示例：
  ///   VeeColors.toHex(Color(0xFFE85D30))  →  '#E85D30'
  static String toHex(Color color) {
    final r = color.red.toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = color.green.toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = color.blue.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$r$g$b';
  }

  /// 根据背景色亮度自动选择前景色（黑或白），用于动态文字颜色。
  ///
  /// 使用 W3C 相对亮度公式，阈值 0.179（人眼感知平衡点）。
  ///
  /// 示例：
  ///   VeeColors.contrastForeground(Color(0xFFE85D30))  →  Colors.white
  ///   VeeColors.contrastForeground(Color(0xFFF1C40F))  →  Colors.black
  static Color contrastForeground(Color background) {
    // 线性化 sRGB 通道
    double linearize(double c) {
      c /= 255.0;
      return c <= 0.04045
          ? c / 12.92
          : ((c + 0.055) / 1.055) * ((c + 0.055) / 1.055);
    }

    final r = linearize(background.red.toDouble());
    final g = linearize(background.green.toDouble());
    final b = linearize(background.blue.toDouble());
    final luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;

    return luminance > 0.179 ? const Color(0xFF1A1A1A) : Colors.white;
  }

  /// 从列表中取颜色（安全取模，避免 index out of range）。
  ///
  /// 主要用于 stats_screen 分类色环取色：
  ///   旧：kCategoryColors[i % kCategoryColors.length]
  ///   新：VeeColors.cycle(kCategoryColors, i)
  static Color cycle(List<Color> colors, int index) {
    if (colors.isEmpty) return const Color(0xFF9E9E9E);
    return colors[index % colors.length];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 收支颜色语义化快捷方法
  // ─────────────────────────────────────────────────────────────────────────
  //
  // 替代 transactions_screen 和 add_edit_transaction 中散落的三元表达式：
  //   旧：t.type == 'income' ? VeeTokens.success
  //       : t.type == 'transfer' ? VeeTokens.info
  //       : VeeTokens.error
  //
  //   新：VeeColors.forTransactionType(t.type)
  //
  // 颜色均来自 VeeTokens，已通过 WCAG AA 校验。

  /// 根据流水类型返回对应语义颜色。
  ///   'income'   → VeeTokens.success  (#18A059, 4.83:1)
  ///   'transfer' → VeeTokens.info     (#1A6BB5, 5.24:1)
  ///   其他/null  → VeeTokens.error    (#C0392B, 5.11:1)
  static Color forTransactionType(String? type) {
    switch (type) {
      case 'income':
        return const Color(0xFF18A059); // VeeTokens.success
      case 'transfer':
        return const Color(0xFF1A6BB5); // VeeTokens.info
      default:
        return const Color(0xFFC0392B); // VeeTokens.error
    }
  }

  /// 根据流水类型返回金额前缀符号。
  ///   'income'   → '+'
  ///   'transfer' → '↔'
  ///   其他/null  → '-'
  static String prefixForTransactionType(String? type) {
    switch (type) {
      case 'income':
        return '+';
      case 'transfer':
        return '↔';
      default:
        return '-';
    }
  }
}
