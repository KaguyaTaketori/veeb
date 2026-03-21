// lib/screens/profile/profile_screen.dart
//
// 未登录时显示 Guest 引导页，已登录时显示正常个人信息页。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../api/auth_api.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/settings/manage_accounts_screen.dart';
import '../../screens/settings/manage_categories_screen.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // ── Guest 模式 ────────────────────────────────────────────────────────
    if (auth.isGuest) {
      return const _GuestProfileView();
    }

    // ── checking（极短） ──────────────────────────────────────────────────
    if (auth.status == AuthStatus.checking || auth.user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    // ── 已登录 ────────────────────────────────────────────────────────────
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(l10n.myPage,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              // 头像占位
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(l10n.guestMode,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  l10n.dataStoredLocally,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // 本地数据统计卡片
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.localData,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatItem(
                            icon: Icons.receipt_long_outlined,
                            label: l10n.recordCount,
                            value: l10n.records(txnState.monthCount),
                          ),
                          const SizedBox(width: 24),
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
              ),
              const SizedBox(height: 20),

              // 登录引导卡片
              Card(
                elevation: 0,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.cloud_sync_outlined,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(l10n.loginBenefits,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.primary)),
                      ]),
                      const SizedBox(height: 12),
                      Text(l10n.syncDataMultipleDevices,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(l10n.cloudBackup,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(l10n.shareWithFamily,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(l10n.aiUsageManagement,
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  ),
                  child: Text(l10n.loginOrRegister,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // 系统设置
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.language,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(l10n.languageSettings,
                          style: const TextStyle(fontSize: 15)),
                      trailing: Icon(Icons.chevron_right,
                          color: Colors.grey[400], size: 20),
                      onTap: () => _showLanguageSelector(context, ref),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    const Divider(height: 1, indent: 52),
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(l10n.aboutVee,
                          style: const TextStyle(fontSize: 15)),
                      trailing: Icon(Icons.chevron_right,
                          color: Colors.grey[400], size: 20),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Vee',
                        applicationVersion: '2.0.0',
                        applicationLegalese: '© 2025 Vee',
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    _SettingItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: '管理账户',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => ManageAccountsScreen())),
                    ),
                    _SettingItem(
                      icon: Icons.category_outlined,
                      label: '管理分类',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => ManageCategoriesScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.language,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ...LocaleNotifier.supportedLocales.map((locale) {
              final isSelected = locale.languageCode == currentLocale.languageCode;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey,
                ),
                title: Text(LocaleNotifier.getLanguageName(locale.languageCode)),
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(locale);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

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
          Row(children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(label,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: valueColor ??
                      Theme.of(context).colorScheme.onSurface)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 已登录视图（原 ProfileScreen 内容不变，抽出为独立 Widget）
// ─────────────────────────────────────────────────────────────────────────────

class _LoggedInProfileView extends ConsumerWidget {
  final UserProfile user;
  const _LoggedInProfileView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(l10n.myPage,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(authProvider.notifier).refreshProfile(),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 24),
              children: [
                _UserHeaderCard(user: user),
                const SizedBox(height: 20),
                _QuotaCard(user: user),
                const SizedBox(height: 20),
                _SectionCard(
                  title: l10n.accountSettings,
                  items: [
                    _SettingItem(
                      icon: Icons.edit_outlined,
                      label: l10n.editProfile,
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(user: user)),
                        );
                        if (updated == true) {
                          ref
                              .read(authProvider.notifier)
                              .refreshProfile();
                        }
                      },
                    ),
                    _SettingItem(
                      icon: Icons.lock_outline,
                      label: l10n.changePassword,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ChangePasswordScreen()),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.telegram,
                      label: l10n.telegramConnection,
                      trailing: user.tgUserId != null
                          ? _Badge(l10n.bound,
                              color: Colors.green)
                          : _Badge(l10n.unbound, color: Colors.orange),
                      onTap: () =>
                          _showTgBindInfo(context, user, ref),
                    ),
                    _SettingItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: '管理账户',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => ManageAccountsScreen())),
                    ),
                    _SettingItem(
                      icon: Icons.category_outlined,
                      label: '管理分类',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => ManageCategoriesScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () =>
                        _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout, size: 20),
                    label: Text(l10n.logout,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTgBindInfo(
      BuildContext context, UserProfile user, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _TgBindSheet(user: user),
    ).whenComplete(
        () => ref.read(authProvider.notifier).refreshProfile());
  }

  Future<void> _confirmLogout(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.language,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ...LocaleNotifier.supportedLocales.map((locale) {
              final isSelected = locale.languageCode == currentLocale.languageCode;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey,
                ),
                title: Text(LocaleNotifier.getLanguageName(locale.languageCode)),
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(locale);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── 以下 Widget 与原 profile_screen.dart 保持一致 ──────────────────────────

class _UserHeaderCard extends StatelessWidget {
  final UserProfile user;
  const _UserHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _Avatar(avatarUrl: user.avatarUrl, name: user.name),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('@${user.username}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String  name;
  const _Avatar({this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final color    = Theme.of(context).colorScheme.primary;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        image: avatarUrl != null && avatarUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Center(
              child: Text(initials,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)))
          : null,
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final UserProfile user;
  const _QuotaCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme    = Theme.of(context);
    final isUnlim  = user.aiQuotaMonthly == -1;
    final percent  = user.aiQuotaPercent;
    final color    = percent > 0.9
        ? Colors.red
        : percent > 0.7
            ? Colors.orange
            : theme.colorScheme.primary;
    final resetDate =
        DateFormat('M/d').format(user.quotaResetDate);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.auto_awesome, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(l10n.aiUsageQuota,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
                if (!isUnlim)
                  Text(l10n.quotaResetsOn(resetDate),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 16),
            if (isUnlim)
              Row(children: [
                Icon(Icons.all_inclusive, size: 20, color: color),
                const SizedBox(width: 8),
                Text(l10n.unlimited,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ])
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.used(user.aiQuotaUsed),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600])),
                  Text(l10n.totalQuota(user.aiQuotaMonthly),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_SettingItem> items;
  const _SectionCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500])),
          ),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 52),
              itemBuilder: (_, i) => items[i],
            ),
          ),
        ],
      );
}

