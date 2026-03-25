// lib/screens/settings/manage_categories_screen.dart
//
// 变更说明（引入 skeletonizer）：
//   - loading 回调不再维护一套平行的假布局（VeeSkeletonCard.card / .stat）
//   - 改为 Skeletonizer(enabled: true) 包裹真实 Widget + 占位数据
//   - 骨架效果自动从真实 Widget 树生成，结构永远与真实 UI 同步

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:vee_app/exceptions/app_exception.dart';
import 'package:vee_app/utils/vee_colors.dart';
import 'package:vee_app/widgets/ui_core/vee_button_spinner.dart';
import 'package:vee_app/widgets/ui_core/vee_category_grid.dart';
import 'package:vee_app/widgets/ui_core/vee_selection_grid.dart';
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

// ── 骨架占位数据 ──────────────────────────────────────────────────────────────
// Skeletonizer 会自动对这些 Widget 应用闪烁效果；
// 文字内容会被矩形替代，emoji 会被圆圈替代。
// 不再需要手动创建"假"卡片布局。

const _kFakeCategoryName = 'BonePlaceholder';

List<Category> _fakeCategoryList(int count, String type) => List.generate(
  count,
  (i) => Category(
    id: -(i + 1),
    name: _kFakeCategoryName,
    icon: '📦',
    color: '#95A5A6',
    type: type,
    isSystem: true,
    sortOrder: i,
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// ManageCategoriesScreen
// ─────────────────────────────────────────────────────────────────────────────

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    final catsAsync = ref.watch(currentCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('管理分类'), centerTitle: true),
      body: catsAsync.when(
        // ── loading：Skeletonizer 包裹真实布局 + 占位数据 ──────────────────
        // 替代原来的 VeeSkeletonCard.card() + GridView(VeeSkeletonCard.stat())
        // 骨架结构与真实 UI 完全一致，不会出现"假卡和真卡布局不一样"的问题
        loading: () => Skeletonizer(
          enabled: true,
          containersColor: VeeTokens.surfaceSunken,
          child: _buildBody(
            context: context,
            systemCats: _fakeCategoryList(8, 'expense'),
            customCats: _fakeCategoryList(3, 'expense'),
            ref: ref,
            canInteract: false,
          ),
        ),

        error: (e, _) => VeeEmptyState(
          icon: Icons.error_outline,
          title: e.toString(),
          iconColor: VeeTokens.error,
        ),

        data: (cats) {
          final system = cats.where((c) => c.isSystem).toList();
          final custom = cats.where((c) => !c.isSystem).toList();
          return _buildBody(
            context: context,
            systemCats: system,
            customCats: custom,
            ref: ref,
            canInteract: true,
            groupId: groupId,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeeTokens.rLg),
        ),
        onPressed: groupId != null
            ? () => _showAddSheet(context, ref, groupId)
            : null,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── 主体布局（loading 和 data 共用）────────────────────────────────────────

  Widget _buildBody({
    required BuildContext context,
    required List<Category> systemCats,
    required List<Category> customCats,
    required WidgetRef ref,
    required bool canInteract,
    int? groupId,
  }) {
    return ListView(
      padding: VeeTokens.cardPadding,
      children: [
        _SectionHeader('系统分类', systemCats.length),
        const SizedBox(height: VeeTokens.spacingXs),
        VeeCategoryGrid(categories: systemCats, canDelete: false),
        const SizedBox(height: VeeTokens.spacingLg),
        _SectionHeader('自定义分类', customCats.length),
        const SizedBox(height: VeeTokens.spacingXs),
        if (customCats.isEmpty && canInteract)
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
            categories: customCats,
            canDelete: canInteract,
            onDelete: canInteract && groupId != null
                ? (cat) => _confirmDeleteCategory(context, ref, cat, groupId)
                : null,
          ),
      ],
    );
  }

  // ── 删除确认（与原版相同）──────────────────────────────────────────────────

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category cat,
    int groupId,
  ) async {
    final ok = await VeeConfirmDialog.showDelete(
      context: context,
      content: '删除「${cat.name}」后，关联流水将归类为「其他」。',
    );
    if (ok != true) return;

    final isLoggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    final db = ref.read(appDatabaseProvider);

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

  void _showAddSheet(BuildContext context, WidgetRef ref, int groupId) {
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

// ── 添加分类 Sheet（与原版相同）──────────────────────────────────────────────

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

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '分类名称'),
            ),
            const SizedBox(height: VeeTokens.spacingMd),

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
              crossAxisCount: 6,
            ),
            const SizedBox(height: VeeTokens.spacingMd),

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
