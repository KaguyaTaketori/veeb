// lib/widgets/ui_core/vee_confirm_dialog.dart
//
// VeeConfirmDialog — 统一操作确认对话框
//
// 替代以下 6+ 处重复的 showDialog(AlertDialog(...)) 调用：
//   - TransactionsScreen Dismissible.confirmDismiss（删除流水）
//   - AddEditTransactionScreen._confirmDelete（删除流水）
//   - ProfileScreen._confirmLogout（登出）
//   - ManageCategoriesScreen._confirmDelete（删除分类）
//   - AdminDashboard._editConfig（保存配置）
//   - PermissionsSheet._save（保存权限 — 注：此处无确认，但可统一错误弹窗）
//
// 使用示例：
//
//   // 危险操作（删除 / 登出）
//   final ok = await VeeConfirmDialog.show(
//     context: context,
//     title: l10n.deleteConfirm,
//     content: l10n.deleteThisRecord,
//     confirmLabel: l10n.delete,
//     isDangerous: true,
//   );
//   if (ok == true) { ... }
//
//   // 普通确认
//   final ok = await VeeConfirmDialog.show(
//     context: context,
//     title: '保存更改',
//     content: '确认将这些设置保存到服务端？',
//   );
//
//   // 带图标的提示
//   await VeeConfirmDialog.show(
//     context: context,
//     title: '操作不可撤销',
//     content: '删除分类后，关联的流水将归类为「其他」。',
//     icon: Icons.warning_amber_rounded,
//     iconColor: Colors.orange,
//     confirmLabel: '我已了解，继续删除',
//     isDangerous: true,
//   );

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;

  /// true → 确认按钮为红色（危险操作：删除/登出/封禁等）
  final bool isDangerous;

  /// 对话框顶部图标（可选）
  final IconData? icon;

  /// 图标颜色（仅在 icon != null 时生效）
  final Color? iconColor;

  const VeeConfirmDialog._({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDangerous,
    this.icon,
    this.iconColor,
  });

  // ── 静态快捷方法 ──────────────────────────────────────────────────────────

  /// 显示确认对话框，返回用户是否点击了"确认"。
  ///
  /// 点击确认 → `true`
  /// 点击取消 / 点击背景关闭 → `false` / `null`
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmLabel = '确认',
    String cancelLabel  = '取消',
    bool isDangerous    = false,
    IconData? icon,
    Color? iconColor,
  }) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => VeeConfirmDialog._(
          title:        title,
          content:      content,
          confirmLabel: confirmLabel,
          cancelLabel:  cancelLabel,
          isDangerous:  isDangerous,
          icon:         icon,
          iconColor:    iconColor,
        ),
      );

  /// 快捷方法：删除确认（isDangerous = true，图标 delete_outline）
  static Future<bool?> showDelete({
    required BuildContext context,
    required String content,
    String title         = '确认删除',
    String confirmLabel  = '删除',
    String cancelLabel   = '取消',
  }) =>
      show(
        context:      context,
        title:        title,
        content:      content,
        confirmLabel: confirmLabel,
        cancelLabel:  cancelLabel,
        isDangerous:  true,
        icon:         Icons.delete_outline,
        iconColor:    VeeTokens.error,
      );

  /// 快捷方法：登出确认
  static Future<bool?> showLogout({
    required BuildContext context,
    String title   = '退出登录',
    String content = '退出后本地数据将保留，可随时重新登录。',
  }) =>
      show(
        context:      context,
        title:        title,
        content:      content,
        confirmLabel: '退出登录',
        cancelLabel:  '取消',
        isDangerous:  true,
        icon:         Icons.logout,
        iconColor:    VeeTokens.error,
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDangerous
        ? VeeTokens.error
        : Theme.of(context).colorScheme.primary;

    return AlertDialog(
      // 内边距通过 contentPadding 精确控制
      contentPadding: EdgeInsets.zero,
      titlePadding:   EdgeInsets.zero,
      actionsPadding: const EdgeInsets.fromLTRB(
        VeeTokens.s16, 0, VeeTokens.s16, VeeTokens.s16,
      ),

      content: Padding(
        padding: const EdgeInsets.fromLTRB(
          VeeTokens.s24, VeeTokens.s24, VeeTokens.s24, VeeTokens.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 图标（可选）──────────────────────────────────────────────
            if (icon != null) ...[
              Container(
                width:  VeeTokens.touchStandard + VeeTokens.s8,
                height: VeeTokens.touchStandard + VeeTokens.s8,
                decoration: BoxDecoration(
                  color: VeeTokens.selectedTint(
                      iconColor ?? Theme.of(context).colorScheme.primary),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size:  VeeTokens.iconXl,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: VeeTokens.spacingMd),
            ],

            // ── 标题 ─────────────────────────────────────────────────────
            Text(
              title,
              style: context.veeText.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VeeTokens.spacingXs),

            // ── 正文 ─────────────────────────────────────────────────────
            Text(
              content,
              style: context.veeText.bodyDefault.copyWith(
                color: VeeTokens.textSecondaryVal,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      actions: [
        // ── 取消按钮（占满一半宽度）──────────────────────────────────────
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
          ),
          const SizedBox(width: VeeTokens.spacingXs),

          // ── 确认按钮 ──────────────────────────────────────────────────
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ),
        ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeInfoDialog — 纯信息展示弹窗（无取消按钮，只有"知道了"）
// ─────────────────────────────────────────────────────────────────────────────

class VeeInfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final String closeLabel;
  final IconData? icon;
  final Color? iconColor;

  const VeeInfoDialog._({
    required this.title,
    required this.content,
    required this.closeLabel,
    this.icon,
    this.iconColor,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String closeLabel = '知道了',
    IconData? icon,
    Color? iconColor,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) => VeeInfoDialog._(
          title:      title,
          content:    content,
          closeLabel: closeLabel,
          icon:       icon,
          iconColor:  iconColor,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      titlePadding:   EdgeInsets.zero,
      actionsPadding: const EdgeInsets.fromLTRB(
        VeeTokens.s16, 0, VeeTokens.s16, VeeTokens.s16,
      ),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(
          VeeTokens.s24, VeeTokens.s24, VeeTokens.s24, VeeTokens.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size:  VeeTokens.iconXl,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: VeeTokens.spacingMd),
            ],
            Text(
              title,
              style: context.veeText.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VeeTokens.spacingXs),
            Text(
              content,
              style: context.veeText.bodyDefault.copyWith(
                color: VeeTokens.textSecondaryVal,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(closeLabel),
          ),
        ),
      ],
    );
  }
}