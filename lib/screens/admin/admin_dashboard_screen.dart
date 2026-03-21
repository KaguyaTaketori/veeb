// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/admin_api.dart';
import '../../l10n/app_localizations.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen>
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(l10n.adminConsole,
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(icon: Icon(Icons.bar_chart), text: l10n.dataDashboard),
            Tab(icon: Icon(Icons.tune), text: l10n.systemConfig),
            Tab(icon: Icon(Icons.people), text: l10n.userManagement),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _StatsTab(),
          _ConfigTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}


// ============================================================
// Tab 1：全局数据看板
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
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(adminApiProvider).getStats();
      setState(() { _stats = data; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);

    final s = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(l10n.userOverview),
          const SizedBox(height: 12),
          _StatsGrid(items: [
            _StatCard(label: l10n.totalUsers,  value: '${s['total_users']}',  icon: Icons.people,        color: Colors.blue),
            _StatCard(label: l10n.activeUsers,  value: '${s['active_users']}', icon: Icons.check_circle,  color: Colors.green),
            _StatCard(label: l10n.adminCount,  value: '${s['admin_count']}',  icon: Icons.admin_panel_settings, color: Colors.orange),
            _StatCard(label: l10n.wsOnline,   value: '${s['online_ws_users']}', icon: Icons.wifi,        color: Colors.teal),
          ]),
          const SizedBox(height: 24),
          _SectionTitle(l10n.billOverview),
          const SizedBox(height: 12),
          _StatsGrid(items: [
            _StatCard(label: l10n.totalBills,    value: '${s['total_bills']}',         icon: Icons.receipt_long,    color: Colors.purple),
            _StatCard(label: l10n.billsThisMonth,    value: '${s['bills_this_month']}',    icon: Icons.calendar_month,  color: Colors.pink),
            _StatCard(label: l10n.aiUsageThisMonth, value: l10n.aiUsageCountTimes(s['ai_quota_used_this_month'] as int), icon: Icons.auto_awesome, color: Colors.amber),
            _StatCard(label: l10n.wsConnections,  value: '${s['total_ws_connections']}', icon: Icons.cable,           color: Colors.cyan),
          ]),
          const SizedBox(height: 32),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
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
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(adminApiProvider).listConfigs();
      final list = data['configs'] as List? ?? [];
      setState(() {
        _configs = list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editConfig(Map<String, dynamic> config) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(
        text: config['config_value'] as String? ?? '');
    final key  = config['config_key'] as String;
    final desc = config['description'] as String? ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(key, style: const TextStyle(fontSize: 15,
            fontFamily: 'monospace')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desc.isNotEmpty) ...[
              Text(desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: ctrl,
              maxLines: null,
              decoration: InputDecoration(
                labelText: l10n.configValue,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save)),
        ],
      ),
    );

    ctrl.dispose();
    if (saved != true) return;

    try {
      await ref.read(adminApiProvider).upsertConfig(key, ctrl.text.trim());
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.layoutUpdated), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateFailed(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _configs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final cfg = _configs[i];
          final key  = cfg['config_key']   as String;
          final val  = cfg['config_value'] as String? ?? '';
          final desc = cfg['description']  as String? ?? '';

          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(key,
                  style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(val.isEmpty ? l10n.empty : val,
                      style: TextStyle(
                          fontSize: 14,
                          color: val.isEmpty
                              ? Colors.grey[400]
                              : Colors.black87)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500])),
                  ],
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
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
// Tab 3：用户管理
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
  int?   _activeFilter;
  int    _page = 1;
  bool   _hasNext = false;

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
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(adminApiProvider).listUsers(
        page: _page,
        keyword: _searchCtrl.text.trim(),
        role: _roleFilter.isEmpty ? null : _roleFilter,
        isActive: _activeFilter,
      );
      final list = (data['users'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _users   = refresh ? list : [..._users, ...list];
        _hasNext = data['has_next'] as bool? ?? false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // 搜索栏 + 筛选器
        _buildToolbar(),
        if (_error != null)
          Expanded(child: _ErrorView(error: _error!, onRetry: () => _load(refresh: true)))
        else if (_loading && _users.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _users.length + (_hasNext ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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

  Widget _buildToolbar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // 搜索框
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: l10n.searchEmailUsername,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _load(refresh: true);
                      })
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _load(refresh: true),
          ),
          const SizedBox(height: 8),
          // 角色 / 状态筛选
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.all,
                  selected: _roleFilter.isEmpty && _activeFilter == null,
                  onTap: () {
                    _roleFilter   = '';
                    _activeFilter = null;
                    _load(refresh: true);
                  },
                ),
                _FilterChip(
                  label: l10n.admin,
                  selected: _roleFilter == 'admin',
                  onTap: () {
                    _roleFilter   = _roleFilter == 'admin' ? '' : 'admin';
                    _load(refresh: true);
                  },
                ),
                _FilterChip(
                  label: l10n.banned,
                  selected: _activeFilter == 0,
                  color: Colors.red,
                  onTap: () {
                    _activeFilter = _activeFilter == 0 ? null : 0;
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? c : Colors.transparent, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? c : Colors.grey[700])),
      ),
    );
  }
}


