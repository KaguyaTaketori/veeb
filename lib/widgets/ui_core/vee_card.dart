// lib/widgets/ui_core/vee_card.dart
//
// VeeCard — 通用卡片容器
// Phase 2 更新：使用 VeeTokens shape/padding 常量，增加 borderColor 参数

import 'package:flutter/material.dart';
import 'vee_tokens.dart';

class VeeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ShapeBorder? shape;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;

  /// 覆盖边框颜色（默认 VeeTokens.borderColor）
  final Color? borderColor;

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

  @override
  Widget build(BuildContext context) {
    final effectiveShape = shape ??
        (borderColor != null
            ? RoundedRectangleBorder(
                borderRadius: VeeTokens.cardBorderRadius,
                side: BorderSide(color: borderColor!, width: 1.0),
              )
            : VeeTokens.cardShape);

    return Card(
      elevation:   VeeTokens.elevationNone,
      margin:      EdgeInsets.zero,
      color:       backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape:       effectiveShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:      onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}