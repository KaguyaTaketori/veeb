import 'package:flutter/material.dart';
import 'vee_tokens.dart';

/// VeeCard 是一个通用的卡片组件，适用于列表项、信息展示等场景。
class VeeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const VeeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VeeTokens.s16),
    this.borderRadius = VeeTokens.r16,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: VeeTokens.border),
      ),
      clipBehavior: Clip.antiAlias, // 确保内部点击水波纹不溢出圆角
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}