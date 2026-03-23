import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class _VeeDialogContent extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color? iconColor;

  final bool showIconContainer;

  const _VeeDialogContent({
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.showIconContainer = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s24,
        VeeTokens.s24,
        VeeTokens.s24,
        VeeTokens.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 图标（可选）──────────────────────────────────────────────
          if (icon != null) ...[
            showIconContainer
                ? Container(
                    width: VeeTokens.touchStandard + VeeTokens.s8,
                    height: VeeTokens.touchStandard + VeeTokens.s8,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      icon,
                      size: VeeTokens.iconXl,
                      color: effectiveIconColor,
                    ),
                  )
                : Icon(icon, size: VeeTokens.iconXl, color: effectiveIconColor),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeConfirmDialog — 确认弹窗（取消 + 确认 双按钮）
// ─────────────────────────────────────────────────────────────────────────────

class VeeConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;

  /// true → 确认按钮为红色（危险操作：删除 / 登出 / 封禁等）
  final bool isDangerous;

  final IconData? icon;
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

  // ── 静态快捷方法 ────────────────────────────────────────────────────────────

  /// 通用确认弹窗。点击确认 → true，取消 / 背景关闭 → false / null。
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmLabel = '确认',
    String cancelLabel = '取消',
    bool isDangerous = false,
    IconData? icon,
    Color? iconColor,
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => VeeConfirmDialog._(
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDangerous: isDangerous,
      icon: icon,
      iconColor: iconColor,
    ),
  );

  /// 快捷：删除确认
  static Future<bool?> showDelete({
    required BuildContext context,
    required String content,
    String title = '确认删除',
    String confirmLabel = '删除',
    String cancelLabel = '取消',
  }) => show(
    context: context,
    title: title,
    content: content,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    isDangerous: true,
    icon: Icons.delete_outline,
    iconColor: VeeTokens.error,
  );

  /// 快捷：登出确认
  static Future<bool?> showLogout({
    required BuildContext context,
    String title = '退出登录',
    String content = '退出后本地数据将保留，可随时重新登录。',
  }) => show(
    context: context,
    title: title,
    content: content,
    confirmLabel: '退出登录',
    cancelLabel: '取消',
    isDangerous: true,
    icon: Icons.logout,
    iconColor: VeeTokens.error,
  );

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDangerous
        ? VeeTokens.error
        : Theme.of(context).colorScheme.primary;

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      actionsPadding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        0,
        VeeTokens.s16,
        VeeTokens.s16,
      ),
      // ← 使用共享内容区，showIconContainer: true（圆形容器风格）
      content: _VeeDialogContent(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
        showIconContainer: true,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: VeeTokens.spacingXs),
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
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeInfoDialog — 信息弹窗（仅"知道了"单按钮）
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
  }) => showDialog<void>(
    context: context,
    builder: (_) => VeeInfoDialog._(
      title: title,
      content: content,
      closeLabel: closeLabel,
      icon: icon,
      iconColor: iconColor,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      actionsPadding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        0,
        VeeTokens.s16,
        VeeTokens.s16,
      ),
      content: _VeeDialogContent(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
        showIconContainer: false,
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
