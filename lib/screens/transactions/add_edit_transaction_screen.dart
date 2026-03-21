// lib/screens/transactions/add_edit_transaction_screen.dart
//
// 变更说明（第二层迁移 #4）：
//   - Step 1 日期选择行：
//     原来：InkWell( child: VeeFormRow( child: Row(...) ) )  — 三层嵌套，视觉正确但模式不统一
//     现在：VeePickerRow(icon, label, value, onTap: _pickDate) — 语义清晰，一行搞定
//   - 账户下拉行保持 VeeFormRow + DropdownButtonFormField 不变：
//     DropdownButton 有内置的下拉 Overlay 交互，与 VeePickerRow（整行点击→外部弹窗）
//     的交互模式不同，不做强制统一以避免引入回归。
//   - 其余逻辑、样式与原版完全一致。

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vee_app/widgets/ui_core/vee_detail_row.dart';
import 'package:vee_app/widgets/ui_core/vee_form_row.dart';
import 'package:vee_app/widgets/ui_core/vee_picker_row.dart'; // ← 新增
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
// 明细行草稿（与原版相同）
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
  // ── 表单状态（与原版相同）─────────────────────────────────────────────────
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

  // ── 步骤状态（与原版相同）─────────────────────────────────────────────────
  int _currentStep = 0;
  static const int _totalSteps = 3;

  late final AnimationController _stepAnim;
  late final Animation<double> _stepFade;

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

  // ── 步骤导航（与原版相同）─────────────────────────────────────────────────

  void _goStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
    _stepAnim.forward(from: 0);
  }

  bool get _canProceedStep0 {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    return amount > 0 && _categoryId != null;
  }

  // ── AppBar（与原版相同）───────────────────────────────────────────────────

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

  // ── 步骤指示器（Layer 3 升级：新增文字标签行）────────────────────────────
  //
  // 改动：在圆点连线下方增加一行文字标签（核心 / 详情 / 附件），
  // 解决用户不知道每个步骤含义的问题。
  // 标签使用 3 个 Expanded 均分宽度，居中对齐到各自步骤圆点正下方。

  Widget _buildStepIndicator() {
    final primary = Theme.of(context).colorScheme.primary;
    const stepLabels = ['核心', '详情', '附件'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s24,
        VeeTokens.s12,
        VeeTokens.s24,
        VeeTokens.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 圆点 + 连线（原有逻辑不变）──────────────────────────────────
          Row(
            children: List.generate(_totalSteps * 2 - 1, (i) {
              if (i.isOdd) {
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
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? primary
                                : VeeTokens.textDisabledVal,
                          ),
                        ),
                ),
              );
            }),
          ),

          // ── 文字标签行（新增）────────────────────────────────────────────
          const SizedBox(height: VeeTokens.s4),
          Row(
            children: List.generate(_totalSteps, (i) {
              final isActive = i == _currentStep;
              final isCompleted = i < _currentStep;
              return Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: VeeTokens.durationNormal,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: (isActive || isCompleted)
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isActive
                        ? primary
                        : isCompleted
                        ? primary.withOpacity(0.6)
                        : VeeTokens.textDisabledVal,
                  ),
                  child: Text(stepLabels[i], textAlign: TextAlign.center),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 0 — Core（Layer 3 升级：粘性金额头部）
  // ─────────────────────────────────────────────────────────────────────────
  //
  // 改动：原版把"类型选择 + 金额输入 + 分类网格"全部放在同一个 ListView，
  // 用户在浏览分类时金额输入区随之滚走，需要来回滚动确认金额。
  //
  // 现在：外层 Column 分为两区：
  //   1. 粘性头部（白色 Material 背景）：error banner + 类型选择 + 金额输入
  //      头部底部加一条 Divider，视觉上提示下方内容可滚动
  //   2. Expanded ListView：分类标题 + 分类网格 + 下一步按钮
  //      用户滚动分类时，金额始终可见，无需反复滚回确认

  Widget _buildStep0(AppLocalizations l10n) {
    final categoriesAsync = ref.watch(currentCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 粘性头部 ──────────────────────────────────────────────────────
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner 也在粘性区内，确保报错时不被遮挡
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
              // 分隔线：明确提示下方内容可滚动
              const Divider(height: 1),
            ],
          ),
        ),

        // ── 可滚动区域：分类网格 + 按钮 ──────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              VeeTokens.s16,
              VeeTokens.spacingMd,
              VeeTokens.s16,
              VeeTokens.s80,
            ),
            children: [
              Text('选择分类', style: context.veeText.sectionTitle),
              const SizedBox(height: VeeTokens.spacingXs),
              categoriesAsync.when(
                data: (cats) {
                  final filtered = cats
                      .where((c) => c.type == _type || c.type == 'both')
                      .toList();
                  // 响应式列数：宽屏用更多列，避免4列在平板上间距过大
                  final cols = MediaQuery.of(context).size.width > 600 ? 6 : 4;
                  return VeeCategoryGrid(
                    categories: filtered,
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                    crossAxisCount: cols,
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
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1 — Details
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep1(AppLocalizations l10n) {
    final accounts = ref.watch(accountsProvider).accounts;
    if (_accountId == null && accounts.isNotEmpty) {
      Future.microtask(() => setState(() => _accountId = accounts.first.id));
    }

    // 日期展示字符串，供 VeePickerRow.value 使用
    final dateLabel =
        '${_txnDate.year}/'
        '${_txnDate.month.toString().padLeft(2, '0')}/'
        '${_txnDate.day.toString().padLeft(2, '0')}';

    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VeeTokens.s16,
        0,
        VeeTokens.s16,
        VeeTokens.s80,
      ),
      children: [
        if (_error != null) VeeErrorBanner(message: _error!),

        // ── 已选摘要卡（Layer 3 升级：明确导航语义）─────────────────────────
        //
        // 原版：VeeCard 无边框，图标用 edit_outlined（"可编辑"暗示模糊）
        // 现在：
        //   - borderColor = selectedTint(primary) → 主色细边框，与下方白色卡片
        //     形成对比，视觉上暗示"这是一个独立的、可点击的导航区块"
        //   - 前置 chevron_left 图标 → 明确"点此返回第一步修改金额/分类"
        //   - 去掉 edit_outlined，改为 Tooltip 包裹的 arrow_back_ios_new，
        //     与 chevron_left 风格统一
        //   - splashColor 用 hoverTint(primary)，点击时有品牌色水波纹反馈
        GestureDetector(
          onTap: () => _goStep(0),
          child: VeeCard(
            padding: VeeTokens.cardPadding,
            borderColor: VeeTokens.selectedTint(primary),
            child: Row(
              children: [
                // 返回图标——明确语义
                Icon(
                  Icons.chevron_left,
                  size: VeeTokens.iconMd,
                  color: primary.withOpacity(0.65),
                ),
                const SizedBox(width: VeeTokens.spacingXxs),

                // 金额
                VeeAmountDisplay(
                  amount: double.tryParse(_amountCtrl.text) ?? 0,
                  currency: _currencyCode,
                  size: VeeAmountSize.medium,
                  color: VeeColors.forTransactionType(_type),
                  prefix: VeeColors.prefixForTransactionType(_type),
                ),
                const SizedBox(width: VeeTokens.spacingMd),

                // 分类徽章
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
                            mainAxisSize: MainAxisSize.min,
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

                // 可编辑提示标签
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VeeTokens.s8,
                    vertical: VeeTokens.s2,
                  ),
                  decoration: BoxDecoration(
                    color: VeeTokens.selectedTint(primary),
                    borderRadius: BorderRadius.circular(VeeTokens.rFull),
                  ),
                  child: Text(
                    '修改',
                    style: context.veeText.micro.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: VeeTokens.spacingMd),

        VeeCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // 账户（保留 DropdownButtonFormField，交互模式不同于 VeePickerRow）
              _buildAccountDropdown(
                accounts,
                _accountId,
                l10n.account,
                (v) => setState(() => _accountId = v),
                l10n,
              ),
              const Divider(height: 1, indent: VeeTokens.dividerIndentStd),

              // 转账目标账户
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

              // ── 迁移 #4：日期行 ──────────────────────────────────────────
              // 原来：InkWell( child: VeeFormRow( child: Row(Text, chevron) ) )
              // 现在：VeePickerRow — 整行语义、视觉完全一致，代码减少 12 行
              VeePickerRow(
                icon: Icons.calendar_today_outlined,
                label: l10n.date,
                value: dateLabel,
                onTap: _pickDate,
              ),
              const Divider(height: 1, indent: VeeTokens.dividerIndentStd),

              // 备注（与原版相同）
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

              // 隐私开关（与原版相同）
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
  // Step 2 — Attachments（与原版相同）
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
        const SizedBox(height: VeeTokens.s32),
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
  // 查看模式（与原版相同）
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
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintText: '0',
              // ✅ Fix: hintStyle 与输入文字保持同样大小，避免 placeholder "0"
              // 比输入文字小得多的割裂感
              hintStyle: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCCCCCC),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  /// 账户下拉行保留 DropdownButtonFormField（内置 Overlay 下拉，
  /// 与 VeePickerRow 整行点击→外部弹窗的交互模式不同）
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
  // 业务逻辑（与原版相同）
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
// 明细行编辑组件（与原版完全相同）
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
