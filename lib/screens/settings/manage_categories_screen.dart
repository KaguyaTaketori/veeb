import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart' hide Category;
import '../../models/transaction.dart';
import '../../providers/categories_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/group_provider.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    final catsAsync = ref.watch(currentCategoriesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('管理分类'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: catsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (cats) {
          final system = cats.where((c) => c.isSystem).toList();
          final custom = cats.where((c) => !c.isSystem).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader('系统分类', system.length),
              const SizedBox(height: 8),
              _CategoriesGrid(categories: system, canDelete: false),
              const SizedBox(height: 20),
              _SectionHeader('自定义分类', custom.length),
              const SizedBox(height: 8),
              if (custom.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('暂无自定义分类',
                        style: TextStyle(color: Colors.grey[400])),
                  ),
                )
              else
                _CategoriesGrid(
                    categories: custom, canDelete: true),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        onPressed: () =>
            _showAddSheet(context, ref, groupId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(
      BuildContext context, WidgetRef ref, int? groupId) {
    if (groupId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddCategorySheet(groupId: groupId),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader(this.title, this.count);

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[600])),
        ),
      ]);
}

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
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
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
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(c.icon,
                    style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 4),
              Text(c.name,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
            if (canDelete)
              Positioned(
                top: 0, right: 0,
                child: GestureDetector(
                  onTap: () =>
                      _confirmDelete(context, ref, c),
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Category c) async {
    final ok = await showDialog<bool>(...); // 不变
    if (ok != true) return;

    final isLoggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    final db = ref.read(appDatabaseProvider);

    if (isLoggedIn && c.id != 0) {
      try {
        // 调服务端删除
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

// ── 添加分类表单 ─────────────────────────────────────────────────────

class _AddCategorySheet extends ConsumerStatefulWidget {
  final int groupId;
  const _AddCategorySheet({required this.groupId});

  @override
  ConsumerState<_AddCategorySheet> createState() =>
      _AddCategorySheetState();
}

class _AddCategorySheetState
    extends ConsumerState<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  String _icon    = '📦';
  String _type    = 'expense';
  String _color   = '#95A5A6';
  bool   _saving  = false;
  String? _error;

  // 预设 emoji 供选择
  static const _emojis = [
    '🍜','🍕','☕','🚇','🚗','✈️','🛍️','👗',
    '🎮','🎬','🎵','💊','🏠','💡','⛽','🛒',
    '💰','📚','🎓','🐾','🌿','🏋️','💅','🎁',
  ];

  static const _colors = [
    '#E85D30','#3B8BD4','#1D9E75','#EF9F27',
    '#9B59B6','#E74C3C','#2ECC71','#1ABC9C',
    '#95A5A6','#F39C12','#16A085','#8E44AD',
  ];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = '请输入分类名称');
      return;
    }
    setState(() { _saving = true; _error = null; });

    try {
      final isLoggedIn =
          ref.read(authProvider).status == AuthStatus.authenticated;

      if (isLoggedIn) {
        // 登录模式：调 API，返回的 remoteId 写回本地
        final remote = await ref.read(categoriesApiProvider).createCategory({
          'name':       _nameCtrl.text.trim(),
          'icon':       _icon,
          'color':      _color,
          'type':       _type,
          'group_id':   widget.groupId,
          'sort_order': 100,
        });
        // 同时写本地，标记已同步
        final db  = ref.read(appDatabaseProvider);
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            remoteId:  Value(remote.id),
            name:      _nameCtrl.text.trim(),
            icon:      Value(_icon),
            color:     Value(_color),
            type:      Value(_type),
            isSystem:  const Value(false),
            groupId:   Value(widget.groupId),
            sortOrder: const Value(100),
            syncStatus: const Value('synced'),
          ),
        );
      } else {
        // Guest 模式：只写本地
        final db  = ref.read(appDatabaseProvider);
        await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            name:      _nameCtrl.text.trim(),
            icon:      Value(_icon),
            color:     Value(_color),
            type:      Value(_type),
            isSystem:  const Value(false),
            groupId:   Value(widget.groupId),
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
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('添加分类',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Text(_error!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 13)),
              const SizedBox(height: 12),
            ],

            // 名称
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '分类名称',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // 收支类型
            const Text('类型',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('支出')),
                ButtonSegment(value: 'income',  label: Text('收入')),
                ButtonSegment(value: 'both',    label: Text('通用')),
              ],
              selected: {_type},
              onSelectionChanged: (s) =>
                  setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            // emoji
            const Text('图标',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _emojis.map((e) {
                final selected = _icon == e;
                return GestureDetector(
                  onTap: () => setState(() => _icon = e),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(e,
                        style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 颜色
            const Text('颜色',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _colors.map((c) {
                final color = Color(
                    int.parse(c.replaceFirst('#', '0xFF')));
                final selected = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Colors.white, width: 2)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 6)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14))),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Text('添加',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}