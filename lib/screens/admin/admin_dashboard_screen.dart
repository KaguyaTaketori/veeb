// lib/screens/admin/admin_dashboard_screen.dart
//
// 变更说明（Bug Fix #2）：
//   - _ConfigTabState._editConfig：
//     原代码在 `ctrl.dispose()` 之后仍然使用 `ctrl.text`，
//     这会导致在某些 Flutter 版本中抛出"used after dispose"异常。
//     修复：在 dispose 前将文本值保存到局部变量 `savedText`，
//     之后使用 savedText 代替 ctrl.text。
//   - 其余逻辑、样式与原版完全一致。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vee_app/widgets/ui_core/vee_detail_row.dart';
import 'package:vee_app/widgets/ui_core/vee_skeleton_card.dart';
import '../../api/admin_api.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_empty_state.dart';
import '../../widgets/ui_core/vee_chip.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import 'package:vee_app/widgets/ui_core/vee_badge.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminConsole,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(icon: const Icon(Icons.bar_chart), text: l10n.dataDashboard),
            Tab(icon: const Icon(Icons.tune), text: l10n.systemConfig),
            Tab(icon: const Icon(Icons.people), text: l10n.userManagement),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_StatsTab(), _ConfigTab(), _UsersTab()],
      ),
    );
  }
}

// ============================================================
// Tab 1：全局数据看板（与原版完全相同）
// ============================================================

