// lib/screens/transactions/add_edit_transaction_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../utils/currency.dart';
import '../../widgets/ui_core/vee_error_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 明细行草稿（编辑用内部 DTO）
// ─────────────────────────────────────────────────────────────────────────────

class _ItemDraft {
  String name;
  double amount;
  double quantity;
  String itemType; // item / discount / tax

  _ItemDraft({
    this.name = '',
    this.amount = 0,
    this.quantity = 1,
    this.itemType = 'item',
  });

  Map<String, dynamic> toJson() => {
        'name':       name,
        'name_raw':   name,
        'quantity':   quantity,
        'amount':     amount,
        'item_type':  itemType,
        'sort_order': 0,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction; // null = 新建
  final DateTime selectedMonth;
  final bool isReadOnly; // true = 以查看模式打开，可切换到编辑

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    required this.selectedMonth,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();

  // ── 表单状态 ──────────────────────────────────────────────────────────────
  String _type = 'expense';
  String _currencyCode = 'JPY';
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;
  DateTime _txnDate = DateTime.now();
  bool _isPrivate = false;
  String _receiptUrl = '';
  File? _pendingImage;
  bool _uploadingImg = false;
  bool _saving = false;
  String? _error;

  // ── 明细 ──────────────────────────────────────────────────────────────────
  final List<_ItemDraft> _items = [];

  // ── 查看 / 编辑切换 ──────────────────────────────────────────────────────
  late bool _isEditing;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _isEditing = !widget.isReadOnly;

    final t = widget.transaction;
    if (t != null) {
      _type = t.type;
      _currencyCode = t.currencyCode;
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      _categoryId = t.categoryId;
      _txnDate = t.date;
      _isPrivate = t.isPrivate;
      _receiptUrl = t.receiptUrl;
      _amountCtrl.text = t.amount.toStringAsFixed(0);
      _noteCtrl.text = t.note ?? '';
      // 从已有明细初始化草稿
      for (final item in t.items) {
        _items.add(_ItemDraft(
          name:     item.name,
          amount:   item.amount,
          quantity: item.quantity,
          itemType: item.itemType,
        ));
      }
    } else {
      _txnDate = DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month,
          DateTime.now().day);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(AppLocalizations l10n) {
    if (!_isEditing) {
      return AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(l10n.detail,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.edit, style: const TextStyle(fontSize: 15)),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      title: Text(_isEdit ? l10n.edit : l10n.addTransaction),
      centerTitle: true,
      actions: [
        if (_saving || _uploadingImg)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child:
                FilledButton.tonal(onPressed: _save, child: Text(l10n.save)),
          ),
      ],
    );
  }

  // ── 查看模式 body ─────────────────────────────────────────────────────────

  Widget _buildViewBody(AppLocalizations l10n) {
    final t = widget.transaction!;
    final color = _parseColor(t.categoryColor);

    final typeLabel = t.type == 'income'
        ? l10n.income
        : t.type == 'transfer'
            ? l10n.transfer
            : l10n.expense;
    final typeColor = t.type == 'income'
        ? Colors.green
        : t.type == 'transfer'
            ? Colors.blue
            : Colors.red.shade400;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // ── 金额头部 ──────────────────────────────────────────────────
            Column(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(typeLabel,
                    style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              const SizedBox(height: 12),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(t.categoryIcon ?? '📦',
                    style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 12),
              Text(t.categoryName ?? l10n.uncategorized,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(t.currencyCode,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(width: 8),
                  Text(t.formattedAmount,
                      style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: typeColor)),
                ],
              ),
            ]),
            const SizedBox(height: 32),

