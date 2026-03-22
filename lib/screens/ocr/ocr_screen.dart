// lib/screens/ocr/ocr_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vee_app/widgets/transaction_item_row.dart';
import 'package:vee_app/widgets/ui_core/vee_detail_row.dart';
import '../../constants/categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../api/transactions_api.dart';
import '../../services/ml_kit_ocr_service.dart';
import '../../services/local_receipt_parser.dart';
import '../../utils/currency.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_amount_display.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OCR 解析草稿（内部 DTO）
// ─────────────────────────────────────────────────────────────────────────────

class _OcrDraft {
  final double amount;
  final String currency;
  final String? merchant;
  final String? category;
  final String? date;
  final String? description;
  final List<Map<String, dynamic>> items;
  final String receiptUrl;

  const _OcrDraft({
    required this.amount,
    required this.currency,
    this.merchant,
    this.category,
    this.date,
    this.description,
    this.items = const [],
    this.receiptUrl = '',
  });

  factory _OcrDraft.fromMap(Map<String, dynamic> map) {
    final rawDate =
        (map['bill_date'] ?? map['date'] ?? map['transaction_date']) as String?;
    final rawItems = (map['items'] as List? ?? []);
    final items = rawItems
        .map<Map<String, dynamic>>((e) {
          if (e is Map<String, dynamic>) return e;
          try {
            return (e as dynamic).toJson() as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();

    return _OcrDraft(
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'JPY',
      merchant: map['merchant'] as String?,
      category: map['category'] as String?,
      date: rawDate,
      description: map['description'] as String?,
      items: items,
      receiptUrl: map['receipt_url'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OcrScreen
// ─────────────────────────────────────────────────────────────────────────────

class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  final _picker = ImagePicker();
  final _mlKitService = MlKitOcrService();

  bool _loading = false;
  bool _useLocalOcr = false;
  String? _error;
  _OcrDraft? _result;

  @override
  void dispose() {
    _mlKitService.dispose();
    super.dispose();
  }

  // ── categoryId 解決 ──────────────────────────────────────────────────────

  Future<int> _getCategoryId(String? categoryName) async {
    final groupId = ref.read(currentGroupIdProvider);
    try {
      final categories = await ref.read(categoriesProvider(groupId).future);
      if (categories.isEmpty) return 1;
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
      return 1;
    }
  }

  // ── OCR 入口 ──────────────────────────────────────────────────────────────

  Future<void> _pickAndOcr(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (xfile == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final isLoggedIn =
          ref.read(authProvider).status == AuthStatus.authenticated;

      if (!isLoggedIn || _useLocalOcr) {
        await _runLocalOcr(xfile.path);
      } else {
        try {
          await _runCloudOcr(File(xfile.path));
        } catch (_) {
          await _runLocalOcr(xfile.path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('云端识别失败，已切换至本地模式'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runLocalOcr(String imagePath) async {
    final rawText = await _mlKitService.recognizeFromFile(imagePath);
    final parsed = LocalReceiptParser.parse(rawText);
    setState(() => _result = _OcrDraft.fromMap(parsed));
  }

  Future<void> _runCloudOcr(File file) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final data = await ref
        .read(transactionsApiProvider)
        .ocrTransaction(base64Str, 'image/jpeg');
    setState(() => _result = _OcrDraft.fromMap(data));
  }

  // ── 确认入库 ──────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    if (_result == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final groupId = ref.read(currentGroupIdProvider);
      if (groupId == null) {
        setState(() => _error = '请先创建账本');
        return;
      }

      var accounts = ref.read(accountsProvider).accounts;
      if (accounts.isEmpty) {
        await ref.read(accountsProvider.notifier).load(groupId);
        accounts = ref.read(accountsProvider).accounts;
        if (accounts.isEmpty) {
          setState(() => _error = '请先在设置中添加账户');
          return;
        }
      }

      final categoryId = await _getCategoryId(_result!.category);

      await ref
          .read(transactionsProvider.notifier)
          .createTransaction(
            type: 'expense',
            amount: _result!.amount,
            currencyCode: _result!.currency,
            accountId: accounts.first.id,
            categoryId: categoryId,
            groupId: groupId,
            isPrivate: false,
            note: _result!.description,
            transactionDate: DateTime.now().millisecondsSinceEpoch / 1000.0,
            receiptUrl: _result!.receiptUrl,
            items: _result!.items,
          );

      setState(() => _result = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('记账成功'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VeeTokens.rSm),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── 模式切换 ──────────────────────────────────────────────────────────────

  Widget _buildModeToggle() {
    final isLoggedIn =
        ref.watch(authProvider).status == AuthStatus.authenticated;

    if (!isLoggedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VeeTokens.s10,
          vertical: VeeTokens.spacingXxs,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(VeeTokens.rMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_android,
              size: VeeTokens.iconXs,
              color: Colors.grey[600],
            ),
            const SizedBox(width: VeeTokens.spacingXxs),
            Text(
              '本地',
              style: context.veeText.micro.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _useLocalOcr ? Icons.phone_android : Icons.cloud_outlined,
          size: VeeTokens.iconXs,
          color: Colors.grey[600],
        ),
        const SizedBox(width: VeeTokens.spacingXxs),
        Text(
          _useLocalOcr ? '本地' : '云端',
          style: context.veeText.micro.copyWith(color: Colors.grey[600]),
        ),
        Transform.scale(
          scale: 0.75,
          child: Switch(
            value: _useLocalOcr,
            onChanged: (v) => setState(() => _useLocalOcr = v),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanReceipt),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: VeeTokens.spacingXs),
            child: _buildModeToggle(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: VeeTokens.maxContentWidth,
          ),
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return _LoadingView(l10n: l10n);

    if (_result != null) {
      return _ConfirmView(
        result: _result!,
        error: _error,
        onConfirm: _confirm,
        onRetake: () => setState(() {
          _result = null;
          _error = null;
        }),
      );
    }

    return _PickerView(
      error: _error,
      onCamera: () => _pickAndOcr(ImageSource.camera),
      onGallery: () => _pickAndOcr(ImageSource.gallery),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 子视图
// ─────────────────────────────────────────────────────────────────────────────

class _PickerView extends StatelessWidget {
  final String? error;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PickerView({
    this.error,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: VeeTokens.s24,
        vertical: VeeTokens.s40,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 主扫描卡
          VeeCard(
            padding: const EdgeInsets.symmetric(
              vertical: VeeTokens.s64,
              horizontal: VeeTokens.spacingLg,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(VeeTokens.spacingLg),
                  decoration: BoxDecoration(
                    color: VeeTokens.selectedTint(
                      Theme.of(context).colorScheme.primaryContainer,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    size: VeeTokens.iconHero,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: VeeTokens.s24),
                Text(l10n.scanReceipt, style: context.veeText.sectionTitle),
                const SizedBox(height: VeeTokens.spacingXs),
                Text(
                  l10n.scanReceiptHint,
                  textAlign: TextAlign.center,
                  style: context.veeText.caption.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VeeTokens.s40),

          // 拍照按钮
          SizedBox(
            width: double.infinity,
            height: VeeTokens.touchStandard + VeeTokens.spacingXs,
            child: FilledButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(l10n.camera),
            ),
          ),
          const SizedBox(height: VeeTokens.spacingMd),

          // 相册按钮
          SizedBox(
            width: double.infinity,
            height: VeeTokens.touchStandard + VeeTokens.spacingXs,
            child: OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(
                Icons.photo_library_outlined,
                color: Colors.black87,
              ),
              label: Text(
                l10n.gallery,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: VeeTokens.s32),
            VeeErrorBanner(message: error!),
          ],
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final AppLocalizations l10n;
  const _LoadingView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(VeeTokens.s24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: VeeTokens.s24),
          Text(l10n.ocrProcessing, style: context.veeText.sectionTitle),
          const SizedBox(height: VeeTokens.spacingXs),
          Text(
            l10n.loading,
            style: context.veeText.caption.copyWith(
              color: VeeTokens.textPlaceholderVal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 结果确认页 ────────────────────────────────────────────────────────────────

class _ConfirmView extends StatelessWidget {
  final _OcrDraft result;
  final String? error;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const _ConfirmView({
    required this.result,
    this.error,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emoji = kCategoryEmoji[result.category] ?? '📦';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: VeeTokens.s16,
              vertical: VeeTokens.s24,
            ),
            children: [
              // ── 金额头部 ────────────────────────────────────────────────
              Column(
                children: [
                  Text(
                    l10n.ocrSuccess,
                    style: context.veeText.caption.copyWith(
                      color: VeeTokens.textPlaceholderVal,
                    ),
                  ),
                  const SizedBox(height: VeeTokens.spacingXs),
                  // VeeAmountDisplay 替代手写双 Text 金额组合
                  VeeAmountDisplay(
                    amount: result.amount,
                    currency: result.currency,
                    size: VeeAmountSize.hero,
                  ),
                ],
              ),
              const SizedBox(height: VeeTokens.s32),

              // ── 基本信息卡 ──────────────────────────────────────────────
              VeeCard.list(
                child: Column(
                  children: [
                    VeeDetailRow(
                      icon: Icons.store_outlined,
                      label: l10n.account,
                      value: result.merchant?.isNotEmpty == true
                          ? result.merchant!
                          : l10n.notSet,
                    ),
                    const Divider(
                      height: 1,
                      indent: VeeTokens.dividerIndentStd,
                    ),
                    VeeDetailRow(
                      icon: Icons.category_outlined,
                      label: l10n.category,
                      value: '$emoji ${result.category ?? l10n.category}',
                    ),
                    const Divider(
                      height: 1,
                      indent: VeeTokens.dividerIndentStd,
                    ),
                    VeeDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.date,
                      value: result.date ?? '',
                    ),
                    if (result.description?.isNotEmpty == true) ...[
                      const Divider(
                        height: 1,
                        indent: VeeTokens.dividerIndentStd,
                      ),
                      VeeDetailRow(
                        icon: Icons.notes_outlined,
                        label: l10n.note,
                        value: result.description!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: VeeTokens.spacingLg),

              // ── 明细 ────────────────────────────────────────────────────
              if (result.items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: VeeTokens.spacingXxs,
                    bottom: VeeTokens.spacingXs,
                  ),
                  child: Text(
                    '${l10n.description} (${result.items.length})',
                    style: context.veeText.sectionTitle,
                  ),
                ),
                VeeCard(
                  padding: VeeTokens.cardPadding,
                  child: Column(
                    children: result.items.map((item) {
                      // Map → TransactionItem 轻量转换（无需 id）
                      final txItem = TransactionItem.fromJson(item);
                      return TransactionItemRow.fromModel(
                        txItem,
                        currency: result.currency,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: VeeTokens.spacingLg),
              ],

              if (error != null) VeeErrorBanner(message: error!),
            ],
          ),
        ),

        // ── 底部操作栏 ──────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left: VeeTokens.s16,
            right: VeeTokens.s16,
            top: VeeTokens.s12,
            bottom: MediaQuery.of(context).padding.bottom + VeeTokens.spacingMd,
          ),
          decoration: BoxDecoration(
            color: VeeTokens.surfaceDefault,
            border: Border(top: BorderSide(color: VeeTokens.borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: VeeTokens.touchStandard + VeeTokens.spacingXxs,
                  child: OutlinedButton(
                    onPressed: onRetake,
                    child: Text(l10n.retake),
                  ),
                ),
              ),
              const SizedBox(width: VeeTokens.s12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: VeeTokens.touchStandard + VeeTokens.spacingXxs,
                  child: FilledButton(
                    onPressed: onConfirm,
                    child: Text(l10n.confirm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
