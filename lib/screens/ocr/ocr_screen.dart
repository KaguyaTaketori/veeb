// lib/screens/ocr/ocr_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/categories.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../api/transactions_api.dart';
import '../../services/ml_kit_ocr_service.dart';
import '../../services/local_receipt_parser.dart';
import '../../utils/currency.dart';
import '../../widgets/ui_core/vee_error_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OCR 解析草稿（取代 Bill 模型，轻量内部 DTO）
// ─────────────────────────────────────────────────────────────────────────────

class _OcrDraft {
  final double amount;
  final String currency;
  final String? merchant;
  final String? category;
  final String? date; // YYYY-MM-DD
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

  /// 从 OCR API / LocalReceiptParser 返回的 Map 构造
  factory _OcrDraft.fromMap(Map<String, dynamic> map) {
    // 兼容 bill_date / date 两种字段名
    final rawDate =
        (map['bill_date'] ?? map['date'] ?? map['transaction_date']) as String?;
    // items 可能是 List<Map> 或 List<BillItem-like>
    final rawItems = (map['items'] as List? ?? []);
    final items = rawItems.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      // 如果是 BillItem 对象调用 toJson
      try {
        return (e as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((e) => e.isNotEmpty).toList();

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
  _OcrDraft? _result; // ← Bill から _OcrDraft に変更
  String? _uploadedReceiptUrl;

  @override
  void dispose() {
    _mlKitService.dispose();
    super.dispose();
  }

  // ── categoryId 解決 ──────────────────────────────────────────────────────

  Future<int> _getCategoryId(String? categoryName) async {
    final groupId = ref.read(currentGroupIdProvider);
    try {
      final categories =
          await ref.read(categoriesProvider(groupId).future);
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
        source: source, imageQuality: 85, maxWidth: 1920);
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
          // 云端失败自动降级到本地
          await _runLocalOcr(xfile.path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('云端识别失败，已切换至本地模式'),
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── 本地 ML Kit ───────────────────────────────────────────────────────────

  Future<void> _runLocalOcr(String imagePath) async {
    final rawText = await _mlKitService.recognizeFromFile(imagePath);
    final parsed = LocalReceiptParser.parse(rawText);
    setState(() => _result = _OcrDraft.fromMap(parsed));
  }

  // ── 云端 OCR（直接使用 TransactionsApi，不再依赖 BillsApi）────────────────

  Future<void> _runCloudOcr(File file) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);

    // TransactionsApi.ocrTransaction 返回 Map<String, dynamic>
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

      await ref.read(transactionsProvider.notifier).createTransaction(
        type: 'expense',
        amount: _result!.amount,
        currencyCode: _result!.currency,
        accountId: accounts.first.id,
        categoryId: categoryId,
        groupId: groupId,
        isPrivate: false,
        note: _result!.description,
        transactionDate:
            DateTime.now().millisecondsSinceEpoch / 1000.0,
        receiptUrl: _uploadedReceiptUrl ?? _result!.receiptUrl,
        items: _result!.items,
      );

      setState(() => _result = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('记账成功'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.phone_android, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text('本地',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ]),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        _useLocalOcr ? Icons.phone_android : Icons.cloud_outlined,
        size: 14,
        color: Colors.grey[600],
      ),
      const SizedBox(width: 4),
      Text(_useLocalOcr ? '本地' : '云端',
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      Transform.scale(
        scale: 0.75,
        child: Switch(
          value: _useLocalOcr,
          onChanged: (v) => setState(() => _useLocalOcr = v),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ]);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.scanReceipt,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildModeToggle(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const _LoadingView();

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
  const _PickerView(
      {this.error, required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 60, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.grey.withOpacity(0.3), width: 1.5),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.document_scanner_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(l10n.scanReceipt,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(l10n.scanReceiptHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5)),
            ]),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(l10n.camera,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined,
                  color: Colors.black87),
              label: Text(l10n.gallery,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 32),
            VeeErrorBanner(message: error!),
          ],
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5)
            ],
          ),
          child: const CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text(l10n.ocrProcessing,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.loading,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ]),
    );
  }
}

// ── 结果确认页（使用 _OcrDraft，不再依赖 Bill）────────────────────────────────

class _ConfirmView extends StatelessWidget {
  final _OcrDraft result;
  final String? error;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;
  const _ConfirmView(
      {required this.result,
      this.error,
      required this.onConfirm,
      required this.onRetake});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountStr = formatAmount(result.amount, result.currency);
    final emoji = kCategoryEmoji[result.category] ?? '📦';
    final currencySymbol = result.currency == 'JPY' ? '¥' : '${result.currency} ';

    return Column(children: [
      Expanded(
        child: ListView(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // ── 金额头部 ────────────────────────────────────────────────
            Column(children: [
              Text(l10n.ocrSuccess,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(result.currency,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(width: 8),
                  Text(amountStr,
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color:
                              Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ]),
            const SizedBox(height: 32),

            // ── 基本信息 ────────────────────────────────────────────────
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(children: [
                _InfoRow(
                  icon: Icons.store_outlined,
                  label: l10n.account,
                  value: result.merchant?.isNotEmpty == true
                      ? result.merchant!
                      : l10n.notSet,
                ),
                const Divider(height: 1, indent: 48),
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: l10n.category,
                  value: '$emoji ${result.category ?? l10n.category}',
                ),
                const Divider(height: 1, indent: 48),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: l10n.date,
                  value: result.date ?? '',
                ),
                if (result.description?.isNotEmpty == true) ...[
                  const Divider(height: 1, indent: 48),
                  _InfoRow(
                    icon: Icons.notes_outlined,
                    label: l10n.note,
                    value: result.description!,
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 24),

            // ── 明细 ────────────────────────────────────────────────────
            if (result.items.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '${l10n.description} (${result.items.length})',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:
                      BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: result.items.map((item) {
                      final isDisc = item['item_type'] == 'discount';
                      final isTax = item['item_type'] == 'tax';
                      final amt =
                          (item['amount'] as num?)?.toDouble() ?? 0;
                      final name = item['name'] as String? ?? '';
                      final amtStr = formatAmount(amt.abs(), result.currency);
                      final qty =
                          (item['quantity'] as num?)?.toDouble() ?? 1.0;
                      final itemColor = isDisc
                          ? Colors.red
                          : isTax
                              ? Colors.grey
                              : Theme.of(context).colorScheme.onSurface;

                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          Text(
                              isDisc
                                  ? '➖'
                                  : isTax
                                      ? '🧾'
                                      : '•',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(name,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: itemColor))),
                          if (qty != 1.0)
                            Text('x${qty.toInt()}  ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600])),
                          Text(
                            isDisc
                                ? '-$currencySymbol$amtStr'
                                : '$currencySymbol$amtStr',
                            style: TextStyle(
                                fontSize: 13,
                                color: itemColor,
                                fontWeight: FontWeight.w500),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (error != null) VeeErrorBanner(message: error!),
          ],
        ),
      ),

      // ── 底部操作栏 ──────────────────────────────────────────────────
      Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border:
              Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
        ),
        child: Row(children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onRetake,
                child: Text(l10n.retake,
                    style: const TextStyle(color: Colors.black87)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: onConfirm,
                child: Text(l10n.confirm,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[500]),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(label,
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 14)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
      );
}