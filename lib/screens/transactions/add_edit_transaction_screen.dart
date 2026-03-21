// lib/screens/transactions/add_edit_transaction_screen.dart
//
// 重构说明（v2）：
//   原版将 9 个字段全部平铺在一个 ScrollView 中，认知负担过高。
//   现改为 3 步渐进式表单：
//
//   Step 1 — Core（必填）：金额 + 收支类型 + 分类
//   Step 2 — Details（可选）：账户 / 转账目标 / 日期 / 备注 / 隐私
//   Step 3 — Attachments（可选）：凭证图片 + 商品明细

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vee_app/widgets/ui_core/vee_detail_row.dart';
import 'package:vee_app/widgets/ui_core/vee_form_row.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// 明细行草稿
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
  final Transaction? transaction;
  final DateTime selectedMonth;
  final bool isReadOnly;

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
    extends ConsumerState<AddEditTransactionScreen>
    with SingleTickerProviderStateMixin {
  // ── 表单状态 ──────────────────────────────────────────────────────────────
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

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

  final List<_ItemDraft> _items = [];

  // ── 步骤状态 ──────────────────────────────────────────────────────────────
  int _currentStep = 0; // 0=Core, 1=Details, 2=Attachments
  static const int _totalSteps = 3;

  late final AnimationController _stepAnim;
  late final Animation<double> _stepFade;

  // ── 编辑模式 ──────────────────────────────────────────────────────────────
  late bool _isEditing;
  bool get _isEdit => widget.transaction != null;
  final _picker = ImagePicker();

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isEditing = !widget.isReadOnly;

    _stepAnim = AnimationController(
      vsync: this,
      duration: VeeTokens.durationNormal,
    )..forward();
    _stepFade = CurvedAnimation(parent: _stepAnim, curve: Curves.easeInOut);

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
    } else {
      _txnDate = DateTime(
        widget.selectedMonth.year,
        widget.selectedMonth.month,
        DateTime.now().day,
      );
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _stepAnim.dispose();
    super.dispose();
  }

  // ── 步骤导航 ──────────────────────────────────────────────────────────────

  void _goStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
    _stepAnim.forward(from: 0);
  }

  bool get _canProceedStep0 {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    return amount > 0 && _categoryId != null;
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

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

    final stepTitles = [l10n.addTransaction, '详情信息', '附件'];
    return AppBar(
      title: Text(_isEdit ? l10n.edit : stepTitles[_currentStep]),
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

  // ── 步骤指示器 ────────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VeeTokens.s24,
        vertical: VeeTokens.s12,
      ),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // 连接线
            final stepIdx = i ~/ 2;
            final isCompleted = stepIdx < _currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: VeeTokens.durationNormal,
                height: 2,
                color: isCompleted ? primary : VeeTokens.borderColor,
              ),
            );
          }
          // 步骤点
          final stepIdx = i ~/ 2;
          final isActive = stepIdx == _currentStep;
          final isCompleted = stepIdx < _currentStep;
          return AnimatedContainer(
            duration: VeeTokens.durationNormal,
            width: isActive ? 28 : 22,
            height: isActive ? 28 : 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? primary
                  : isActive
                  ? VeeTokens.selectedTint(primary)
                  : VeeTokens.surfaceSunken,
              border: Border.all(
                color: (isActive || isCompleted)
                    ? primary
                    : VeeTokens.borderColor,
                width: isActive ? 2.0 : 1.0,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check, size: 12, color: Colors.white)
                  : Text(
                      '${stepIdx + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? primary : VeeTokens.textDisabledVal,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 0 — Core（金额 + 类型 + 分类）
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep0(AppLocalizations l10n) {
    final categoriesAsync = ref.watch(currentCategoriesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        0,
        VeeTokens.s16,
        VeeTokens.s80,
      ),
      children: [
        if (_error != null) VeeErrorBanner(message: _error!),

        // ── 收支类型选择器 ──────────────────────────────────────────────
        _buildTypeSelector(l10n),
        const SizedBox(height: VeeTokens.spacingLg),

        // ── 金额输入（大号居中）──────────────────────────────────────────
        _buildAmountHeader(),
        const SizedBox(height: VeeTokens.spacingLg),

        // ── 分类网格 ─────────────────────────────────────────────────────
        Text('选择分类', style: context.veeText.sectionTitle),
        const SizedBox(height: VeeTokens.spacingXs),
        categoriesAsync.when(
          data: (cats) {
            final filtered = cats
                .where((c) => c.type == _type || c.type == 'both')
                .toList();
            return VeeCategoryGrid(
              categories: filtered,
              selectedId: _categoryId,
              onSelected: (id) => setState(() => _categoryId = id),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(VeeTokens.s24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => VeeErrorBanner(message: e.toString()),
        ),

        const SizedBox(height: VeeTokens.s32),

        // ── 下一步按钮 ──────────────────────────────────────────────────
        SizedBox(
          height: VeeTokens.buttonHeight,
          child: FilledButton(
            onPressed: _canProceedStep0 ? () => _goStep(1) : null,
            child: const Text('下一步：填写详情'),
          ),
        ),
        if (!_canProceedStep0)
          Padding(
            padding: const EdgeInsets.only(top: VeeTokens.s8),
            child: Text(
              '请填写金额并选择分类',
              textAlign: TextAlign.center,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1 — Details（账户 / 日期 / 备注 / 隐私）
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep1(AppLocalizations l10n) {
    final accounts = ref.watch(accountsProvider).accounts;
    if (_accountId == null && accounts.isNotEmpty) {
      Future.microtask(() => setState(() => _accountId = accounts.first.id));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        0,
        VeeTokens.s16,
        VeeTokens.s80,
      ),
      children: [
        if (_error != null) VeeErrorBanner(message: _error!),

        // ── 已选摘要（不可交互，点击可回到 Step 0）────────────────────────
        GestureDetector(
          onTap: () => _goStep(0),
          child: VeeCard(
            padding: VeeTokens.cardPadding,
            child: Row(
              children: [
                VeeAmountDisplay(
                  amount: double.tryParse(_amountCtrl.text) ?? 0,
                  currency: _currencyCode,
                  size: VeeAmountSize.medium,
                  color: VeeColors.forTransactionType(_type),
                  prefix: VeeColors.prefixForTransactionType(_type),
                ),
                const SizedBox(width: VeeTokens.spacingMd),
                // 分类小徽章
                if (_categoryId != null)
                  ref
                      .watch(currentCategoriesProvider)
                      .maybeWhen(
                        data: (cats) {
                          final cat = cats
                              .where((c) => c.id == _categoryId)
                              .firstOrNull;
                          if (cat == null) return const SizedBox.shrink();
                          return Row(
                            children: [
                              Text(
                                cat.icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: VeeTokens.s4),
                              Text(cat.name, style: context.veeText.cardTitle),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                const Spacer(),
                Icon(
                  Icons.edit_outlined,
                  size: VeeTokens.iconSm,
                  color: VeeTokens.textPlaceholderVal,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: VeeTokens.spacingMd),

        // ── 详细信息卡 ──────────────────────────────────────────────────
        VeeCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // 账户
              _buildAccountDropdown(
                accounts,
                _accountId,
                l10n.account,
                (v) => setState(() => _accountId = v),
                l10n,
              ),
              const Divider(height: 1, indent: VeeTokens.dividerIndentStd),

              // 转账目标账户（仅 transfer 显示）
              if (_type == 'transfer') ...[
                _buildAccountDropdown(
                  accounts,
                  _toAccountId,
                  l10n.to,
                  (v) => setState(() => _toAccountId = v),
                  l10n,
                ),
                const Divider(height: 1, indent: VeeTokens.dividerIndentStd),
              ],

              // 日期
              InkWell(
                onTap: _pickDate,
                splashColor: VeeTokens.selectedTint(
                  Theme.of(context).colorScheme.primary,
                ),
                child: VeeFormRow(
                  icon: Icons.calendar_today_outlined,
                  label: l10n.date,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_txnDate.year}/'
                          '${_txnDate.month.toString().padLeft(2, '0')}/'
                          '${_txnDate.day.toString().padLeft(2, '0')}',
                          style: context.veeText.bodyDefault,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: VeeTokens.textPlaceholderVal,
                        size: VeeTokens.iconMd,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, indent: VeeTokens.dividerIndentStd),

              // 备注
              VeeFormRow(
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
              const Divider(height: 1, indent: VeeTokens.dividerIndentStd),

              // 隐私开关
              SwitchListTile(
                secondary: Icon(
                  Icons.lock_outline,
                  color: VeeTokens.textSecondaryVal,
                  size: VeeTokens.iconMd,
                ),
                title: Text(l10n.private),
                subtitle: Text(
                  l10n.shareTransactions,
                  style: context.veeText.micro.copyWith(
                    color: VeeTokens.textSecondaryVal,
                  ),
                ),
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: VeeTokens.s32),

        // ── 操作按钮行 ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goStep(0),
                child: const Text('上一步'),
              ),
            ),
            const SizedBox(width: VeeTokens.spacingXs),
            Expanded(
              flex: 2,
              child: FilledButton.tonal(
                onPressed: _saving ? null : _save,
                child: const Text('保存（跳过附件）'),
              ),
            ),
            const SizedBox(width: VeeTokens.spacingXs),
            Expanded(
              child: FilledButton(
                onPressed: () => _goStep(2),
                child: const Text('附件'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2 — Attachments（凭证图片 + 商品明细）
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep2(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        0,
        VeeTokens.s16,
        VeeTokens.s80,
      ),
      children: [
        if (_error != null) VeeErrorBanner(message: _error!),

        // ── 凭证图片 ────────────────────────────────────────────────────
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

        // ── 商品明细 ────────────────────────────────────────────────────
        _buildItemsSection(l10n),
        const SizedBox(height: VeeTokens.s32),

        // ── 操作按钮行 ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goStep(1),
                child: const Text('上一步'),
              ),
            ),
            const SizedBox(width: VeeTokens.spacingXs),
            Expanded(
              flex: 2,
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
                    : const Text('完成保存'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 查看模式（isReadOnly）
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildViewBody(AppLocalizations l10n) {
    final t = widget.transaction!;
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
            // ── 金额头部 ────────────────────────────────────────────────
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

            VeeCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  VeeDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.date,
                    value:
                        '${t.date.year}/${t.date.month.toString().padLeft(2, '0')}/${t.date.day.toString().padLeft(2, '0')}',
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
                            '${isDisc ? '-' : ''}${t.currencyCode} ${formatAmount(item.amount.abs(), t.currencyCode)}',
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
                onPressed: () => _confirmDelete(context),
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

  // ─────────────────────────────────────────────────────────────────────────
  // 共享子 Widget
  // ─────────────────────────────────────────────────────────────────────────

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
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintText: '0',
            ),
            onChanged: (_) => setState(() {}), // 触发 _canProceedStep0 重算
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDropdown(
    List<dynamic> accounts,
    int? value,
    String label,
    ValueChanged<int?> onChanged,
    AppLocalizations l10n,
  ) {
    return VeeFormRow(
      icon: Icons.account_balance_wallet_outlined,
      label: label,
      child: DropdownButtonFormField<int>(
        value: value,
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
        onChanged: onChanged,
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
                label: const Text('添加商品'),
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
                label: const Text('添加折扣'),
              ),
            ),
          ],
        ),

        if (_items.isNotEmpty) ...[
          const SizedBox(height: VeeTokens.spacingXs),
          _ItemsSumBar(items: _items, currency: _currencyCode),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 业务逻辑
  // ─────────────────────────────────────────────────────────────────────────

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
      setState(
        () => _error = AppLocalizations.of(
          context,
        )!.operationFailed(e.toString()),
      );
      return null;
    } finally {
      setState(() => _uploadingImg = false);
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() {
        _error = l10n.required;
        _currentStep = 0;
      });
      return;
    }
    if (_categoryId == null) {
      setState(() {
        _error = l10n.required;
        _currentStep = 0;
      });
      return;
    }
    if (_type == 'transfer' && _toAccountId == null) {
      setState(() {
        _error = l10n.required;
        _currentStep = 1;
      });
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
      final txnDate = _txnDate.millisecondsSinceEpoch / 1000.0;
      final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
      final notifier = ref.read(transactionsProvider.notifier);

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

  Future<void> _confirmDelete(BuildContext ctx) async {
    final l10n = AppLocalizations.of(ctx)!;
    final ok = await VeeConfirmDialog.showDelete(
      context: ctx,
      content: l10n.deleteThisRecord,
    );
    if (ok == true && ctx.mounted) {
      await ref
          .read(transactionsProvider.notifier)
          .deleteTransaction(widget.transaction!.id);
      if (ctx.mounted) Navigator.pop(ctx, true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isEditing) {
      return Scaffold(appBar: _buildAppBar(l10n), body: _buildViewBody(l10n));
    }

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: VeeTokens.durationNormal,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: switch (_currentStep) {
                  0 => _buildStep0(l10n),
                  1 => _buildStep1(l10n),
                  2 => _buildStep2(l10n),
                  _ => _buildStep0(l10n),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 明细行编辑组件（保持不变）
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

class _ItemsSumBar extends StatelessWidget {
  final List<_ItemDraft> items;
  final String currency;
  const _ItemsSumBar({required this.items, required this.currency});

  @override
  Widget build(BuildContext context) {
    double subtotal = 0, discount = 0;
    for (final item in items) {
      if (item.itemType == 'discount') {
        discount += item.amount;
      } else {
        subtotal += item.amount * item.quantity;
      }
    }
    final total = subtotal - discount;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VeeTokens.s12,
        vertical: VeeTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: VeeTokens.selectedTint(Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(VeeTokens.rSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (discount > 0) ...[
            Text(
              '小计 ${formatAmount(subtotal, currency)}',
              style: context.veeText.micro.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
            const SizedBox(width: VeeTokens.spacingXs),
            Text(
              '折扣 -${formatAmount(discount, currency)}',
              style: context.veeText.micro.copyWith(color: VeeTokens.error),
            ),
            const SizedBox(width: VeeTokens.spacingXs),
          ],
          Text(
            '合计 ',
            style: context.veeText.caption.copyWith(
              color: VeeTokens.textSecondaryVal,
            ),
          ),
          VeeAmountDisplay(
            amount: total,
            currency: currency,
            size: VeeAmountSize.small,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