class _StatsTab extends ConsumerStatefulWidget {
  const _StatsTab();

  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(adminApiProvider).getStats();
      setState(() => _stats = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return ListView(
        padding: VeeTokens.cardPadding,
        children: [
          Wrap(
            spacing: VeeTokens.s12,
            runSpacing: VeeTokens.s12,
            children: List.generate(
              8,
              (_) => SizedBox(
                width: (MediaQuery.of(context).size.width -
                        VeeTokens.s32 * 2 -
                        VeeTokens.s12) /
                    2,
                height: 88,
                child: VeeSkeletonCard.stat(),
              ),
            ),
          ),
        ],
      );
    }
    if (_error != null) {
      return VeeEmptyState(
        icon: Icons.error_outline,
        title: _error!,
        iconColor: VeeTokens.error,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }

    final s = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: VeeTokens.cardPadding,
        children: [
          _SectionTitle(l10n.userOverview),
          const SizedBox(height: VeeTokens.spacingMd),
          _StatsGrid(
            items: [
              _StatCard(
                label: l10n.totalUsers,
                value: '${s['total_users']}',
                icon: Icons.people,
                color: Colors.blue,
              ),
              _StatCard(
                label: l10n.activeUsers,
                value: '${s['active_users']}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _StatCard(
                label: l10n.adminCount,
                value: '${s['admin_count']}',
                icon: Icons.admin_panel_settings,
                color: Colors.orange,
              ),
              _StatCard(
                label: l10n.wsOnline,
                value: '${s['online_ws_users']}',
                icon: Icons.wifi,
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: VeeTokens.spacingLg),
          _SectionTitle(l10n.billOverview),
          const SizedBox(height: VeeTokens.spacingMd),
          _StatsGrid(
            items: [
              _StatCard(
                label: l10n.totalBills,
                value: '${s['total_bills']}',
                icon: Icons.receipt_long,
                color: Colors.purple,
              ),
              _StatCard(
                label: l10n.billsThisMonth,
                value: '${s['bills_this_month']}',
                icon: Icons.calendar_month,
                color: Colors.pink,
              ),
              _StatCard(
                label: l10n.aiUsageThisMonth,
                value: l10n.aiUsageCountTimes(
                  s['ai_quota_used_this_month'] as int,
                ),
                icon: Icons.auto_awesome,
                color: Colors.amber,
              ),
              _StatCard(
                label: l10n.wsConnections,
                value: '${s['total_ws_connections']}',
                icon: Icons.cable,
                color: Colors.cyan,
              ),
            ],
          ),
          const SizedBox(height: VeeTokens.spacingXxl),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatCard> items;
  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
        spacing: VeeTokens.s12,
        runSpacing: VeeTokens.s12,
        children: items
            .map((item) => SizedBox(
                  width: (MediaQuery.of(context).size.width -
                          VeeTokens.s32 * 2 -
                          VeeTokens.s12) /
                      2,
                  height: 88,
                  child: item,
                ))
            .toList(),
      );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 迁移 #3：用 VeeCard.stat() 工厂替代手动设置 backgroundColor + borderColor
    return VeeCard.stat(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: VeeTokens.iconLg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: context.veeText.amountMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                style: context.veeText.micro.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Tab 2：系统配置
// ============================================================

class _ConfigTab extends ConsumerStatefulWidget {
  const _ConfigTab();

  @override
  ConsumerState<_ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<_ConfigTab> {
  List<Map<String, dynamic>> _configs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(adminApiProvider).listConfigs();
      final list = data['configs'] as List? ?? [];
      setState(() => _configs = list.cast<Map<String, dynamic>>());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editConfig(Map<String, dynamic> config) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(
      text: config['config_value'] as String? ?? '',
    );
    final key = config['config_key'] as String;
    final desc = config['description'] as String? ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          key,
          style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desc.isNotEmpty) ...[
              Text(
                desc,
                style: context.veeText.micro.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: VeeTokens.s12),
            ],
            TextField(
              controller: ctrl,
              maxLines: null,
              decoration: InputDecoration(labelText: l10n.configValue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    // ── Bug Fix #2 ────────────────────────────────────────────────────────
    // 原代码：
    //   ctrl.dispose();           // ← controller 已销毁
    //   if (saved != true) return;
    //   await _api.upsertConfig(key, ctrl.text.trim()); // ← 使用已销毁的 ctrl ❌
    //
    // 修复：在 dispose 前把文本值存入局部变量，后续使用该变量。
    final textToSave = ctrl.text.trim(); // ← 先保存值
    ctrl.dispose(); // ← 再销毁控制器

    if (saved != true) return;

    try {
      await ref.read(adminApiProvider).upsertConfig(key, textToSave); // ← 用局部变量
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.layoutUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.updateFailed(e.toString())),
            backgroundColor: VeeTokens.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return VeeEmptyState(
        icon: Icons.error_outline,
        title: _error!,
        iconColor: VeeTokens.error,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: VeeTokens.cardPadding,
        itemCount: _configs.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: VeeTokens.spacingXs),
        itemBuilder: (_, i) {
          final cfg = _configs[i];
          final key = cfg['config_key'] as String;
          final val = cfg['config_value'] as String? ?? '';
          final desc = cfg['description'] as String? ?? '';

          return VeeCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: VeeTokens.s16,
                vertical: VeeTokens.spacingXs,
              ),
              title: Text(
                key,
                style: context.veeText.monoLabel.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: VeeTokens.spacingXxs),
                  Text(
                    val.isEmpty ? l10n.empty : val,
                    style: context.veeText.bodyDefault.copyWith(
                      color: val.isEmpty
                          ? VeeTokens.textPlaceholderVal
                          : VeeTokens.textPrimaryVal,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: VeeTokens.spacingXxs),
                    Text(
                      desc,
                      style: context.veeText.micro.copyWith(
                        color: VeeTokens.textPlaceholderVal,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined, size: VeeTokens.iconMd),
                onPressed: () => _editConfig(cfg),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Tab 3：用户管理（与原版完全相同）
// ============================================================

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _roleFilter = '';
  int? _activeFilter;
  int _page = 1;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(adminApiProvider)
          .listUsers(
            page: _page,
            keyword: _searchCtrl.text.trim(),
            role: _roleFilter.isEmpty ? null : _roleFilter,
            isActive: _activeFilter,
          );
      final list = (data['users'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() {
        _users = refresh ? list : [..._users, ...list];
        _hasNext = data['has_next'] as bool? ?? false;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildToolbar(l10n),
        if (_error != null)
          Expanded(
            child: VeeEmptyState(
              icon: Icons.error_outline,
              title: _error!,
              iconColor: VeeTokens.error,
              actionLabel: l10n.retry,
              onAction: () => _load(refresh: true),
            ),
          )
        else if (_loading && _users.isEmpty)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: VeeTokens.s16, vertical: VeeTokens.spacingXs),
              children: List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: VeeTokens.spacingXs),
                child: VeeSkeletonCard.card(),
              )),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  VeeTokens.s16,
                  0,
                  VeeTokens.s16,
                  VeeTokens.s16,
                ),
                itemCount: _users.length + (_hasNext ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: VeeTokens.spacingXs),
                itemBuilder: (_, i) {
                  if (i == _users.length) {
                    return FilledButton.tonal(
                      onPressed: () {
                        _page++;
                        _load();
                      },
                      child: Text(l10n.loadMore),
                    );
                  }
                  return _UserCard(
                    user: _users[i],
                    onRefresh: () => _load(refresh: true),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        VeeTokens.s12,
        VeeTokens.s16,
        VeeTokens.spacingXs,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: l10n.searchEmailUsername,
              prefixIcon: const Icon(Icons.search, size: VeeTokens.iconMd),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: VeeTokens.iconSm),
                      onPressed: () {
                        _searchCtrl.clear();
                        _load(refresh: true);
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _load(refresh: true),
          ),
          const SizedBox(height: VeeTokens.spacingXs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                VeeChip(
                  label: l10n.all,
                  selected: _roleFilter.isEmpty && _activeFilter == null,
                  onTap: () {
                    setState(() {
                      _roleFilter = '';
                      _activeFilter = null;
                    });
                    _load(refresh: true);
                  },
                ),
                const SizedBox(width: VeeTokens.spacingXs),
                VeeChip(
                  label: l10n.admin,
                  selected: _roleFilter == 'admin',
                  onTap: () {
                    setState(
                      () => _roleFilter = _roleFilter == 'admin' ? '' : 'admin',
                    );
                    _load(refresh: true);
                  },
                ),
                const SizedBox(width: VeeTokens.spacingXs),
                VeeChip(
                  label: l10n.banned,
                  selected: _activeFilter == 0,
                  accentColor: VeeTokens.error,
                  onTap: () {
                    setState(
                      () => _activeFilter = _activeFilter == 0 ? null : 0,
                    );
                    _load(refresh: true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 用户卡片（与原版完全相同）────────────────────────────────────────────────

class _UserCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;
  const _UserCard({required this.user, required this.onRefresh});

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  bool _toggling = false;

  Map<String, dynamic> get u => widget.user;
  int get userId => u['id'] as int;
  bool get isActive => (u['is_active'] as bool?) ?? true;
  String get role => u['role'] as String? ?? 'user';
  String get name => (u['display_name'] as String?)?.isNotEmpty == true
      ? u['display_name'] as String
      : (u['app_username'] as String? ?? 'ID:$userId');

  List<String> get perms {
    final raw = u['permissions'];
    if (raw is List) return raw.cast<String>();
    return [];
  }

  Future<void> _toggleActive() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _toggling = true);
    try {
      await ref
          .read(adminApiProvider)
          .setUserActive(userId, isActive: !isActive);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.operationFailed(e.toString())),
            backgroundColor: VeeTokens.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  void _showPermissionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VeeTokens.rXl),
        ),
      ),
      builder: (_) => _PermissionsSheet(
        userId: userId,
        userName: name,
        currentPerms: perms,
        onSaved: widget.onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roleColor = role == 'admin' ? Colors.orange : Colors.grey;

    return VeeCard(
      borderColor: isActive ? null : VeeTokens.strongTint(VeeTokens.error),
      padding: VeeTokens.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: context.veeText.cardTitle),
                        const SizedBox(width: VeeTokens.spacingXs),
                        VeeBadge(
                          label: role == 'admin' ? l10n.admin : l10n.username,
                          color: roleColor,
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: VeeTokens.spacingXxs),
                          VeeBadge(label: l10n.banned, color: VeeTokens.error),
                        ],
                      ],
                    ),
                    const SizedBox(height: VeeTokens.s2),
                    Text(
                      u['email'] as String? ?? '',
                      style: context.veeText.micro.copyWith(
                        color: VeeTokens.textPlaceholderVal,
                      ),
                    ),
                  ],
                ),
              ),
              _toggling
                  ? const SizedBox(
                      width: 32,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: isActive,
                      onChanged: (_) => _toggleActive(),
                      activeColor: VeeTokens.success,
                      inactiveThumbColor: VeeTokens.error,
                    ),
            ],
          ),
          const SizedBox(height: VeeTokens.s10),
          VeeDetailRow(
            icon: Icons.location_on_outlined,
            label: 'Reg IP',
            value: u['registration_ip'] ?? '—',
          ),
          const SizedBox(height: VeeTokens.s2),
          VeeDetailRow(
            icon: Icons.history,
            label: 'Last IP',
            value: u['last_login_ip'] ?? '—',
          ),
          const SizedBox(height: VeeTokens.s10),
          Wrap(
            spacing: VeeTokens.spacingXxs,
            runSpacing: VeeTokens.spacingXxs,
            children: perms.isEmpty
                ? [VeeBadge(label: l10n.noPermission, color: Colors.grey)]
                : perms
                      .map(
                        (p) => VeeBadge(
                          label: _permLabel(p),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: VeeTokens.s12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: VeeTokens.spacingXs,
                ),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VeeTokens.rSm),
                ),
              ),
              onPressed: _showPermissionsSheet,
              icon: const Icon(Icons.tune, size: VeeTokens.iconSm),
              label: Text(
                l10n.configPermission,
                style: context.veeText.chipLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _permLabel(String perm) {
    final l10n = AppLocalizations.of(context)!;
    return switch (perm) {
      'bot_text' => l10n.botTextLabel,
      'bot_receipt' => l10n.botReceiptLabel,
      'bot_voice' => l10n.botVoiceLabel,
      'bot_download' => l10n.botDownloadLabel,
      'app_ocr' => l10n.appOcrLabel,
      'app_export' => l10n.appExportLabel,
      'app_upload' => l10n.appUploadLabel,
      _ => perm,
    };
  }
}

// ── 权限配置抽屉（与原版完全相同）────────────────────────────────────────────

class _PermissionsSheet extends ConsumerStatefulWidget {
  final int userId;
  final String userName;
  final List<String> currentPerms;
  final VoidCallback onSaved;

