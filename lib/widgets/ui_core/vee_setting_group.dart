// lib/widgets/ui_core/vee_setting_group.dart
//
// VeeSettingGroup — 设置项分组卡片
// Phase 2 更新：使用 VeeTokens.dividerIndentStd，VeeCard 替代原始 Card

import 'package:flutter/material.dart';
import 'vee_card.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeSettingGroup extends StatelessWidget {
  final List<Widget> items;

  /// 分割线缩进（默认对齐 leading icon：52pt）
  final double indent;

  /// 可选分组标题（显示在卡片上方的小灰字）
  final String? title;

  const VeeSettingGroup({
    super.key,
    required this.items,
    this.indent = VeeTokens.dividerIndentStd,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: VeeTokens.sectionHeaderPadding,
            child: Text(
              title!,
              style: context.veeText.micro.copyWith(
                color: VeeTokens.textSecondaryVal,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
        VeeCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: indent,
              color: VeeTokens.borderColor,
            ),
            itemBuilder: (_, index) => items[index],
          ),
        ),
      ],
    );
  }
}