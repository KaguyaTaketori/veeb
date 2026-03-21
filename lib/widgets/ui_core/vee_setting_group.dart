import 'package:flutter/material.dart';
import 'vee_card.dart';
import 'vee_tokens.dart';

class VeeSettingGroup extends StatelessWidget {
  final List<Widget> items;
  final double indent; // 分割线的左侧缩进

  const VeeSettingGroup({
    super.key,
    required this.items,
    this.indent = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return VeeCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: indent),
        itemBuilder: (_, index) => items[index],
      ),
    );
  }
}