class _SettingItem extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final Widget?    trailing;
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
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(label, style: const TextStyle(fontSize: 15)),
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: Colors.grey[400], size: 20),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge(this.label, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600)),
      );
}

class _TgBindSheet extends ConsumerStatefulWidget {
  final UserProfile user;
  const _TgBindSheet({required this.user});

  @override
  ConsumerState<_TgBindSheet> createState() => _TgBindSheetState();
}

class _TgBindSheetState extends ConsumerState<_TgBindSheet> {
  bool    _loading = false;
  String? _code;
  String? _error;

  Future<void> _requestCode() async {
    setState(() { _loading = true; _error = null; _code = null; });
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
    setState(() { _loading = true; _error = null; });
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
    final theme    = Theme.of(context);
    final isBound  = widget.user.tgUserId != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.telegram, color: const Color(0xFF2AABEE), size: 24),
            const SizedBox(width: 8),
            Text(l10n.telegramBind,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),

          if (_error != null) ...[
            VeeErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],

          if (isBound) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(l10n.boundWithTelegram('${widget.user.tgUserId}'),
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 8),
            Text(l10n.quotaSharedAfterBind,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _loading ? null : _unbind,
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.unbind),
            ),
          ] else ...[
            Text(l10n.bindTelegramDesc,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 20),

            if (_code != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(children: [
                  Text(l10n.verificationCode, style: TextStyle(
                      fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(_code!,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 12,
                        color: theme.colorScheme.primary,
                      )),
                  const SizedBox(height: 8),
                  Text(l10n.validFor10Minutes, style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  l10n.sendBindCommand(_code!),
                  style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _loading ? null : _requestCode,
                child: Text(l10n.refreshCode),
              ),
            ] else ...[
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _requestCode,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link, size: 20),
                  label: Text(l10n.applyBindCode,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
