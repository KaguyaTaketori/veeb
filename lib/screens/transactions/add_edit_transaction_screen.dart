// lib/screens/transactions/add_edit_transaction_screen.dart
//
// 流水详情 / 编辑屏（全屏）
//
// 变更说明（Wizard → 单屏重构）：
//   - 移除 3-step wizard、步骤指示器、步骤导航按钮
//   - 新建流水由 new_transaction_sheet.dart（底部弹窗）承接
//   - 本屏只处理两个场景：
//       isReadOnly = true  → 查看模式（只读，含删除入口）
//       isReadOnly = false → 编辑模式（单屏滚动表单）
//   - 编辑模式布局：类型 + 金额（固定头部）+ 分类网格 + 详情卡 + 可选区（折叠）
//   - VeeExpandableSection 替代原"保存跳过附件"按钮

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vee_app/widgets/ui_core/vee_detail_row.dart';
import 'package:vee_app/widgets/ui_core/vee_form_row.dart';
import 'package:vee_app/widgets/ui_core/vee_picker_row.dart';
import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../utils/currency.dart';
import '../../utils/vee_colors.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_confirm_dialog.dart';
import '../../widgets/ui_core/vee_amount_display.dart';
import '../../widgets/ui_core/vee_category_grid.dart';
import '../../widgets/ui_core/vee_image_picker.dart';
import '../../widgets/ui_core/vee_expandable_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 明细行草稿（内部 DTO）
// ─────────────────────────────────────────────────────────────────────────────

class _ItemDraft {
  String name;
  double amount;
  double quantity;
  String itemType;

