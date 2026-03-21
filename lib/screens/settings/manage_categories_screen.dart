import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart' hide Category;
import '../../models/transaction.dart';
import '../../providers/categories_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/client.dart';
import '../../api/transactions_api.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_empty_state.dart';
import '../../widgets/ui_core/vee_confirm_dialog.dart';
import '../../widgets/ui_core/vee_error_banner.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    final catsAsync = ref.watch(currentCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理分类'),
        centerTitle: true,
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => VeeEmptyState(
          icon: Icons.error_outline,
          title: e.toString(),
          iconColor: VeeTokens.error,
        ),
        data: (cats) {
          final system = cats.where((c) => c.isSystem).toList();
          final custom = cats.where((c) => !c.isSystem).toList();
          return ListView(
            padding: VeeTokens.cardPadding,
            children: [
              _SectionHeader('系统分类', system.length),
              const SizedBox(height: VeeTokens.spacingXs),
              _CategoriesGrid(categories: system, canDelete: false),
              const SizedBox(height: VeeTokens.spacingLg),
              _SectionHeader('自定义分类', custom.length),
              const SizedBox(height: VeeTokens.spacingXs),
              if (custom.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(VeeTokens.s24),
                  child: Center(
                    child: Text(
                      '暂无自定义分类',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                )
              else
                _CategoriesGrid(categories: custom, canDelete: true),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VeeTokens.rLg)),
        onPressed: () => _showAddSheet(context, ref, groupId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, int? groupId) {
    if (groupId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(VeeTokens.rXl))),
      builder: (_) => _AddCategorySheet(groupId: groupId),
    );
  }
}

// ── 区块标题 ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader(this.title, this.count);

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: context.veeText.sectionTitle),
        const SizedBox(width: VeeTokens.spacingXs),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: VeeTokens.s8, vertical: VeeTokens.s2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(VeeTokens.rFull),
          ),
          child: Text(
            '$count',
            style: context.veeText.micro.copyWith(color: Colors.grey[600]),
          ),
        ),
      ]);
}

// ── 分类网格 ──────────────────────────────────────────────────────────────────

