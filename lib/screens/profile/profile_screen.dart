// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vee_app/widgets/ui_core/vee_skeleton_card.dart';
import '../../api/auth_api.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/settings/manage_accounts_screen.dart';
import '../../screens/settings/manage_categories_screen.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_confirm_dialog.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_setting_group.dart';
import '../../widgets/ui_core/vee_amount_display.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'package:vee_app/widgets/ui_core/vee_badge.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isGuest) return const _GuestProfileView();

    if (auth.status == AuthStatus.checking || auth.user == null) {
      return Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: VeeTokens.s24, vertical: VeeTokens.s32),
          children: [
            // 头像 + 用户名卡
            VeeSkeletonCard.card(),
            const SizedBox(height: VeeTokens.spacingLg),
            // AI 额度卡
            VeeSkeletonCard.card(),
            const SizedBox(height: VeeTokens.spacingLg),
            // 设置列表项 × 5
            ...List.generate(5, (_) => Padding(
              padding: const EdgeInsets.only(
                  bottom: VeeTokens.spacingXs),
              child: VeeSkeletonCard.list(),
            )),
          ],
        ),
      );
    }

    return _LoggedInProfileView(user: auth.user!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guest 视图
// ─────────────────────────────────────────────────────────────────────────────

class _GuestProfileView extends ConsumerWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnState = ref.watch(transactionsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myPage), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: VeeTokens.maxFormWidth + 80,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: VeeTokens.s24,
              vertical: VeeTokens.s32,
            ),
            children: [
              // 头像占位
              Center(
                child: Container(
                  width: VeeTokens.s80,
                  height: VeeTokens.s80,
                  decoration: BoxDecoration(
                    color: VeeTokens.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: VeeTokens.iconXxl,
                    color: VeeTokens.textPlaceholderVal,
                  ),
                ),
              ),
              const SizedBox(height: VeeTokens.s12),
              Center(
                child: Text(
                  l10n.guestMode,
                  style: context.veeText.sectionTitle,
                ),
              ),
              const SizedBox(height: VeeTokens.spacingXxs),
              Center(
                child: Text(
                  l10n.dataStoredLocally,
                  style: context.veeText.caption.copyWith(
                    color: VeeTokens.textPlaceholderVal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: VeeTokens.s32),

              // 本地数据统计卡片
              VeeCard(
                padding: VeeTokens.cardPaddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.localData,
                      style: context.veeText.micro.copyWith(
                        color: VeeTokens.textPlaceholderVal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: VeeTokens.s12),
                    Row(
                      children: [
                        _StatItem(
                          icon: Icons.receipt_long_outlined,
                          label: l10n.recordCount,
                          value: l10n.records(txnState.monthCount),
                        ),
                        const SizedBox(width: VeeTokens.spacingLg),
                        _StatItem(
                          icon: Icons.cloud_off_outlined,
                          label: l10n.cloudSync,
                          value: l10n.notSet,
                          valueColor: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VeeTokens.spacingLg),

              // 登录引导卡片
              VeeCard(
                backgroundColor: VeeTokens.surfaceTint(
                  Theme.of(context).colorScheme.primary,
                ),
                borderColor: VeeTokens.selectedTint(
                  Theme.of(context).colorScheme.primary,
                ),
                padding: VeeTokens.cardPaddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_sync_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: VeeTokens.spacingXs),
                        Text(
                          l10n.loginBenefits,
                          style: context.veeText.cardTitle.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VeeTokens.s12),
                    Text(
                      l10n.syncDataMultipleDevices,
                      style: context.veeText.bodyDefault,
                    ),
                    const SizedBox(height: VeeTokens.s2 + 1),
                    Text(l10n.cloudBackup, style: context.veeText.bodyDefault),
                    const SizedBox(height: VeeTokens.s2 + 1),
                    Text(
                      l10n.shareWithFamily,
                      style: context.veeText.bodyDefault,
                    ),
                    const SizedBox(height: VeeTokens.s2 + 1),
                    Text(
                      l10n.aiUsageManagement,
                      style: context.veeText.bodyDefault,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VeeTokens.spacingLg),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: VeeTokens.buttonHeight,
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text(l10n.loginOrRegister),
                ),
              ),
              const SizedBox(height: VeeTokens.spacingLg),

              // 系统设置 — 使用 VeeSettingGroup
              VeeSettingGroup(
                items: [
                  _SettingItem(
                    icon: Icons.language,
                    label: l10n.languageSettings,
                    onTap: () => _showLanguageSelector(context, ref),
                  ),
                  _SettingItem(
                    icon: Icons.info_outline,
                    label: l10n.aboutVee,
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Vee',
                      applicationVersion: '2.0.0',
                      applicationLegalese: '© 2025 Vee',
                    ),
                  ),
                  _SettingItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: '管理账户',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageAccountsScreen(),
                      ),
                    ),
                  ),
                  _SettingItem(
                    icon: Icons.category_outlined,
                    label: '管理分类',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageCategoriesScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VeeTokens.s48),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VeeTokens.rXl),
        ),
      ),
      builder: (ctx) => _LanguageSelectorSheet(currentLocale: currentLocale),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            icon,
            size: VeeTokens.iconSm,
            color: VeeTokens.textPlaceholderVal,
          ),
          const SizedBox(width: VeeTokens.spacingXxs),
          Text(
            label,
            style: context.veeText.micro.copyWith(
              color: VeeTokens.textPlaceholderVal,
            ),
          ),
        ],
      ),
      const SizedBox(height: VeeTokens.spacingXxs),
      Text(
        value,
        style: context.veeText.pageTitle.copyWith(
          color: valueColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 已登录视图
// ─────────────────────────────────────────────────────────────────────────────

class _LoggedInProfileView extends ConsumerWidget {
  final UserProfile user;
  const _LoggedInProfileView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myPage), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: VeeTokens.maxContentWidth,
          ),
          child: RefreshIndicator(
            onRefresh: () => ref.read(authProvider.notifier).refreshProfile(),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: VeeTokens.s16,
                vertical: VeeTokens.s24,
              ),
              children: [
                _UserHeaderCard(user: user),
                const SizedBox(height: VeeTokens.spacingLg),
                _QuotaCard(user: user),
                const SizedBox(height: VeeTokens.spacingLg),

                // 账户设置 — 使用 VeeSettingGroup
                VeeSettingGroup(
                  title: l10n.accountSettings,
                  items: [
                    _SettingItem(
                      icon: Icons.edit_outlined,
                      label: l10n.editProfile,
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user),
                          ),
                        );
                        if (updated == true) {
                          ref.read(authProvider.notifier).refreshProfile();
                        }
                      },
                    ),
                    _SettingItem(
                      icon: Icons.lock_outline,
                      label: l10n.changePassword,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.telegram,
                      label: l10n.telegramConnection,
                      trailing: user.tgUserId != null
                          ? VeeBadge(
                              label: l10n.bound,
                              color: VeeTokens.success,
                            )
                          : VeeBadge(label: l10n.unbound, color: Colors.orange),
                      onTap: () => _showTgBindInfo(context, user, ref),
                    ),
                    _SettingItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: '管理账户',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageAccountsScreen(),
                        ),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.category_outlined,
                      label: '管理分类',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageCategoriesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VeeTokens.spacingMd),

                // 系统设置 — 使用 VeeSettingGroup
                VeeSettingGroup(
                  title: l10n.systemSettings,
                  items: [
                    _SettingItem(
                      icon: Icons.language,
                      label: l10n.languageSettings,
                      onTap: () => _showLanguageSelector(context, ref),
                    ),
                    _SettingItem(
                      icon: Icons.info_outline,
                      label: l10n.aboutVee,
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Vee',
                        applicationVersion: '2.0.0',
                        applicationLegalese: '© 2025 Vee',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VeeTokens.s32),

                // 登出按钮
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VeeTokens.error,
                      side: VeeTokens.dangerBorder(VeeTokens.error),
                      padding: const EdgeInsets.symmetric(
                        vertical: VeeTokens.s16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VeeTokens.rLg),
                      ),
                    ),
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout, size: VeeTokens.iconMd),
                    label: Text(
                      l10n.logout,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: VeeTokens.s48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTgBindInfo(BuildContext context, UserProfile user, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VeeTokens.rXl),
        ),
      ),
      builder: (ctx) => _TgBindSheet(user: user),
    ).whenComplete(() => ref.read(authProvider.notifier).refreshProfile());
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await VeeConfirmDialog.showLogout(
      context: context,
      title: l10n.logout,
      content: l10n.logoutConfirm,
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VeeTokens.rXl),
        ),
      ),
      builder: (ctx) => _LanguageSelectorSheet(currentLocale: currentLocale),
    );
  }
}