  _ItemDraft({
    this.name = '',
    this.amount = 0,
    this.quantity = 1,
    this.itemType = 'item',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'name_raw': name,
    'quantity': quantity,
    'amount': amount,
    'item_type': itemType,
    'sort_order': 0,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction transaction; // 必须传入，本屏只处理已有流水
  final bool isReadOnly;

  const AddEditTransactionScreen({
    super.key,
    required this.transaction,
    this.isReadOnly = true,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();

  late String _type;
  late String _currencyCode;
  late int? _accountId;
  late int? _toAccountId;
  late int? _categoryId;
  late DateTime _txnDate;
  late bool _isPrivate;
  late String _receiptUrl;
  File? _pendingImage;
  bool _uploadingImg = false;
  bool _saving = false;
  String? _error;
  final List<_ItemDraft> _items = [];

  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = !widget.isReadOnly;
    _syncFromTransaction(widget.transaction);
  }

  void _syncFromTransaction(Transaction t) {
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
    _items.clear();
    for (final item in t.items) {
      _items.add(
        _ItemDraft(
          name: item.name,
          amount: item.amount,
          quantity: item.quantity,
          itemType: item.itemType,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── 辅助 getters ─────────────────────────────────────────────────────────

  String get _dateLabel =>
      '${_txnDate.year}/'
      '${_txnDate.month.toString().padLeft(2, '0')}/'
      '${_txnDate.day.toString().padLeft(2, '0')}';

  int get _optionalFilledCount => [
    _noteCtrl.text.isNotEmpty,
    _isPrivate,
    _pendingImage != null || _receiptUrl.isNotEmpty,
    _items.isNotEmpty,
  ].where((b) => b).length;

  // ── 操作 ─────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _txnDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _txnDate = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
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
      return await ref
          .read(transactionsProvider.notifier)
          .uploadReceipt(fileBytes: bytes, filename: filename, mimeType: mime);
    } catch (e) {
      setState(() => _error = e.toString());
      return null;
    } finally {
      if (mounted) setState(() => _uploadingImg = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (amount <= 0) {
      setState(() => _error = l10n.required);
      return;
    }
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

      await ref
          .read(transactionsProvider.notifier)
          .updateTransaction(
            id: widget.transaction.id,
            type: _type,
            amount: amount,
            currencyCode: _currencyCode,
            accountId: _accountId,
            toAccountId: _toAccountId,
            categoryId: _categoryId,
            isPrivate: _isPrivate,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            transactionDate: _txnDate.millisecondsSinceEpoch / 1000.0,
            receiptUrl: receiptUrl,
          );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await VeeConfirmDialog.showDelete(
      context: context,
      content: l10n.deleteThisRecord,
    );
    if (ok == true && mounted) {
      await ref
          .read(transactionsProvider.notifier)
          .deleteTransaction(widget.transaction.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: _isEditing ? _buildEditBody(l10n) : _buildViewBody(l10n),
    );
  }

  AppBar _buildAppBar(AppLocalizations l10n) {
    if (!_isEditing) {
      return AppBar(
        title: Text(l10n.detail),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_outlined, size: VeeTokens.iconSm),
            label: Text(l10n.edit),
          ),
        ],
      );
    }

    return AppBar(
      title: Text(l10n.edit),
      centerTitle: true,
      actions: [
        if (_saving || _uploadingImg)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: VeeTokens.s16),
              child: SizedBox(
                width: VeeTokens.iconMd,
                height: VeeTokens.iconMd,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 编辑模式：单屏滚动表单（无 wizard）
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEditBody(AppLocalizations l10n) {
    final categoriesAsync = ref.watch(currentCategoriesProvider);
    final accounts = ref.watch(accountsProvider).accounts;

    if (_accountId == null && accounts.isNotEmpty) {
      Future.microtask(() => setState(() => _accountId = accounts.first.id));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 固定头部：类型选择 + 金额 ─────────────────────────────────
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VeeTokens.s16,
                    VeeTokens.spacingXs,
                    VeeTokens.s16,
                    0,
                  ),
                  child: VeeErrorBanner(message: _error!),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VeeTokens.s16,
                  VeeTokens.spacingXs,
                  VeeTokens.s16,
                  0,
                ),
                child: _buildTypeSelector(l10n),
              ),
              const SizedBox(height: VeeTokens.spacingMd),
              _buildAmountHeader(),
              const SizedBox(height: VeeTokens.spacingMd),
              const Divider(height: 1),
            ],
          ),
        ),

        // ── 可滚动区域 ────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              VeeTokens.s16,
              VeeTokens.spacingMd,
              VeeTokens.s16,
              VeeTokens.s80,
            ),
            children: [
              // 分类
              Text(
                '分类',
                style: context.veeText.caption.copyWith(
                  color: VeeTokens.textSecondaryVal,
                ),
              ),
              const SizedBox(height: VeeTokens.spacingXxs),
              categoriesAsync.when(
                data: (cats) {
                  final filtered = cats
                      .where((c) => c.type == _type || c.type == 'both')
                      .toList();
                  final cols = MediaQuery.of(context).size.width > 600 ? 6 : 4;
                  return VeeCategoryGrid(
                    categories: filtered,
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                    crossAxisCount: cols,
                  );
                },
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => VeeErrorBanner(message: e.toString()),
              ),
              const SizedBox(height: VeeTokens.spacingMd),

              // 账户 + 日期
              VeeCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildAccountDropdown(accounts, l10n),
                    if (_type == 'transfer') ...[
                      const Divider(
                        height: 1,
                        indent: VeeTokens.dividerIndentStd,
                      ),
                      _buildToAccountDropdown(accounts, l10n),
                    ],
                    const Divider(
                      height: 1,
                      indent: VeeTokens.dividerIndentStd,
                    ),
                    VeePickerRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.date,
                      value: _dateLabel,
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VeeTokens.spacingXxs),

              // 可选区：备注 + 隐私 + 附件 + 明细
              const Divider(height: 1),
              VeeExpandableSection(
                label: '备注 / 附件 / 明细',
                icon: Icons.tune_outlined,
                badgeCount: _optionalFilledCount,
                initiallyExpanded: _optionalFilledCount > 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: VeeTokens.spacingXs),
                    VeeCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          VeeFormRow(
                            icon: Icons.notes_outlined,
                            label: l10n.note,
                            child: TextFormField(
                              controller: _noteCtrl,
                              maxLines: null,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '添加备注…',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          const Divider(
                            height: 1,
                            indent: VeeTokens.dividerIndentStd,
                          ),
                          SwitchListTile(
                            secondary: Icon(
                              Icons.lock_outline,
                              color: VeeTokens.textSecondaryVal,
                              size: VeeTokens.iconMd,
                            ),
                            title: Text(
                              l10n.private,
                              style: context.veeText.bodyDefault,
                            ),
                            value: _isPrivate,
                            onChanged: (v) => setState(() => _isPrivate = v),
                            dense: true,
                            contentPadding: VeeTokens.tilePadding,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VeeTokens.spacingXs),
                    Text(l10n.scanReceipt, style: context.veeText.sectionTitle),
                    const SizedBox(height: VeeTokens.spacingXs),
                    VeeImagePicker(
                      pendingFile: _pendingImage,
                      remoteUrl: _receiptUrl,
                      uploading: _uploadingImg,
                      onCamera: () => _pickImage(ImageSource.camera),
                      onGallery: () => _pickImage(ImageSource.gallery),
                      onRemove: () => setState(() {
                        _pendingImage = null;
                        _receiptUrl = '';
                      }),
                    ),
                    const SizedBox(height: VeeTokens.spacingLg),
                    _buildItemsSection(l10n),
                    const SizedBox(height: VeeTokens.spacingXs),
                  ],
                ),
              ),
              const SizedBox(height: VeeTokens.s32),

              // 保存按钮
              SizedBox(
                height: VeeTokens.buttonHeight,
                child: FilledButton(
                  onPressed: (_saving || _uploadingImg) ? null : _save,
                  child: (_saving || _uploadingImg)
                      ? const SizedBox(
                          width: VeeTokens.iconMd,
                          height: VeeTokens.iconMd,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 查看模式（与原版一致）
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildViewBody(AppLocalizations l10n) {
    final t = widget.transaction;
    final color = VeeColors.fromHex(t.categoryColor);
    final typeLabel = t.type == 'income'
        ? l10n.income
        : t.type == 'transfer'
        ? l10n.transfer
        : l10n.expense;
    final typeColor = VeeColors.forTransactionType(t.type);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: VeeTokens.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: VeeTokens.s16,
            vertical: VeeTokens.s24,
          ),
          children: [
            // 金额头部
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VeeTokens.s12,
                    vertical: VeeTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: VeeTokens.selectedTint(typeColor),
                    borderRadius: BorderRadius.circular(VeeTokens.rSm),
                  ),
                  child: Text(
                    typeLabel,
                    style: context.veeText.chipLabel.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: VeeTokens.s12),
                Container(
                  width: VeeTokens.s64,
                  height: VeeTokens.s64,
                  decoration: BoxDecoration(
                    color: VeeTokens.hoverTint(color),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t.categoryIcon ?? '📦',
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                const SizedBox(height: VeeTokens.s12),
                Text(
                  t.categoryName ?? l10n.uncategorized,
                  style: context.veeText.caption.copyWith(
                    color: VeeTokens.textSecondaryVal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: VeeTokens.spacingXxs),
                VeeAmountDisplay(
                  amount: t.amount,
                  currency: t.currencyCode,
                  size: VeeAmountSize.hero,
                  color: typeColor,
                ),
              ],
            ),
            const SizedBox(height: VeeTokens.s32),

            // 详情卡
            VeeCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  VeeDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.date,
                    value: _dateLabel,
                  ),
                  if (t.note?.isNotEmpty == true) ...[
                    const Divider(
                      height: 1,
                      indent: VeeTokens.dividerIndentStd,
                    ),
                    VeeDetailRow(
                      icon: Icons.notes_outlined,
                      label: l10n.note,
                      value: t.note!,
                    ),
                  ],
                  if (t.isPrivate) ...[
                    const Divider(
                      height: 1,
                      indent: VeeTokens.dividerIndentStd,
                    ),
                    VeeDetailRow(
                      icon: Icons.lock_outline,
                      label: l10n.private,
                      value: l10n.yes,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: VeeTokens.spacingLg),

            // 凭证图片
            if (t.hasReceipt) ...[
              Text(l10n.receiptImages, style: context.veeText.sectionTitle),
              const SizedBox(height: VeeTokens.s12),
              ClipRRect(
                borderRadius: BorderRadius.circular(VeeTokens.rLg),
                child: Image.network(
                  t.receiptUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: VeeTokens.spacingLg),
            ],

            // 明细列表
            if (t.items.isNotEmpty) ...[
              Text(
                l10n.itemsCount(t.items.length),
                style: context.veeText.sectionTitle,
              ),
              const SizedBox(height: VeeTokens.s12),
              VeeCard(
                padding: VeeTokens.cardPadding,
                child: Column(
                  children: t.items.map((item) {
                    final isDisc = item.itemType == 'discount';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: VeeTokens.s2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            isDisc ? '➖' : '•',
                            style: const TextStyle(fontSize: VeeTokens.iconXs),
                          ),
                          const SizedBox(width: VeeTokens.spacingXs),
                          Expanded(
                            child: Text(
                              item.name,
                              style: context.veeText.caption,
                            ),
                          ),
                          Text(
                            '${isDisc ? '-' : ''}${t.currencyCode} '
                            '${formatAmount(item.amount.abs(), t.currencyCode)}',
                            style: context.veeText.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isDisc ? VeeTokens.error : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: VeeTokens.spacingLg),
            ],

            // 删除按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: VeeTokens.errorSurface,
                  foregroundColor: VeeTokens.error,
                  padding: const EdgeInsets.symmetric(vertical: VeeTokens.s16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VeeTokens.rLg),
                  ),
                ),
                onPressed: _confirmDelete,
                child: Text(
                  l10n.deleteThisRecord,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: VeeTokens.s48),
          ],
        ),
      ),
    );
  }

  // ── 共用子 Widget ─────────────────────────────────────────────────────────

  Widget _buildTypeSelector(AppLocalizations l10n) {
    final types = [
      ('expense', l10n.expense, VeeTokens.error),
      ('income', l10n.income, VeeTokens.success),
      ('transfer', l10n.transfer, VeeTokens.info),
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
            child: AnimatedContainer(
              duration: VeeTokens.durationFast,
              margin: const EdgeInsets.symmetric(
                horizontal: VeeTokens.spacingXxs,
              ),
              padding: const EdgeInsets.symmetric(vertical: VeeTokens.s10),
              decoration: BoxDecoration(
                color: selected
                    ? VeeTokens.selectedTint(t.$3)
                    : VeeTokens.surfaceSunken,
                borderRadius: BorderRadius.circular(VeeTokens.rMd),
                border: Border.all(
                  color: selected ? t.$3 : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                t.$2,
                style: context.veeText.chipLabel.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? t.$3 : VeeTokens.textSecondaryVal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DropdownButton<String>(
          value: _currencyCode,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down, size: VeeTokens.iconSm),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: [
            'JPY',
            'CNY',
            'USD',
            'EUR',
            'HKD',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _currencyCode = v!),
        ),
        const SizedBox(width: VeeTokens.spacingXs),
        IntrinsicWidth(
          child: TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDropdown(List<dynamic> accounts, AppLocalizations l10n) {
    return VeeFormRow(
      icon: Icons.account_balance_wallet_outlined,
      label: l10n.account,
      child: DropdownButtonFormField<int>(
        value: _accountId,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        icon: Icon(
          Icons.chevron_right,
          color: VeeTokens.textPlaceholderVal,
          size: VeeTokens.iconMd,
        ),
        items: accounts
            .map(
              (a) => DropdownMenuItem<int>(
                value: a.id as int,
                child: Text('${a.typeIcon} ${a.name}'),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _accountId = v),
      ),
    );
  }

  Widget _buildToAccountDropdown(
    List<dynamic> accounts,
    AppLocalizations l10n,
  ) {
    return VeeFormRow(
      icon: Icons.swap_horiz_outlined,
      label: l10n.to,
      child: DropdownButtonFormField<int>(
        value: _toAccountId,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        icon: Icon(
          Icons.chevron_right,
          color: VeeTokens.textPlaceholderVal,
          size: VeeTokens.iconMd,
        ),
        items: accounts
            .where((a) => (a.id as int) != _accountId)
            .map(
              (a) => DropdownMenuItem<int>(
                value: a.id as int,
                child: Text('${a.typeIcon} ${a.name}'),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _toAccountId = v),
      ),
    );
  }

  Widget _buildItemsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: VeeTokens.iconSm,
              color: VeeTokens.textSecondaryVal,
            ),
            const SizedBox(width: VeeTokens.spacingXxs),
            Text('商品明细', style: context.veeText.sectionTitle),
            const Spacer(),
            Text(
              '${_items.length} 项',
              style: context.veeText.micro.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
          ],
        ),
        const SizedBox(height: VeeTokens.spacingXs),

        if (_items.isNotEmpty)
          VeeCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (idx > 0)
                      const Divider(height: 1, indent: VeeTokens.s16),
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

        const SizedBox(height: VeeTokens.spacingXs),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: VeeTokens.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VeeTokens.rMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: VeeTokens.s12),
                ),
                onPressed: () => setState(() => _items.add(_ItemDraft())),
                icon: const Icon(Icons.add, size: VeeTokens.iconSm),
                label: const Text('商品'),
              ),
            ),
            const SizedBox(width: VeeTokens.spacingXs),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: VeeTokens.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VeeTokens.rMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: VeeTokens.s12),
                ),
                onPressed: () => setState(
                  () => _items.add(_ItemDraft(itemType: 'discount')),
                ),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: VeeTokens.iconSm,
                ),
                label: const Text('折扣'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 明细行编辑组件（与原版相同）
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
    _amtCtrl = TextEditingController(
      text: widget.item.amount > 0 ? widget.item.amount.toStringAsFixed(0) : '',
    );
    _qtyCtrl = TextEditingController(
      text: widget.item.quantity == 1.0
          ? '1'
          : widget.item.quantity.toStringAsFixed(1),
    );
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
    final accentColor = isDiscount
        ? VeeTokens.error
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VeeTokens.s12,
        vertical: VeeTokens.s10,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                widget.item.itemType = widget.item.itemType == 'discount'
                    ? 'item'
                    : 'discount';
              });
              widget.onChanged();
            },
            child: Container(
              width: VeeTokens.s32,
              height: VeeTokens.s32,
              decoration: BoxDecoration(
                color: VeeTokens.selectedTint(accentColor),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                isDiscount ? '➖' : '•',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: VeeTokens.spacingXs),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: isDiscount ? '折扣/优惠' : '商品名称',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: context.veeText.caption.copyWith(fontSize: 14),
              onChanged: (v) {
                widget.item.name = v;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: VeeTokens.spacingXxs),
          if (!isDiscount) ...[
            SizedBox(
              width: 36,
              child: TextField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '×1',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: VeeTokens.textPlaceholderVal,
                  ),
                  prefix: Text(
                    '×',
                    style: TextStyle(
                      fontSize: 11,
                      color: VeeTokens.textSecondaryVal,
                    ),
                  ),
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
            const SizedBox(width: VeeTokens.spacingXxs),
          ],
          SizedBox(
            width: 72,
            child: TextField(
              controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDiscount ? VeeTokens.error : null,
              ),
              textAlign: TextAlign.right,
              onChanged: (v) {
                widget.item.amount = double.tryParse(v) ?? 0;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: VeeTokens.spacingXxs),
          GestureDetector(
            onTap: widget.onDelete,
            child: Icon(
              Icons.close,
              size: VeeTokens.iconSm,
              color: VeeTokens.textPlaceholderVal,
            ),
          ),
        ],
      ),
    );
  }
}