class _CategoriesGrid extends ConsumerWidget {
  final List<Category> categories;
  final bool canDelete;
  const _CategoriesGrid(
      {required this.categories, required this.canDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: VeeTokens.s12,
        crossAxisSpacing: VeeTokens.s12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final c = categories[i];
        final color = _parseColor(c.color);
        return Stack(
          children: [
            Column(children: [
              Container(
                width: VeeTokens.s56,
                height: VeeTokens.s56,
                decoration: BoxDecoration(
                  color: VeeTokens.selectedTint(color),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(c.icon,
                    style: TextStyle(fontSize: VeeTokens.iconXl - 2)),
              ),
              const SizedBox(height: VeeTokens.spacingXxs),
              Text(c.name,
                  style: context.veeText.micro,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
            if (canDelete)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _confirmDelete(context, ref, c),
                  child: Container(
                    width: VeeTokens.s20,
                    height: VeeTokens.s20,
                    decoration: const BoxDecoration(
                      color: VeeTokens.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: VeeTokens.iconXs, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _parseColor(String colorStr) {
    final hex = colorStr.replaceFirst('#', '0xFF');
    return Color(int.parse(hex));
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Category c) async {
    final ok = await VeeConfirmDialog.showDelete(
      context: context,
      content: '删除分类"${c.name}"？',
    );
    if (ok != true) return;

    final isLoggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    final db = ref.read(appDatabaseProvider);

    if (isLoggedIn && c.id != 0) {
      try {
        final dio = ref.read(apiClientProvider);
        await dio.delete('/categories/${c.id}');
      } catch (e) {
        // 服务端失败时仍删本地，下次同步处理
      }
    }

    await (db.delete(db.categories)
          ..where((t) => t.id.equals(c.id)))
        .go();

    final groupId = ref.read(currentGroupIdProvider);
    ref.invalidate(categoriesProvider(groupId));
  }
}

// ── 添加分类表单 ──────────────────────────────────────────────────────────────

class _AddCategorySheet extends ConsumerStatefulWidget {
  final int groupId;
  const _AddCategorySheet({required this.groupId});

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '📦';
  String _type = 'expense';
  String _color = '#95A5A6';
  bool _saving = false;
  String? _error;

  static const _emojis = [
    '🍜', '🍕', '☕', '🚇', '🚗', '✈️', '🛍️', '👗',
    '🎮', '🎬', '🎵', '💊', '🏠', '💡', '⛽', '🛒',
    '💰', '📚', '🎓', '🐾', '🌿', '🏋️', '💅', '🎁',
  ];

  static const _colors = [
    '#E85D30', '#3B8BD4', '#1D9E75', '#EF9F27',
    '#9B59B6', '#E74C3C', '#2ECC71', '#1ABC9C',
    '#95A5A6', '#F39C12', '#16A085', '#8E44AD',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = '请输入分类名称');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final isLoggedIn =
          ref.read(authProvider).status == AuthStatus.authenticated;

      if (isLoggedIn) {
        final remote = await ref.read(categoriesApiProvider).createCategory({
          'name': _nameCtrl.text.trim(),
          'icon': _icon,
          'color': _color,
          'type': _type,
          'group_id': widget.groupId,
          'sort_order': 100,
        });
        final db = ref.read(appDatabaseProvider);
        await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            remoteId: Value(remote.id),
            name: _nameCtrl.text.trim(),
            icon: Value(_icon),
            color: Value(_color),
            type: Value(_type),
            isSystem: const Value(false),
            groupId: Value(widget.groupId),
            sortOrder: const Value(100),
            syncStatus: const Value('synced'),
          ),
        );
      } else {
        final db = ref.read(appDatabaseProvider);
        await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            name: _nameCtrl.text.trim(),
            icon: Value(_icon),
            color: Value(_color),
            type: Value(_type),
            isSystem: const Value(false),
            groupId: Value(widget.groupId),
            sortOrder: const Value(100),
            syncStatus: const Value('pending_create'),
          ),
        );
      }

      ref.invalidate(categoriesProvider(widget.groupId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VeeTokens.sheetPadding(context),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('添加分类', style: context.veeText.sectionTitle),
            const SizedBox(height: VeeTokens.spacingLg),

            if (_error != null) ...[
              VeeErrorBanner(message: _error!),
            ],

            // 名称
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '分类名称'),
            ),
            const SizedBox(height: VeeTokens.spacingMd),

            // 收支类型
            Text('类型', style: context.veeText.caption.copyWith(color: Colors.grey)),
            const SizedBox(height: VeeTokens.spacingXs),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('支出')),
                ButtonSegment(value: 'income', label: Text('收入')),
                ButtonSegment(value: 'both', label: Text('通用')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: VeeTokens.spacingMd),

            // emoji
            Text('图标', style: context.veeText.caption.copyWith(color: Colors.grey)),
            const SizedBox(height: VeeTokens.spacingXs),
            Wrap(
              spacing: VeeTokens.spacingXs,
              runSpacing: VeeTokens.spacingXs,
              children: _emojis.map((e) {
                final selected = _icon == e;
                return GestureDetector(
                  onTap: () => setState(() => _icon = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? VeeTokens.selectedTint(
                              Theme.of(context).colorScheme.primary)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(VeeTokens.rSm),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: VeeTokens.spacingMd),

            // 颜色
            Text('颜色', style: context.veeText.caption.copyWith(color: Colors.grey)),
            const SizedBox(height: VeeTokens.spacingXs),
            Wrap(
              spacing: VeeTokens.spacingXs,
              runSpacing: VeeTokens.spacingXs,
              children: _colors.map((c) {
                final color = Color(int.parse(c.replaceFirst('#', '0xFF')));
                final selected = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(
                              color: VeeTokens.overlayTint(color),
                              blurRadius: 6)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: VeeTokens.iconSm)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: VeeTokens.spacingLg),

            SizedBox(
              height: VeeTokens.buttonHeight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: VeeTokens.iconMd,
                        height: VeeTokens.iconMd,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}