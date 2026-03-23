// lib/widgets/ui_core/vee_button_spinner.dart
//
// VeeButtonSpinner — 按钮内嵌 Loading 指示器
//
// 替代全库 10+ 处散落的固定写法：
//   SizedBox(
//     width: VeeTokens.iconMd, height: VeeTokens.iconMd,
//     child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//   )
//
// ─────────────────────────────────────────────────────────────────────────────
//
// 设计规范：
//   - 默认尺寸 iconMd (20px)，适用于 FilledButton / OutlinedButton
//   - .small() 命名构造使用 iconSm (16px)，适用于紧凑按钮
//   - 默认颜色 Colors.white（FilledButton 彩色背景），可覆盖
//   - 全部参数均有默认值，支持 const 构造
//
// 用法示例：
//
//   // FilledButton（最常见，const）
//   FilledButton(
//     onPressed: _saving ? null : _save,
//     child: _saving ? const VeeButtonSpinner() : Text('保存'),
//   )
//
//   // OutlinedButton / 带色按钮（需指定颜色，非 const）
//   OutlinedButton(
//     style: OutlinedButton.styleFrom(foregroundColor: VeeTokens.error),
//     onPressed: _loading ? null : _unbind,
//     child: _loading
//         ? VeeButtonSpinner(color: VeeTokens.error)
//         : Text('解绑'),
//   )
//
//   // AppBar actions 内联（跟随主题色，非 const）
//   VeeButtonSpinner(color: Theme.of(context).colorScheme.primary)
//
//   // 紧凑按钮（iconSm = 16px）
//   const VeeButtonSpinner.small()
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'vee_tokens.dart';

class VeeButtonSpinner extends StatelessWidget {
  /// Spinner 颜色，默认 Colors.white（适用于 FilledButton 彩色背景）。
  /// OutlinedButton 或 AppBar 场景需显式传入对应颜色。
  final Color color;

  /// 圆圈粗细，默认 2.0
  final double strokeWidth;

  /// 尺寸，默认 iconMd (20px)
  final double size;

  /// 标准尺寸（iconMd = 20px），用于 FilledButton / OutlinedButton
  const VeeButtonSpinner({
    super.key,
    this.color = Colors.white,
    this.strokeWidth = 2.0,
    this.size = VeeTokens.iconMd,
  });

  /// 小尺寸变体（iconSm = 16px），用于紧凑按钮场景
  const VeeButtonSpinner.small({
    super.key,
    this.color = Colors.white,
    this.strokeWidth = 2.0,
  }) : size = VeeTokens.iconSm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
    );
  }
}
