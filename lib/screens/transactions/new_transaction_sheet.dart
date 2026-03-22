// lib/screens/transactions/new_transaction_sheet.dart
//
// 新建流水底部弹窗（单屏记账）
//
// 变更说明（Step 7）：
//   - 核心区新增 payee 输入行（位于账户行与日期行之间）
//   - transfer 类型时 payee 行自动隐藏（内部转账无外部对手方）
//   - _save() 透传 payee 到 createTransaction

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_expandable_section.dart';
import '../../widgets/ui_core/vee_form_row.dart';
import '../../widgets/ui_core/vee_image_picker.dart';
import '../../widgets/ui_core/vee_category_grid.dart';
import '../../widgets/ui_core/vee_picker_row.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_account_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 公共入口函数
// ─────────────────────────────────────────────────────────────────────────────

Future<bool?> showNewTransactionSheet(
  BuildContext context, {
  DateTime? selectedMonth,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) =>
        _NewTransactionSheet(selectedMonth: selectedMonth ?? DateTime.now()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 内部明细行草稿
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
// Sheet Widget
// ─────────────────────────────────────────────────────────────────────────────

class _NewTransactionSheet extends ConsumerStatefulWidget {
  final DateTime selectedMonth;
  const _NewTransactionSheet({required this.selectedMonth});

  @override
  ConsumerState<_NewTransactionSheet> createState() =>
      _NewTransactionSheetState();
}

class _NewTransactionSheetState extends ConsumerState<_NewTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _payeeCtrl = TextEditingController(); // ✅ 新增
  final _picker = ImagePicker();

  String _type = 'expense';
  String _currencyCode = 'JPY';
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;
  late DateTime _txnDate;
  bool _isPrivate = false;
  String _receiptUrl = '';
  File? _pendingImage;
  bool _uploadingImg = false;
  bool _saving = false;
  String? _error;
  final List<_ItemDraft> _items = [];

  @override
  void initState() {
    super.initState();
    _txnDate = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month,
      DateTime.now().day.clamp(
        1,
        DateUtils.getDaysInMonth(
          widget.selectedMonth.year,
          widget.selectedMonth.month,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _payeeCtrl.dispose(); // ✅ 新增
    super.dispose();
  }

  // ── 辅助 getters ─────────────────────────────────────────────────────────

  bool get _canSave {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    return amount > 0 && _categoryId != null && _accountId != null;
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

  // ── 业务操作 ──────────────────────────────────────────────────────────────

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
    if (_pendingImage == null) return _receiptUrl.isEmpty ? null : _receiptUrl;
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
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = '请输入金额');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = '请选择分类');
      return;
    }
    if (_accountId == null) {
      setState(() => _error = '请选择账户');
      return;
    }
    if (_type == 'transfer' && _toAccountId == null) {
      setState(() => _error = '请选择转账目标账户');
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
      final validItems = _items
          .where((i) => i.name.trim().isNotEmpty && i.amount > 0)
          .map((i) => i.toJson())
          .toList();

      // transfer 无外部对手方，payee 传 null
      final payeeValue = _type == 'transfer'
          ? null
          : _payeeCtrl.text.trim().isEmpty
          ? null
          : _payeeCtrl.text.trim();

      await ref
          .read(transactionsProvider.notifier)
          .createTransaction(
            type: _type,
            amount: amount,
            currencyCode: _currencyCode,
            accountId: _accountId!,
            toAccountId: _toAccountId,
            categoryId: _categoryId!,
            groupId: groupId,
            isPrivate: _isPrivate,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            payee: payeeValue, // ✅ 新增
            transactionDate: _txnDate.millisecondsSinceEpoch / 1000.0,
            receiptUrl: receiptUrl ?? '',
            items: validItems,
          );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(accountsProvider).accounts;
    final categoriesAsync = ref.watch(currentCategoriesProvider);

    if (_accountId == null && accounts.isNotEmpty) {
      Future.microtask(() => setState(() => _accountId = accounts.first.id));
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: VeeTokens.sheetBorderRadius,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 拖拽指示条 ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: VeeTokens.s12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VeeTokens.borderColor,
              borderRadius: BorderRadius.circular(VeeTokens.s2),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VeeTokens.s20,
              VeeTokens.s12,
              VeeTokens.s8,
              0,
            ),
            child: Row(
              children: [
                Text('记一笔', style: context.veeText.sectionTitle),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: VeeTokens.iconMd),
                  color: VeeTokens.textSecondaryVal,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),

          // ── 可滚动内容区 ─────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: VeeTokens.s16,
                right: VeeTokens.s16,
                top: VeeTokens.spacingXs,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + VeeTokens.s32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    VeeErrorBanner(message: _error!),
                    const SizedBox(height: VeeTokens.spacingXs),
                  ],

                  _buildTypeSelector(l10n),
                  const SizedBox(height: VeeTokens.spacingMd),

                  _buildAmountInput(),
                  const SizedBox(height: VeeTokens.spacingMd),

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
                      final cols = MediaQuery.of(context).size.width > 400
                          ? 5
                          : 4;
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

                  // ── 核心区：账户 + payee + 日期 ──────────────────────
                  VeeCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildAccountRow(accounts, l10n),

                        // ✅ payee 行：transfer 时隐藏
                        if (_type != 'transfer') ...[
                          const Divider(
                            height: 1,
                            indent: VeeTokens.dividerIndentStd,
                          ),
                          _buildPayeeRow(l10n),
                        ],

                        if (_type == 'transfer') ...[
                          const Divider(
                            height: 1,
                            indent: VeeTokens.dividerIndentStd,
                          ),
                          _buildToAccountRow(accounts, l10n),
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

                  // ── 可选区（折叠）────────────────────────────────────
                  const Divider(height: 1),
                  VeeExpandableSection(
                    label: '更多选项',
                    icon: Icons.tune_outlined,
                    badgeCount: _optionalFilledCount,
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
                                onChanged: (v) =>
                                    setState(() => _isPrivate = v),
                                dense: true,
                                contentPadding: VeeTokens.tilePadding,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: VeeTokens.spacingXs),

                        Text(
                          '凭证图片',
                          style: context.veeText.caption.copyWith(
                            color: VeeTokens.textSecondaryVal,
                          ),
                        ),
                        const SizedBox(height: VeeTokens.spacingXxs),
                        VeeImagePicker(
                          pendingFile: _pendingImage,
                          remoteUrl: _receiptUrl,
                          uploading: _uploadingImg,
                          emptyHeight: 80,
                          onCamera: () => _pickImage(ImageSource.camera),
                          onGallery: () => _pickImage(ImageSource.gallery),
                          onRemove: () => setState(() {
                            _pendingImage = null;
                            _receiptUrl = '';
                          }),
                        ),
                        const SizedBox(height: VeeTokens.spacingXs),

                        _buildItemsSection(),
                        const SizedBox(height: VeeTokens.spacingXs),
                      ],
                    ),
                  ),
                  const SizedBox(height: VeeTokens.spacingMd),

                  // 保存按钮
                  SizedBox(
                    height: VeeTokens.buttonHeight,
                    child: FilledButton(
                      onPressed: (_saving || _uploadingImg || !_canSave)
                          ? null
                          : _save,
                      child: (_saving || _uploadingImg)
                          ? const SizedBox(
                              width: VeeTokens.iconMd,
                              height: VeeTokens.iconMd,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 子 Widget ──────────────────────────────────────────────────────────────

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
              // transfer 时清空 payee（无外部对手方）
              if (t.$1 == 'transfer') _payeeCtrl.clear();
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

  Widget _buildAmountInput() {
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
            autofocus: true,
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

  // ✅ 新增：payee 输入行
  Widget _buildPayeeRow(AppLocalizations l10n) {
    return VeeFormRow(
      icon: Icons.storefront_outlined,
      label: l10n.payee,
      child: TextFormField(
        controller: _payeeCtrl,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: _type == 'income' ? '收款来源（如公司名）' : '商家或收款方名称',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildAccountRow(List<dynamic> accounts, AppLocalizations l10n) {
    return Padding(
      padding: VeeTokens.tilePadding,
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: VeeTokens.iconMd,
            color: VeeTokens.textSecondaryVal,
          ),
          const SizedBox(width: VeeTokens.s12),
          SizedBox(
            width: 64,
            child: Text(
              l10n.account,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
          ),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  Widget _buildToAccountRow(List<dynamic> accounts, AppLocalizations l10n) {
    final selected = accounts
        .where((a) => (a.id as int) == _toAccountId)
        .firstOrNull;
    return VeePickerRow(
      icon: Icons.swap_horiz_outlined,
      label: l10n.to,
      value: selected != null
          ? '${selected.typeIcon} ${selected.name}'
          : l10n.pleaseSelect,
      isPlaceholder: selected == null,
      onTap: () => _showAccountPicker(accounts, isTo: true),
    );
  }

  Future<void> _showAccountPicker(
    List<dynamic> accounts, {
    required bool isTo,
  }) async {
    final filtered = isTo
        ? accounts.where((a) => (a.id as int) != _accountId).toList()
        : accounts;

    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: VeeTokens.sheetBorderRadius,
      ),
      builder: (ctx) => AccountPickerSheet(accounts: filtered),
    );
    if (picked == null) return;
    setState(() {
      if (isTo) {
        _toAccountId = picked;
      } else {
        _accountId = picked;
      }
    });
  }

  Widget _buildItemsSection() {
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
            Text(
              '商品明细',
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
            const Spacer(),
            if (_items.isNotEmpty)
              Text(
                '${_items.length} 项',
                style: context.veeText.micro.copyWith(
                  color: VeeTokens.textSecondaryVal,
                ),
              ),
          ],
        ),

        if (_items.isNotEmpty) ...[
          const SizedBox(height: VeeTokens.spacingXxs),
          VeeCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isDisc = item.itemType == 'discount';
                return Column(
                  children: [
                    if (idx > 0)
                      const Divider(height: 1, indent: VeeTokens.s16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VeeTokens.s12,
                        vertical: VeeTokens.s8,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              item.itemType = isDisc ? 'item' : 'discount';
                            }),
                            child: Container(
                              width: VeeTokens.s28,
                              height: VeeTokens.s28,
                              decoration: BoxDecoration(
                                color: VeeTokens.selectedTint(
                                  isDisc
                                      ? VeeTokens.error
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isDisc ? '➖' : '•',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: VeeTokens.spacingXs),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: isDisc ? '折扣/优惠' : '商品名称',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (v) => item.name = v,
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            child: TextField(
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                hintText: '金额',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDisc ? VeeTokens.error : null,
                              ),
                              onChanged: (v) =>
                                  item.amount = double.tryParse(v) ?? 0,
                            ),
                          ),
                          const SizedBox(width: VeeTokens.spacingXxs),
                          GestureDetector(
                            onTap: () => setState(() => _items.removeAt(idx)),
                            child: Icon(
                              Icons.close,
                              size: VeeTokens.iconSm,
                              color: VeeTokens.textPlaceholderVal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: VeeTokens.spacingXxs),
        Row(
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: VeeTokens.spacingXs,
                  vertical: VeeTokens.s4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _items.add(_ItemDraft())),
              icon: const Icon(Icons.add, size: VeeTokens.iconXs),
              label: const Text('添加商品', style: TextStyle(fontSize: 12)),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: VeeTokens.spacingXs,
                  vertical: VeeTokens.s4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: VeeTokens.error,
              ),
              onPressed: () =>
                  setState(() => _items.add(_ItemDraft(itemType: 'discount'))),
              icon: const Icon(
                Icons.remove_circle_outline,
                size: VeeTokens.iconXs,
              ),
              label: const Text('添加折扣', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}