// ── 用户卡片 ──────────────────────────────────────────────────────────────

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
  int    get userId   => u['id'] as int;
  bool   get isActive => (u['is_active'] as bool?) ?? true;
  String get role     => u['role'] as String? ?? 'user';
  String get name     => (u['display_name'] as String?)?.isNotEmpty == true
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
      await ref.read(adminApiProvider).setUserActive(
            userId, isActive: !isActive);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.operationFailed(e.toString())),
              backgroundColor: Colors.red),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
    final statusColor = isActive ? Colors.green : Colors.red;
    final roleColor   = role == 'admin' ? Colors.orange : Colors.grey;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isActive
                ? Colors.grey.withOpacity(0.2)
                : Colors.red.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：名称 + 状态角标 + 封禁开关
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(width: 8),
                          // 角色角标
                          _Badge(
                            label: role == 'admin' ? l10n.admin : l10n.username,
                            color: roleColor,
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            _Badge(label: l10n.banned, color: Colors.red),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        u['email'] as String? ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // 封禁 Switch
                _toggling
                    ? const SizedBox(
                        width: 32, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: isActive,
                        onChanged: (_) => _toggleActive(),
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
              ],
            ),
            const SizedBox(height: 10),
            // 中间：IP 信息
            _InfoRow(Icons.location_on_outlined,
                AppLocalizations.of(context)!.registrationIp(u['registration_ip'] ?? '—')),
            const SizedBox(height: 2),
            _InfoRow(Icons.history,
                AppLocalizations.of(context)!.lastIp(u['last_login_ip'] ?? '—')),
            const SizedBox(height: 10),
            // 权限标签行
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (perms.isEmpty)
                  _Badge(label: l10n.noPermission, color: Colors.grey)
                else
                  ...perms.map((p) => _Badge(
                        label: _permLabel(p),
                        color: Theme.of(context).colorScheme.primary,
                      )),
              ],
            ),
            const SizedBox(height: 12),
            // 底部操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                          color: Colors.grey.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showPermissionsSheet,
                    icon: const Icon(Icons.tune, size: 16),
                    label: Text(l10n.configPermission,
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _permLabel(String perm) {
    final l10n = AppLocalizations.of(context)!;
    return switch (perm) {
      'bot_text'     => l10n.botTextLabel,
      'bot_receipt'  => l10n.botReceiptLabel,
      'bot_voice'    => l10n.botVoiceLabel,
      'bot_download' => l10n.botDownloadLabel,
      'app_ocr'      => l10n.appOcrLabel,
      'app_export'   => l10n.appExportLabel,
      'app_upload'   => l10n.appUploadLabel,
      _              => perm,
    };
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600)),
      );
}


// ============================================================
// 权限配置抽屉
// ============================================================

class _PermissionsSheet extends ConsumerStatefulWidget {
  final int      userId;
  final String   userName;
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
    ('bot_text',     l10n.botText,     Icons.text_fields),
    ('bot_receipt',  l10n.botReceipt,  Icons.camera_alt_outlined),
    ('bot_voice',    l10n.botVoice,    Icons.mic_outlined),
    ('bot_download', l10n.botDownload, Icons.download_outlined),
    ('app_ocr',      l10n.appOcr,     Icons.document_scanner_outlined),
    ('app_export',   l10n.appExport,  Icons.file_download_outlined),
    ('app_upload',   l10n.appUpload,   Icons.upload_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.currentPerms);
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(adminApiProvider).setUserPermissions(
            widget.userId, _selected.toList());
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          // 拖拽把手
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.tune,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.configPermission,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(widget.userName,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                // 全选 / 清空
                TextButton(
                  onPressed: () {
                    final perms = _getPerms(l10n);
                    setState(() => _selected =
                        _selected.length == perms.length
                            ? {}
                            : perms.map((e) => e.$1).toSet());
                  },
                  child: Text(
                      _selected.length == _getPerms(l10n).length ? l10n.clearAll : l10n.selectAll),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(_error!,
                  style: TextStyle(
                      color: Colors.red.shade700, fontSize: 13)),
            ),
          // 权限多选列表
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _getPerms(l10n).map((entry) {
                final (perm, label, icon) = entry;
                final checked = _selected.contains(perm);
                return Card(
                  elevation: 0,
                  color: checked
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
                      : Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: checked
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3)
                          : Colors.grey.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: checked,
                    onChanged: (v) => setState(() =>
                        v! ? _selected.add(perm) : _selected.remove(perm)),
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: checked
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          size: 18,
                          color: checked
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[500]),
                    ),
                    title: Text(label,
                        style: TextStyle(
                            fontWeight: checked
                                ? FontWeight.w600
                                : FontWeight.normal)),
                    subtitle: Text('`$perm`',
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace')),
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),
          // 保存按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          l10n.savePermission(_selected.length),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// 共用错误视图
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87));
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      );
  }
}