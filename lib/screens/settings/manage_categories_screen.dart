import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vee_app/exceptions/app_exception.dart';
import 'package:vee_app/utils/vee_colors.dart';
import 'package:vee_app/widgets/ui_core/vee_button_spinner.dart';
import 'package:vee_app/widgets/ui_core/vee_category_grid.dart';
import 'package:vee_app/widgets/ui_core/vee_selection_grid.dart';
import 'package:vee_app/widgets/ui_core/vee_skeleton_card.dart';
import '../../database/app_database.dart' hide Category;
import '../../models/transaction.dart';
import '../../providers/categories_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
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
      appBar: AppBar(title: const Text('管理分类'), centerTitle: true),
      body: catsAsync.when(
        loading: () => ListView(
          padding: VeeTokens.cardPadding,
          children: [
            // 系统分类区块
            VeeSkeletonCard.card(),
            const SizedBox(height: VeeTokens.spacingXs),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: VeeTokens.s12,
              crossAxisSpacing: VeeTokens.s12,
              childAspectRatio: 0.9,
              children: List.generate(8, (_) => VeeSkeletonCard.stat()),
            ),
            const SizedBox(height: VeeTokens.spacingLg),
            // 自定义分类区块
            VeeSkeletonCard.card(),
          ],
        ),
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
              VeeCategoryGrid(categories: system, canDelete: false),
              const SizedBox(height: VeeTokens.spacingLg),
              _SectionHeader('自定义分类', custom.length),
              const SizedBox(height: VeeTokens.spacingXs),
              if (custom.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(VeeTokens.s24),
                  child: Center(
                    child: Text(
                      '暂无自定义分类',
                      style: TextStyle(color: VeeTokens.textPlaceholderVal),
                    ),
                  ),
                )
              else
                VeeCategoryGrid(
                  categories: custom,
                  canDelete: true,
                  onDelete: (cat) => _confirmDeleteCategory(context, ref, cat),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeeTokens.rLg),
        ),
        onPressed: () => _showAddSheet(context, ref, groupId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final ok = await VeeConfirmDialog.showDelete(
      context: context,
      content: '删除「${cat.name}」后，关联流水将归类为「其他」。',
    );
    if (ok != true) return;

    final isLoggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    final db = ref.read(appDatabaseProvider);
    final groupId = ref.read(currentGroupIdProvider);

    if (isLoggedIn && cat.id != 0) {
      try {
        await ref.read(categoriesApiProvider).deleteCategory(cat.id);
      } on AppException catch (e) {
        if (e.statusCode != 404) rethrow;
      }
    }

    await (db.delete(db.categories)..where((c) => c.id.equals(cat.id))).go();

    ref.invalidate(categoriesProvider(groupId));
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, int? groupId) {
    if (groupId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VeeTokens.rXl),
        ),
      ),
      builder: (_) => _AddCategorySheet(groupId: groupId),
    );
  }
}

// ── 区块标题（与原版相同）────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader(this.title, this.count);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: context.veeText.sectionTitle),
      const SizedBox(width: VeeTokens.spacingXs),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VeeTokens.s8,
          vertical: VeeTokens.s2,
        ),
        decoration: BoxDecoration(
          color: VeeTokens.surfaceSunken,
          borderRadius: BorderRadius.circular(VeeTokens.rFull),
        ),
        child: Text(
          '$count',
          style: context.veeText.micro.copyWith(
            color: VeeTokens.textSecondaryVal,
          ),
        ),
      ),
    ],
  );
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

  // 迁移 #2：常量列表保留（作为数据源），渲染逻辑移入组件
  static const _emojis = [
    '🍜',
    '🍕',
    '☕',
    '🚇',
    '🚗',
    '✈️',
    '🛍️',
    '👗',
    '🎮',
    '🎬',
    '🎵',
    '💊',
    '🏠',
    '💡',
    '⛽',
    '🛒',
    '💰',
    '📚',
    '🎓',
    '🐾',
    '🌿',
    '🏋️',
    '💅',
    '🎁',
  ];

  static const _colors = [
    '#E85D30',
    '#3B8BD4',
    '#1D9E75',
    '#EF9F27',
    '#9B59B6',
    '#E74C3C',
    '#2ECC71',
    '#1ABC9C',
    '#95A5A6',
    '#F39C12',
    '#16A085',
    '#8E44AD',
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
        await db
            .into(db.categories)
            .insert(
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
        await db
            .into(db.categories)
            .insert(
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

            if (_error != null) VeeErrorBanner(message: _error!),

            // 名称
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '分类名称'),
            ),
            const SizedBox(height: VeeTokens.spacingMd),

            // 收支类型
            Text(
              '类型',
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
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

            // ── emoji 选择器（迁移 #2：Wrap × 24 → VeeEmojiGrid）────────────
            Text(
              '图标',
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
            const SizedBox(height: VeeTokens.spacingXs),
            VeeEmojiGrid(
              emojis: _emojis,
              selectedEmoji: _icon,
              onSelected: (e) => setState(() => _icon = e),
              crossAxisCount: 6, // 与原 Wrap 列数保持视觉一致
            ),
            const SizedBox(height: VeeTokens.spacingMd),

            // ── 颜色选择器（迁移 #2：Wrap × 12 → VeeColorGrid）──────────────
            Text(
              '颜色',
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
            const SizedBox(height: VeeTokens.spacingXs),
            VeeColorGrid(
              colors: _colors,
              selected: _color,
              onSelected: (hex) => setState(() => _color = hex),
            ),
            const SizedBox(height: VeeTokens.spacingLg),

            SizedBox(
              height: VeeTokens.buttonHeight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const VeeButtonSpinner() : const Text('添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
