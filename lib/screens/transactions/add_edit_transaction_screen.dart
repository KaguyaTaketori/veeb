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
import '../../utils/vee_colors.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_row.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_confirm_dialog.dart';
import '../../widgets/ui_core/vee_amount_display.dart';
import '../../widgets/ui_core/vee_category_grid.dart';
import '../../widgets/ui_core/vee_image_picker.dart';
import '../../widgets/ui_core/vee_expandable_section.dart';
import '../../widgets/ui_core/vee_button_spinner.dart';
import 'widgets/transaction_item_draft.dart';
import 'widgets/transaction_type_selector.dart';
import 'widgets/transaction_amount_input.dart';
import 'widgets/transaction_items_section.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction transaction;
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
  final _payeeCtrl = TextEditingController();
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

  // 共享 draft 列表，直接传入 TransactionItemsSection
  final List<TransactionItemDraft> _items = [];

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
    _payeeCtrl.text = t.payee ?? '';
    _items.clear();
    for (final item in t.items) {
      _items.add(
        TransactionItemDraft(
          // ← 使用共享 data class
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
    _payeeCtrl.dispose();
    super.dispose();
  }

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

  // ── 业务操作 ────────────────────────────────────────────────────────────────

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

      final payeeValue = _type == 'transfer'
          ? null
          : _payeeCtrl.text.trim().isEmpty
          ? null
          : _payeeCtrl.text.trim();

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
            payee: payeeValue,
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

  // ── Build ───────────────────────────────────────────────────────────────────

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
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: VeeTokens.s16),
              child: VeeButtonSpinner(
                // Step 1
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }

  // ── 编辑模式 ────────────────────────────────────────────────────────────────

  Widget _buildEditBody(AppLocalizations l10n) {
    final categoriesAsync = ref.watch(currentCategoriesProvider);
    final accounts = ref.watch(accountsProvider).accounts;

    if (_accountId == null && accounts.isNotEmpty) {
      Future.microtask(() => setState(() => _accountId = accounts.first.id));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 固定顶部区域
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
                // ① 类型选择器 ← 共享组件
                child: TransactionTypeSelector(
                  currentType: _type,
                  onTypeChanged: (newType) => setState(() {
                    _type = newType;
                    _categoryId = null;
                    if (newType == 'transfer') _payeeCtrl.clear();
                  }),
                ),
              ),
              const SizedBox(height: VeeTokens.spacingMd),

              // ② 金额输入 ← 共享组件（autofocus: false，默认）
              TransactionAmountInput(
                controller: _amountCtrl,
                currencyCode: _currencyCode,
                onCurrencyChanged: (c) => setState(() => _currencyCode = c),
                onAmountChanged: () => setState(() {}),
              ),
              const SizedBox(height: VeeTokens.spacingMd),
              const Divider(height: 1),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              VeeTokens.s16,
              VeeTokens.spacingMd,
              VeeTokens.s16,
              VeeTokens.s80,
            ),
            children: [
              // ③ 分类网格
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

              // ④ 核心行
              VeeCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    VeeRow.form(
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
                                value: a.id,
                                child: Text('${a.typeIcon} ${a.name}'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _accountId = v),
                      ),
                    ),

                    if (_type != 'transfer') ...[
                      const Divider(
                        height: 1,
                        indent: VeeTokens.dividerIndentStd,
                      ),
                      VeeRow.form(
                        icon: Icons.storefront_outlined,
                        label: l10n.payee,
                        child: TextFormField(
                          controller: _payeeCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: _type == 'income' ? '收款来源' : '商家或收款方名称',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],

                    if (_type == 'transfer') ...[
                      const Divider(
                        height: 1,
                        indent: VeeTokens.dividerIndentStd,
                      ),
                      VeeRow.form(
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
                              .where((a) => a.id != _accountId)
                              .map(
                                (a) => DropdownMenuItem<int>(
                                  value: a.id,
                                  child: Text('${a.typeIcon} ${a.name}'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _toAccountId = v),
                        ),
                      ),
                    ],

                    const Divider(
                      height: 1,
                      indent: VeeTokens.dividerIndentStd,
                    ),
                    VeeRow.display(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.date,
                      value: _dateLabel,
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VeeTokens.spacingXxs),

              // ⑤ 可选区
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
                          VeeRow.form(
                            icon: Icons.notes_outlined,
                            label: l10n.note,
                            child: TextFormField(
                              controller: _noteCtrl,
                              maxLines: null,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
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

                    // ⑥ 明细区 ← 共享组件
                    TransactionItemsSection(
                      items: _items,
                      currency: _currencyCode,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: VeeTokens.spacingXs),
                  ],
                ),
              ),
              const SizedBox(height: VeeTokens.s32),

              SizedBox(
                height: VeeTokens.buttonHeight,
                child: FilledButton(
                  onPressed: (_saving || _uploadingImg) ? null : _save,
                  child: (_saving || _uploadingImg)
                      ? const VeeButtonSpinner() // Step 1
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 查看模式（与原版完全相同，无需改动）─────────────────────────────────────

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

            // 详情卡（使用 VeeRow.display）
            VeeCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (t.displayPayee != null) ...[
                    VeeRow.display(
                      icon: Icons.storefront_outlined,
                      label: l10n.payee,
                      value: t.displayPayee!,
                    ),
                    const Divider(
                      height: 1,
                      indent: VeeTokens.dividerIndentStd,
                    ),
                  ],
                  VeeRow.display(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.date,
                    value: _dateLabel,
                  ),
                  if (t.note?.isNotEmpty == true) ...[
                    const Divider(
                      height: 1,
                      indent: VeeTokens.dividerIndentStd,
                    ),
                    VeeRow.display(
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
                    VeeRow.display(
                      icon: Icons.lock_outline,
                      label: l10n.private,
                      value: l10n.yes,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: VeeTokens.spacingLg),

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
}
