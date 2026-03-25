import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/transactions_api.dart';
import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../services/local_receipt_parser.dart';
import '../../services/ml_kit_ocr_service.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_expandable_section.dart';
import '../../widgets/ui_core/vee_row.dart';
import '../../widgets/ui_core/vee_image_picker.dart';
import '../../widgets/ui_core/vee_category_grid.dart';
import '../../widgets/ui_core/vee_button_spinner.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_account_picker_sheet.dart';
import 'widgets/transaction_item_draft.dart';
import 'widgets/transaction_type_selector.dart';
import 'widgets/transaction_amount_input.dart';
import 'widgets/transaction_items_section.dart';

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
  final _payeeCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _mlKitService = MlKitOcrService();

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
  bool _scanning = false; // OCR 扫描中状态
  String? _error;

  final List<TransactionItemDraft> _items = [];

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
    _payeeCtrl.dispose();
    _mlKitService.dispose();
    super.dispose();
  }

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

  // ── OCR 相关 ────────────────────────────────────────────────────────────────

  /// 从 OCR 结果中解析 categoryId
  Future<int?> _getCategoryId(String? categoryName) async {
    if (categoryName == null) return null;
    try {
      final categories = await ref.read(currentCategoriesProvider.future);
      if (categories.isEmpty) return null;
      return categories
          .firstWhere(
            (c) => c.name == categoryName,
            orElse: () => categories.firstWhere(
              (c) => c.name == '其他',
              orElse: () => categories.first,
            ),
          )
          .id;
    } catch (_) {
      return null;
    }
  }

  /// 扫描小票并自动填入表单
  Future<void> _scanAndFill(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (xfile == null) return;

    setState(() {
      _scanning = true;
      _error = null;
    });

    try {
      final isLoggedIn =
          ref.read(authProvider).status == AuthStatus.authenticated;

      Map<String, dynamic> parsed;

      if (isLoggedIn) {
        // 云端 OCR
        try {
          final file = File(xfile.path);
          final bytes = await file.readAsBytes();
          final base64Str = base64Encode(bytes);
          final data =
              await ref.read(transactionsApiProvider).ocrTransaction({
                    'image_base64': base64Str,
                    'mime_type': 'image/jpeg',
                  })
                  as Map<String, dynamic>;
          parsed = data;
        } catch (_) {
          // 云端失败，降级到本地
          final rawText = await _mlKitService.recognizeFromFile(xfile.path);
          parsed = LocalReceiptParser.parse(rawText);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('云端识别失败，已切换至本地模式'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // 本地 OCR
        final rawText = await _mlKitService.recognizeFromFile(xfile.path);
        parsed = LocalReceiptParser.parse(rawText);
      }

      // 将解析结果填入表单
      await _applyOcrResult(parsed, File(xfile.path));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// 将 OCR 解析结果应用到表单字段
  Future<void> _applyOcrResult(
    Map<String, dynamic> parsed,
    File imageFile,
  ) async {
    final amount = (parsed['amount'] as num?)?.toDouble() ?? 0;
    final currency = parsed['currency'] as String? ?? 'JPY';
    final merchant = parsed['merchant'] as String?;
    final categoryName = parsed['category'] as String?;
    final description = parsed['description'] as String?;
    final receiptUrl = parsed['receipt_url'] as String? ?? '';
    final rawItems = (parsed['items'] as List? ?? []);

    // 解析分类
    final categoryId = await _getCategoryId(categoryName);

    // 解析明细
    final items = rawItems
        .map<Map<String, dynamic>>((e) {
          if (e is Map<String, dynamic>) return e;
          return <String, dynamic>{};
        })
        .where((e) => e.isNotEmpty)
        .map(
          (e) => TransactionItemDraft(
            name: e['name'] as String? ?? '',
            amount: (e['amount'] as num?)?.toDouble() ?? 0,
            quantity: (e['quantity'] as num?)?.toDouble() ?? 1.0,
            itemType: e['item_type'] as String? ?? 'item',
          ),
        )
        .where((i) => i.name.isNotEmpty && i.amount > 0)
        .toList();

    setState(() {
      if (amount > 0) _amountCtrl.text = amount.toStringAsFixed(0);
      _currencyCode = currency;
      if (merchant != null && merchant.isNotEmpty) {
        _payeeCtrl.text = merchant;
      }
      if (categoryId != null) _categoryId = categoryId;
      if (description != null && description.isNotEmpty) {
        _noteCtrl.text = description;
      }
      if (receiptUrl.isNotEmpty) {
        _receiptUrl = receiptUrl;
      } else {
        _pendingImage = imageFile;
      }
      if (items.isNotEmpty) {
        _items
          ..clear()
          ..addAll(items);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            amount > 0
                ? '识别成功，已自动填入 ¥${amount.toStringAsFixed(0)}'
                : '已识别，请确认并补充信息',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
    if (_pendingImage == null) {
      return _receiptUrl.isEmpty ? null : _receiptUrl;
    }
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
            payee: payeeValue,
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

  // ── Build ───────────────────────────────────────────────────────────────────

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
          // ── 拖拽条 ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: VeeTokens.s12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VeeTokens.borderColor,
              borderRadius: BorderRadius.circular(VeeTokens.s2),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────
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
                // ── OCR 扫描按钮 ─────────────────────────────────────
                _scanning
                    ? const Padding(
                        padding: EdgeInsets.all(VeeTokens.s12),
                        child: SizedBox(
                          width: VeeTokens.iconMd,
                          height: VeeTokens.iconMd,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.document_scanner_outlined,
                          size: VeeTokens.iconLg,
                        ),
                        color: VeeTokens.textSecondaryVal,
                        tooltip: '扫描小票',
                        onPressed: () => _showScanMenu(context),
                      ),
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

                  // ① 类型选择器
                  TransactionTypeSelector(
                    currentType: _type,
                    onTypeChanged: (newType) => setState(() {
                      _type = newType;
                      _categoryId = null;
                      if (newType == 'transfer') _payeeCtrl.clear();
                    }),
                  ),
                  const SizedBox(height: VeeTokens.spacingMd),

                  // ② 金额输入
                  TransactionAmountInput(
                    controller: _amountCtrl,
                    currencyCode: _currencyCode,
                    onCurrencyChanged: (c) => setState(() => _currencyCode = c),
                    autofocus: true,
                    onAmountChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: VeeTokens.spacingMd),

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

                  // ④ 核心行：账户 + payee + 转账目标 + 日期
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
                                hintText: _type == 'income'
                                    ? '收款来源（如公司名）'
                                    : '商家或收款方名称',
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
                          _buildToAccountRow(accounts, l10n),
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
                          emptyHeight: 100,
                          onCamera: () => _pickImage(ImageSource.camera),
                          onGallery: () => _pickImage(ImageSource.gallery),
                          onRemove: () => setState(() {
                            _pendingImage = null;
                            _receiptUrl = '';
                          }),
                        ),
                        const SizedBox(height: VeeTokens.spacingXs),

                        TransactionItemsSection(
                          items: _items,
                          currency: _currencyCode,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: VeeTokens.spacingXs),
                      ],
                    ),
                  ),
                  const SizedBox(height: VeeTokens.spacingMd),

                  // ⑥ 保存按钮
                  SizedBox(
                    height: VeeTokens.buttonHeight,
                    child: FilledButton(
                      onPressed: (_saving || _uploadingImg || !_canSave)
                          ? null
                          : _save,
                      child: (_saving || _uploadingImg)
                          ? const VeeButtonSpinner()
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

  // ── 扫描菜单（选择拍照或相册）─────────────────────────────────────────────

  void _showScanMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VeeTokens.rXl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VeeTokens.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: VeeTokens.spacingLg,
                  bottom: VeeTokens.spacingMd,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('扫描小票识别', style: context.veeText.sectionTitle),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: VeeTokens.selectedTint(
                      Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(VeeTokens.rSm),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: VeeTokens.iconMd,
                  ),
                ),
                title: const Text('拍照识别'),
                subtitle: const Text('使用相机拍摄小票'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanAndFill(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: VeeTokens.selectedTint(
                      Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(VeeTokens.rSm),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: VeeTokens.iconMd,
                  ),
                ),
                title: const Text('从相册选取'),
                subtitle: const Text('选择已有的小票图片'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanAndFill(ImageSource.gallery);
                },
              ),
              const SizedBox(height: VeeTokens.spacingXs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToAccountRow(List<dynamic> accounts, AppLocalizations l10n) {
    final selected = accounts
        .where((a) => (a.id as int) == _toAccountId)
        .firstOrNull;
    return VeeRow.display(
      icon: Icons.swap_horiz_outlined,
      label: l10n.to,
      value: selected != null
          ? '${selected.typeIcon} ${selected.name}'
          : l10n.pleaseSelect,
      isPlaceholder: selected == null,
      onTap: () => _showAccountPicker(accounts),
    );
  }

  Future<void> _showAccountPicker(List<dynamic> accounts) async {
    final filtered = accounts
        .where((a) => (a.id as int) != _accountId)
        .toList();
    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: VeeTokens.sheetBorderRadius,
      ),
      builder: (ctx) => AccountPickerSheet(accounts: filtered),
    );
    if (picked == null) return;
    setState(() => _toAccountId = picked);
  }
}