  const _PermissionsSheet({
    required this.userId,
    required this.userName,
    required this.currentPerms,
    required this.onSaved,
  });

  @override
  ConsumerState<_PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends ConsumerState<_PermissionsSheet> {
  late Set<String> _selected;
  bool _saving = false;
  String? _error;

  static List<(String, String, IconData)> _getPerms(AppLocalizations l10n) => [
    ('bot_text', l10n.botText, Icons.text_fields),
    ('bot_receipt', l10n.botReceipt, Icons.camera_alt_outlined),
    ('bot_voice', l10n.botVoice, Icons.mic_outlined),
    ('bot_download', l10n.botDownload, Icons.download_outlined),
    ('app_ocr', l10n.appOcr, Icons.document_scanner_outlined),
    ('app_export', l10n.appExport, Icons.file_download_outlined),
    ('app_upload', l10n.appUpload, Icons.upload_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.currentPerms);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .setUserPermissions(widget.userId, _selected.toList());
      widget.onSaved();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.permissionUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final perms = _getPerms(l10n);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: VeeTokens.spacingXs),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(VeeTokens.s2),
            ),
          ),
          const SizedBox(height: VeeTokens.spacingMd),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VeeTokens.spacingLg,
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: VeeTokens.s10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.configPermission,
                        style: context.veeText.sectionTitle,
                      ),
                      Text(
                        widget.userName,
                        style: context.veeText.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(
                      () => _selected = _selected.length == perms.length
                          ? {}
                          : perms.map((e) => e.$1).toSet(),
                    );
                  },
                  child: Text(
                    _selected.length == perms.length
                        ? l10n.clearAll
                        : l10n.selectAll,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: VeeTokens.spacingMd),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VeeTokens.spacingLg,
                vertical: VeeTokens.spacingXxs,
              ),
              child: VeeErrorBanner(message: _error!),
            ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: VeeTokens.s16),
              children: perms.map((entry) {
                final (perm, label, icon) = entry;
                final checked = _selected.contains(perm);
                return Card(
                  elevation: 0,
                  color: checked
                      ? VeeTokens.surfaceTint(
                          Theme.of(context).colorScheme.primary,
                        )
                      : Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VeeTokens.rMd),
                    side: BorderSide(
                      color: checked
                          ? VeeTokens.pressedTint(
                              Theme.of(context).colorScheme.primary,
                            )
                          : VeeTokens.borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: checked,
                    onChanged: (v) => setState(
                      () => v! ? _selected.add(perm) : _selected.remove(perm),
                    ),
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: checked
                            ? VeeTokens.selectedTint(
                                Theme.of(context).colorScheme.primary,
                              )
                            : VeeTokens.surfaceSunken,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: VeeTokens.iconSm,
                        color: checked
                            ? Theme.of(context).colorScheme.primary
                            : VeeTokens.textPlaceholderVal,
                      ),
                    ),
                    title: Text(
                      label,
                      style: context.veeText.cardTitle.copyWith(
                        fontWeight: checked
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '`$perm`',
                      style: context.veeText.micro.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VeeTokens.rMd),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                VeeTokens.spacingLg,
                VeeTokens.spacingXs,
                VeeTokens.spacingLg,
                VeeTokens.spacingMd,
              ),
              child: SizedBox(
                width: double.infinity,
                height: VeeTokens.buttonHeight,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: VeeTokens.iconMd,
                          height: VeeTokens.iconMd,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.savePermission(_selected.length)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 区块标题（内部复用）──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: context.veeText.sectionTitle);
}
