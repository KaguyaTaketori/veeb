// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: RefreshIndicator(
            onRefresh: () => ref.read(authProvider.notifier).refreshProfile(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // 1. 用户头部卡片
                _UserHeaderCard(user: user),
                const SizedBox(height: 20),

                // 2. AI 配额卡片
                _QuotaCard(user: user),
                const SizedBox(height: 20),

                // 3. 账号设置
                _SectionCard(
                  title: '账号',
                  items: [
                    _SettingItem(
                      icon: Icons.edit_outlined,
                      label: '编辑个人资料',
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => EditProfileScreen(user: user)),
                        );
                        if (updated == true) {
                          ref.read(authProvider.notifier).refreshProfile();
                        }
                      },
                    ),
                    _SettingItem(
                      icon: Icons.lock_outline,
                      label: '修改密码',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.telegram,
                      label: 'Telegram 绑定',
                      trailing: user.tgUserId != null
                        ? _Badge('已绑定 #${user.tgUserId}', color: Colors.green)
                        : _Badge('未绑定', color: Colors.orange),
                      onTap: () => _showTgBindInfo(context, user, ref),  // ← 加 ref
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. 通用设置
                _SectionCard(
                  title: '系统',
                  items: [
                    _SettingItem(
                      icon: Icons.info_outline,
                      label: '关于 Vee',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Vee',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2025 Vee',
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.delete_sweep_outlined,
                      label: '清除本地缓存',
                      onTap: () => _confirmClearCache(context),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 5. 退出登录
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
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('退出登录',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
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

  void _showTgBindInfo(BuildContext context, UserProfile user, WidgetRef ref) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => _TgBindSheet(user: user),
    ).whenComplete(() {
        ref.read(authProvider.notifier).refreshProfile();
    });
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确认要退出当前账号吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('缓存已清除'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── 子组件 ─────────────────────────────────────────────────────────────────

class _UserHeaderCard extends StatelessWidget {
  final UserProfile user;
  const _UserHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 头像
            _Avatar(avatarUrl: user.avatarUrl, name: user.name),
            const SizedBox(width: 16),
            // 用户信息
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
  final String name;
  const _Avatar({this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
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
          ? Center(child: Text(initials,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
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
    final theme   = Theme.of(context);
    final isUnlim = user.aiQuotaMonthly == -1;
    final percent = user.aiQuotaPercent;
    final color   = percent > 0.9
        ? Colors.red
        : percent > 0.7
            ? Colors.orange
            : theme.colorScheme.primary;
    final resetDate = DateFormat('MM月dd日').format(user.quotaResetDate);

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
                  const Text('AI 使用配额',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
                if (!isUnlim)
                  Text('$resetDate 重置',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 16),
            if (isUnlim) ...[
              Row(children: [
                Icon(Icons.all_inclusive, size: 20, color: color),
                const SizedBox(width: 8),
                Text('无限制', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: color)),
              ]),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('已使用 ${user.aiQuotaUsed} 次',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  Text('共 ${user.aiQuotaMonthly} 次/月',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
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
              const SizedBox(height: 8),
              if (percent >= 0.9)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('配额即将用尽，请联系管理员',
                      style: TextStyle(
                          fontSize: 12, color: Colors.red.shade700)),
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
  Widget build(BuildContext context) {
    return Column(
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
}

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
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(label, style: const TextStyle(fontSize: 15)),
        trailing: trailing ??
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
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
      final resp = await ref.read(meApiProvider).requestTgBindCode();
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
      await ref.read(meApiProvider).deleteTgBind();
      await ref.read(authProvider.notifier).refreshProfile();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // 标题行
          Row(children: [
            Icon(Icons.telegram, color: const Color(0xFF2AABEE), size: 24),
            const SizedBox(width: 8),
            const Text('Telegram 绑定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(_error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
            const SizedBox(height: 12),
          ],

          if (isBound) ...[
            // 已绑定状态
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text('已绑定 Telegram #${widget.user.tgUserId}',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 8),
            Text('绑定后 Bot 和 App 共享 AI 使用配额',
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
                  : const Text('解除绑定'),
            ),
          ] else ...[
            // 未绑定状态
            Text('绑定后 Bot 下载/识别与 App 共享同一个 AI 配额，统一管理更方便。',
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 20),

            if (_code != null) ...[
              // 显示验证码
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(children: [
                  Text('验证码', style: TextStyle(
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
                  Text('10 分钟内有效', style: TextStyle(
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
                  '前往 Telegram Bot，发送：\n/bind $_code',
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
                child: const Text('刷新验证码'),
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
                  label: const Text('申请绑定码',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}