// ── 语言选择器 Sheet（抽出，Guest/登录共用）──────────────────────────────────

class _LanguageSelectorSheet extends ConsumerWidget {
  final dynamic currentLocale;
  const _LanguageSelectorSheet({required this.currentLocale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VeeTokens.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: VeeTokens.spacingLg,
              bottom: VeeTokens.spacingMd,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.language, style: context.veeText.sectionTitle),
            ),
          ),
          ...LocaleNotifier.supportedLocales.map((locale) {
            final isSelected =
                locale.languageCode == currentLocale.languageCode;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : VeeTokens.textPlaceholderVal,
              ),
              title: Text(LocaleNotifier.getLanguageName(locale.languageCode)),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(locale);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: VeeTokens.spacingMd),
        ],
      ),
    );
  }
}

// ── 用户头部卡片 ──────────────────────────────────────────────────────────────

class _UserHeaderCard extends StatelessWidget {
  final UserProfile user;
  const _UserHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return VeeCard(
      padding: VeeTokens.cardPaddingLg,
      child: Row(
        children: [
          _Avatar(avatarUrl: user.avatarUrl, name: user.name),
          const SizedBox(width: VeeTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: context.veeText.sectionTitle),
                const SizedBox(height: VeeTokens.s2),
                Text(
                  '@${user.username}',
                  style: context.veeText.caption.copyWith(
                    color: VeeTokens.textPlaceholderVal,
                  ),
                ),
                const SizedBox(height: VeeTokens.spacingXxs),
                Text(
                  user.email,
                  style: context.veeText.caption.copyWith(
                    color: VeeTokens.textSecondaryVal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  const _Avatar({this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: VeeTokens.s64,
      height: VeeTokens.s64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VeeTokens.selectedTint(color),
        image: avatarUrl != null && avatarUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Center(
              child: Text(
                initials,
                style: context.veeText.amountMedium.copyWith(color: color),
              ),
            )
          : null,
    );
  }
}

// ── AI 额度卡 ─────────────────────────────────────────────────────────────────

class _QuotaCard extends StatelessWidget {
  final UserProfile user;
  const _QuotaCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isUnlim = user.aiQuotaMonthly == -1;
    final percent = user.aiQuotaPercent;
    final color = percent > 0.9
        ? VeeTokens.error
        : percent > 0.7
        ? Colors.orange
        : theme.colorScheme.primary;
    final resetDate = DateFormat('M/d').format(user.quotaResetDate);

    return VeeCard(
      padding: VeeTokens.cardPaddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: VeeTokens.iconSm,
                    color: color,
                  ),
                  const SizedBox(width: VeeTokens.spacingXs),
                  Text(l10n.aiUsageQuota, style: context.veeText.cardTitle),
                ],
              ),
              if (!isUnlim)
                Text(
                  l10n.quotaResetsOn(resetDate),
                  style: context.veeText.micro.copyWith(
                    color: VeeTokens.textPlaceholderVal,
                  ),
                ),
            ],
          ),
          const SizedBox(height: VeeTokens.spacingMd),
          if (isUnlim)
            Row(
              children: [
                Icon(Icons.all_inclusive, size: VeeTokens.iconMd, color: color),
                const SizedBox(width: VeeTokens.spacingXs),
                Text(
                  l10n.unlimited,
                  style: context.veeText.amountSmall.copyWith(color: color),
                ),
              ],
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.used(user.aiQuotaUsed),
                  style: context.veeText.caption.copyWith(
                    color: VeeTokens.textSecondaryVal,
                  ),
                ),
                Text(
                  l10n.totalQuota(user.aiQuotaMonthly),
                  style: context.veeText.caption.copyWith(
                    color: VeeTokens.textSecondaryVal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VeeTokens.s10),
            ClipRRect(
              borderRadius: BorderRadius.circular(VeeTokens.rSm),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 设置项 ────────────────────────────────────────────────────────────────────

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: VeeTokens.hoverTint(Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(VeeTokens.rSm),
      ),
      child: Icon(
        icon,
        size: VeeTokens.iconMd,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    title: Text(label, style: context.veeText.bodyDefault),
    trailing:
        trailing ??
        Icon(
          Icons.chevron_right,
          color: VeeTokens.textPlaceholderVal,
          size: VeeTokens.iconMd,
        ),
    onTap: onTap,
    contentPadding: VeeTokens.tilePadding,
  );
}

// ── Telegram 绑定 Sheet ───────────────────────────────────────────────────────

class _TgBindSheet extends ConsumerStatefulWidget {
  final UserProfile user;
  const _TgBindSheet({required this.user});

  @override
  ConsumerState<_TgBindSheet> createState() => _TgBindSheetState();
}

class _TgBindSheetState extends ConsumerState<_TgBindSheet> {
  bool _loading = false;
  String? _code;
  String? _error;

  Future<void> _requestCode() async {
    setState(() {
      _loading = true;
      _error = null;
      _code = null;
    });
    try {
      final resp = await ref.read(authProvider.notifier).requestTgBindCode();
      setState(() => _code = resp['code'] as String?);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unbind() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).deleteTgBind();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isBound = widget.user.tgUserId != null;

    return Padding(
      padding: VeeTokens.sheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.telegram,
                color: Color(0xFF2AABEE),
                size: VeeTokens.iconLg,
              ),
              const SizedBox(width: VeeTokens.spacingXs),
              Text(l10n.telegramBind, style: context.veeText.sectionTitle),
            ],
          ),
          const SizedBox(height: VeeTokens.spacingMd),

          if (_error != null) VeeErrorBanner(message: _error!),

          if (isBound) ...[
            Container(
              padding: VeeTokens.tilePadding,
              decoration: BoxDecoration(
                color: VeeTokens.successSurface,
                borderRadius: BorderRadius.circular(VeeTokens.rMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: VeeTokens.success,
                    size: VeeTokens.iconMd,
                  ),
                  const SizedBox(width: VeeTokens.spacingXs),
                  Text(
                    l10n.boundWithTelegram('${widget.user.tgUserId}'),
                    style: context.veeText.cardTitle.copyWith(
                      color: VeeTokens.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VeeTokens.spacingXs),
            Text(
              l10n.quotaSharedAfterBind,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
            const SizedBox(height: VeeTokens.spacingLg),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: VeeTokens.error,
                side: VeeTokens.dangerBorder(VeeTokens.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VeeTokens.rMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: VeeTokens.s14),
              ),
              onPressed: _loading ? null : _unbind,
              child: _loading
                  ? const SizedBox(
                      width: VeeTokens.iconSm,
                      height: VeeTokens.iconSm,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.unbind),
            ),
          ] else ...[
            Text(
              l10n.bindTelegramDesc,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
                height: 1.5,
              ),
            ),
            const SizedBox(height: VeeTokens.spacingLg),

            if (_code != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: VeeTokens.spacingLg,
                ),
                decoration: BoxDecoration(
                  color: VeeTokens.surfaceTint(theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(VeeTokens.rLg),
                  border: Border.all(
                    color: VeeTokens.selectedTint(theme.colorScheme.primary),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.verificationCode,
                      style: context.veeText.caption.copyWith(
                        color: VeeTokens.textSecondaryVal,
                      ),
                    ),
                    const SizedBox(height: VeeTokens.spacingXs),
                    Text(
                      _code!,
                      style: context.veeText.amountHero.copyWith(
                        letterSpacing: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: VeeTokens.spacingXs),
                    Text(
                      l10n.validFor10Minutes,
                      style: context.veeText.micro.copyWith(
                        color: VeeTokens.textPlaceholderVal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VeeTokens.s12),
              Container(
                padding: VeeTokens.tilePadding,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(VeeTokens.rSm),
                ),
                child: Text(
                  l10n.sendBindCommand(_code!),
                  style: context.veeText.bodyDefault.copyWith(
                    fontFamily: 'monospace',
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: VeeTokens.s14),
              TextButton(
                onPressed: _loading ? null : _requestCode,
                child: Text(l10n.refreshCode),
              ),
            ] else ...[
              SizedBox(
                height: VeeTokens.touchStandard + VeeTokens.s2,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _requestCode,
                  icon: _loading
                      ? const SizedBox(
                          width: VeeTokens.iconSm,
                          height: VeeTokens.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link, size: VeeTokens.iconMd),
                  label: Text(l10n.applyBindCode),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