            // ── 基本信息 ──────────────────────────────────────────────────
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _ViewRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.date,
                      value:
                          '${t.date.year}/${t.date.month.toString().padLeft(2, '0')}/${t.date.day.toString().padLeft(2, '0')}'),
                  if (t.note?.isNotEmpty == true) ...[
                    const Divider(height: 1, indent: 48),
                    _ViewRow(
                        icon: Icons.notes_outlined,
                        label: l10n.note,
                        value: t.note!),
                  ],
                  if (t.isPrivate) ...[
                    const Divider(height: 1, indent: 48),
                    _ViewRow(
                        icon: Icons.lock_outline,
                        label: l10n.private,
                        value: l10n.yes),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 凭证 ──────────────────────────────────────────────────────
            if (t.hasReceipt) ...[
              _SectionTitle(l10n.receiptImages),
              const SizedBox(height: 12),
              _ReceiptImage(url: t.receiptUrl),
              const SizedBox(height: 24),
            ],

            // ── 明细 ──────────────────────────────────────────────────────
            if (t.items.isNotEmpty) ...[
              _SectionTitle(l10n.itemsCount(t.items.length)),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: t.items.map((item) {
                      final isDisc = item.itemType == 'discount';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          Text(isDisc ? '➖' : '•',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(item.name,
                                  style: const TextStyle(fontSize: 13))),
                          Text(
                            '${isDisc ? '-' : ''}${t.currencyCode} ${formatAmount(item.amount.abs(), t.currencyCode)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDisc ? Colors.red : null),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── 删除按钮 ──────────────────────────────────────────────────
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _confirmDelete(context),
                child: Text(l10n.deleteThisRecord,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ── 编辑模式 body ─────────────────────────────────────────────────────────

  Widget _buildEditBody(AppLocalizations l10n) {
    final accountsState = ref.watch(accountsProvider);
    final accounts = accountsState.accounts;
    final categoriesAsync = ref.watch(currentCategoriesProvider);

    if (_accountId == null && accounts.isNotEmpty) {
      Future.microtask(() => setState(() => _accountId = accounts.first.id));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (_error != null) VeeErrorBanner(message: _error!),

              _buildTypeSelector(l10n),
              const SizedBox(height: 20),

              _buildAmountHeader(),
              const SizedBox(height: 20),

              // ── 基本信息卡片 ──────────────────────────────────────────
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    categoriesAsync.when(
                      data: (cats) => _buildCategoryPicker(cats, l10n),
                      loading: () =>
                          ListTile(title: Text(l10n.categoryLoading)),
                      error: (e, _) => ListTile(
                          title: Text(l10n.categoryLoadError(e.toString()))),
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildAccountDropdown(accounts, _accountId, l10n.account,
                        (v) => setState(() => _accountId = v), l10n),
                    if (_type == 'transfer') ...[
                      const Divider(height: 1, indent: 48),
                      _buildAccountDropdown(
                          accounts,
                          _toAccountId,
                          l10n.to,
                          (v) => setState(() => _toAccountId = v),
                          l10n),
                    ],
                    const Divider(height: 1, indent: 48),
                    InkWell(
                      onTap: _pickDate,
                      child: _FormRow(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.date,
                        child: Row(children: [
                          Expanded(
                              child: Text(
                            '${_txnDate.year}/${_txnDate.month.toString().padLeft(2, '0')}/${_txnDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 15),
                          )),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey),
                        ]),
                      ),
                    ),
                    const Divider(height: 1, indent: 48),
                    _FormRow(
                      icon: Icons.notes_outlined,
                      label: l10n.note,
                      child: TextFormField(
                        controller: _noteCtrl,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: l10n.note,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 48),
                    SwitchListTile(
                      secondary: Icon(Icons.lock_outline,
                          color: Colors.grey[500]),
                      title: Text(l10n.private),
                      subtitle: Text(l10n.shareTransactions,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                      value: _isPrivate,
                      onChanged: (v) => setState(() => _isPrivate = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 明细编辑区 ────────────────────────────────────────────
              _buildItemsSection(l10n),
              const SizedBox(height: 16),

              // ── 凭证区 ────────────────────────────────────────────────
              _ReceiptSection(
                pendingFile: _pendingImage,
                receiptUrl: _receiptUrl,
                uploading: _uploadingImg,
                onPickCamera: () => _pickImage(ImageSource.camera),
                onPickGallery: () => _pickImage(ImageSource.gallery),
                onRemove: () =>
                    setState(() {
                      _pendingImage = null;
                      _receiptUrl = '';
                    }),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── 明细编辑区 ────────────────────────────────────────────────────────────

  Widget _buildItemsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('商品明细',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_items.length} 项',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 8),

        // 明细列表
        if (_items.isNotEmpty)
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: _items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (idx > 0) const Divider(height: 1, indent: 16),
                    _ItemEditRow(
                      item: item,
                      currency: _currencyCode,
                      onChanged: () => setState(() {}),
                      onDelete: () => setState(() => _items.removeAt(idx)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 8),

        // 添加明细按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => setState(() => _items.add(_ItemDraft())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加商品'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => setState(
                    () => _items.add(_ItemDraft(itemType: 'discount'))),
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                label: const Text('添加折扣'),
              ),
            ),
          ],
        ),

        // 自动求和提示
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ItemsSumBar(items: _items, currency: _currencyCode),
        ],
      ],
    );
  }

  // ── 类型选择器 ────────────────────────────────────────────────────────────

  Widget _buildTypeSelector(AppLocalizations l10n) {
    final types = [
      ('expense', l10n.expense, Colors.red),
      ('income', l10n.income, Colors.green),
      ('transfer', l10n.transfer, Colors.blue),
    ];
    return Row(
      children: types.map((t) {
        final selected = _type == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _type = t.$1;
              _categoryId = null;
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? t.$3.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? t.$3 : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(t.$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? t.$3 : Colors.grey[600],
                  )),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 分类选择 ──────────────────────────────────────────────────────────────

  Widget _buildCategoryPicker(List<Category> categories, AppLocalizations l10n) {
    final filtered =
        categories.where((c) => c.type == _type || c.type == 'both').toList();
    final selected = filtered.firstWhere(
      (c) => c.id == _categoryId,
      orElse: () => filtered.isEmpty
          ? Category(
              id: -1,
              name: l10n.pleaseSelect,
              icon: '❓',
              color: '#95A5A6',
              type: 'both',
              isSystem: false,
              sortOrder: 0)
          : filtered.first,
    );

    return InkWell(
      onTap: () => _showCategorySheet(filtered, l10n),
      child: _FormRow(
        icon: Icons.category_outlined,
        label: l10n.category,
        child: Row(children: [
          Text(selected.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(selected.name,
                  style: const TextStyle(fontSize: 15))),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }

  void _showCategorySheet(List<Category> categories, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategorySheet(
        categories: categories,
        selectedId: _categoryId,
        onSelected: (id) {
          setState(() => _categoryId = id);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── 账户下拉 ──────────────────────────────────────────────────────────────

  Widget _buildAccountDropdown(List<dynamic> accounts, int? value,
      String label, ValueChanged<int?> onChanged, AppLocalizations l10n) {
    return _FormRow(
      icon: Icons.account_balance_wallet_outlined,
      label: label,
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true),
        icon: const Icon(Icons.chevron_right, color: Colors.grey),
        items: accounts
            .map((a) => DropdownMenuItem<int>(
                  value: a.id as int,
                  child: Text('${a.typeIcon} ${a.name}'),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (_) => value == null ? l10n.required : null,
      ),
    );
  }

  // ── 图片 ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1920);
    if (xfile == null) return;
    setState(() {
      _pendingImage = File(xfile.path);
      _receiptUrl = '';
    });
  }

  Future<String?> _uploadPendingImage() async {
    if (_pendingImage == null) return _receiptUrl;
    setState(() => _uploadingImg = true);
    try {
      final bytes = await _pendingImage!.readAsBytes();
      final filename = _pendingImage!.path.split('/').last;
      final mime = filename.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      return await ref.read(transactionsProvider.notifier).uploadReceipt(
          fileBytes: bytes, filename: filename, mimeType: mime);
    } catch (e) {
      setState(() => _error =
          AppLocalizations.of(context)!.operationFailed(e.toString()));
      return null;
    } finally {
      setState(() => _uploadingImg = false);
    }
  }

  // ── 金额头部 ──────────────────────────────────────────────────────────────

  Widget _buildAmountHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DropdownButton<String>(
          value: _currencyCode,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: ['JPY', 'CNY', 'USD', 'EUR', 'HKD']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _currencyCode = v!),
        ),
        const SizedBox(width: 8),
        IntrinsicWidth(
          child: TextFormField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintText: '0',
            ),
            validator: (v) {
              final l10n = AppLocalizations.of(context)!;
              if (v == null || v.trim().isEmpty) return l10n.required;
              if (double.tryParse(v.trim()) == null) return l10n.error;
              if (double.parse(v.trim()) <= 0) return l10n.error;
              return null;
            },
          ),
        ),
      ],
    );
  }

  // ── 保存 ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = l10n.required);
      return;
    }
    if (_type == 'transfer' && _toAccountId == null) {
      setState(() => _error = l10n.required);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final receiptUrl = await _uploadPendingImage();
      if (_pendingImage != null && receiptUrl == null) return;

      final groupId = ref.read(currentGroupIdProvider)!;
      final amount = double.parse(_amountCtrl.text.trim());
      final txnDate = _txnDate.millisecondsSinceEpoch / 1000.0;
      final note =
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
      final notifier = ref.read(transactionsProvider.notifier);

      // 过滤掉名称为空或金额为0的明细
      final validItems = _items
          .where((i) => i.name.trim().isNotEmpty && i.amount > 0)
          .map((i) => i.toJson())
          .toList();

      if (_isEdit) {
        await notifier.updateTransaction(
          id: widget.transaction!.id,
          type: _type,
          amount: amount,
          currencyCode: _currencyCode,
          accountId: _accountId,
          toAccountId: _toAccountId,
          categoryId: _categoryId,
          isPrivate: _isPrivate,
          note: note,
          transactionDate: txnDate,
          receiptUrl: receiptUrl,
        );
      } else {
        await notifier.createTransaction(
          type: _type,
          amount: amount,
          currencyCode: _currencyCode,
          accountId: _accountId!,
          toAccountId: _toAccountId,
          categoryId: _categoryId!,
          groupId: groupId,
          isPrivate: _isPrivate,
          note: note,
          transactionDate: txnDate,
          receiptUrl: receiptUrl,
          items: validItems,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _txnDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _txnDate = picked);
  }

  Future<void> _confirmDelete(BuildContext ctx) async {
    final l10n = AppLocalizations.of(ctx)!;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.deleteThisRecord),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      await ref
          .read(transactionsProvider.notifier)
          .deleteTransaction(widget.transaction!.id);
      if (ctx.mounted) Navigator.pop(ctx, true);
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(l10n),
      body: _isEditing ? _buildEditBody(l10n) : _buildViewBody(l10n),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 明细行编辑组件
// ─────────────────────────────────────────────────────────────────────────────

class _ItemEditRow extends StatefulWidget {
  final _ItemDraft item;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ItemEditRow({
    required this.item,
    required this.currency,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ItemEditRow> createState() => _ItemEditRowState();
}

class _ItemEditRowState extends State<_ItemEditRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amtCtrl;
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _amtCtrl  = TextEditingController(
        text: widget.item.amount > 0 ? widget.item.amount.toStringAsFixed(0) : '');
    _qtyCtrl  = TextEditingController(
        text: widget.item.quantity == 1.0 ? '1' : widget.item.quantity.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDiscount = widget.item.itemType == 'discount';
    final accentColor = isDiscount ? Colors.red : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // 类型图标
          GestureDetector(
            onTap: () {
              setState(() {
                widget.item.itemType =
                    widget.item.itemType == 'discount' ? 'item' : 'discount';
              });
              widget.onChanged();
            },
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(isDiscount ? '➖' : '•',
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),

          // 商品名称
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: isDiscount ? '折扣/优惠' : '商品名称',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (v) {
                widget.item.name = v;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 4),

          // 数量（仅 item 类型显示）
          if (!isDiscount) ...[
            SizedBox(
              width: 36,
              child: TextField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '×1',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  prefix: Text('×', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
                onChanged: (v) {
                  widget.item.quantity = double.tryParse(v) ?? 1.0;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 4),
          ],

          // 金额
          SizedBox(
            width: 72,
            child: TextField(
              controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDiscount ? Colors.red : null),
              textAlign: TextAlign.right,
              onChanged: (v) {
                widget.item.amount = double.tryParse(v) ?? 0;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 4),

          // 删除
          GestureDetector(
            onTap: widget.onDelete,
            child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ── 明细合计栏 ────────────────────────────────────────────────────────────────

class _ItemsSumBar extends StatelessWidget {
  final List<_ItemDraft> items;
  final String currency;

  const _ItemsSumBar({required this.items, required this.currency});

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    double discount = 0;
    for (final item in items) {
      if (item.itemType == 'discount') {
        discount += item.amount;
      } else {
        subtotal += item.amount * item.quantity;
      }
    }
    final total = subtotal - discount;
    final sym   = currency == 'JPY' ? '¥' : '$currency ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (discount > 0) ...[
            Text('小计 $sym${formatAmount(subtotal, currency)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(width: 8),
            Text('折扣 -$sym${formatAmount(discount, currency)}',
                style: const TextStyle(fontSize: 12, color: Colors.red)),
            const SizedBox(width: 8),
          ],
          Text('合计 ',
              style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Text('$sym${formatAmount(total, currency)}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 查看模式辅助组件
// ─────────────────────────────────────────────────────────────────────────────

class _ViewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ViewRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[500]),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      );
}

class _ReceiptImage extends StatelessWidget {
  final String url;
  const _ReceiptImage({required this.url});
  @override
  Widget build(BuildContext ctx) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(url,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey)),
                )),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 编辑模式辅助组件
// ─────────────────────────────────────────────────────────────────────────────

class _FormRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _FormRow(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[500]),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ),
            Expanded(child: child),
          ],
        ),
      );
}

class _CategorySheet extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;
  const _CategorySheet(
      {required this.categories,
      required this.selectedId,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(l10n.category,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = cat.id == selectedId;
              final color = _parseColor(cat.color);
              return GestureDetector(
                onTap: () => onSelected(cat.id),
                child: Column(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withOpacity(0.2)
                          : color.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: color, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(cat.icon,
                        style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 4),
                  Text(cat.name,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected ? color : Colors.grey[700]),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class _ReceiptSection extends StatelessWidget {
  final File? pendingFile;
  final String receiptUrl;
  final bool uploading;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;
  const _ReceiptSection(
      {required this.pendingFile,
      required this.receiptUrl,
      required this.uploading,
      required this.onPickCamera,
      required this.onPickGallery,
      required this.onRemove});

  bool get _hasImage => pendingFile != null || receiptUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(l10n.scanReceipt,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        if (_hasImage)
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: pendingFile != null
                  ? Image.file(pendingFile!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover)
                  : Image.network(receiptUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover),
            ),
            if (uploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                    backgroundColor: Colors.black54, iconSize: 20),
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onRemove,
              ),
            ),
          ])
        else
          Container(
            height: 100,
            decoration: BoxDecoration(
              border:
                  Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PickBtn(
                    icon: Icons.camera_alt_outlined,
                    label: l10n.camera,
                    onTap: onPickCamera),
                const SizedBox(width: 48),
                _PickBtn(
                    icon: Icons.photo_library_outlined,
                    label: l10n.gallery,
                    onTap: onPickGallery),
              ],
            ),
          ),
      ],
    );
  }
}

class _PickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
          ),
        ),
      );
}