// lib/screens/ocr/ocr_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bill.dart' show Bill;
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bills_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../services/ml_kit_ocr_service.dart';
import '../../services/local_receipt_parser.dart';
import '../../widgets/bill_item_row.dart';
import '../../widgets/ui_core/vee_error_banner.dart';

class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  final _picker       = ImagePicker();
  final _mlKitService = MlKitOcrService();

  bool    _loading     = false;
  bool    _useLocalOcr = false;
  String? _error;
  Bill?   _result;
  String? _uploadedReceiptUrl;

  @override
  void dispose() {
    _mlKitService.dispose();
    super.dispose();
  }

  // ── categoryId：异步查找，避免返回 0 ─────────────────────────────

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

  // ── OCR 入口 ──────────────────────────────────────────────────────

  Future<void> _pickAndOcr(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1920);
    if (xfile == null) return;

    setState(() {
      _loading = true;
      _error   = null;
      _result  = null;
    });

    try {
      final isLoggedIn =
          ref.read(authProvider).status == AuthStatus.authenticated;

      // Guest 模式或手动选择本地，强制走 ML Kit
      if (!isLoggedIn || _useLocalOcr) {
        await _runLocalOcr(xfile.path);
      } else {
        try {
          await _runCloudOcr(File(xfile.path));
        } catch (_) {
          // 云端失败自动降级
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
    final parsed  = LocalReceiptParser.parse(rawText);
    setState(() => _result = Bill.fromJson({
          ...parsed,
          'id':          0,
          'created_at':  DateTime.now().millisecondsSinceEpoch / 1000,
          'updated_at':  DateTime.now().millisecondsSinceEpoch / 1000,
          'receipt_url': '',
          'source':      'local',
        }));
  }

  Future<void> _runCloudOcr(File file) async {
    final bytes     = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final bill = await ref
        .read(billsProvider.notifier)
        .ocrBill(base64Str, 'image/jpeg');
    setState(() => _result = bill);
  }

  // ── 确认入库 ──────────────────────────────────────────────────────

  Future<void> _confirm() async {
    if (_result == null) return;

    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      // 1. 检查 group
      final groupId = ref.read(currentGroupIdProvider);
      if (groupId == null) {
        setState(() => _error = '请先创建账本');
        return;
      }

      // 2. 检查账户（尝试重新加载）
      var accounts = ref.read(accountsProvider).accounts;
      if (accounts.isEmpty) {
        await ref.read(accountsProvider.notifier).load(groupId);
        accounts = ref.read(accountsProvider).accounts;
        if (accounts.isEmpty) {
          setState(() => _error = '请先在设置中添加账户');
          return;
        }
      }

      // 3. 异步获取 categoryId
      final categoryId = await _getCategoryId(_result!.category);

      // 4. 创建流水
      await ref.read(transactionsProvider.notifier).createTransaction(
        type:            'expense',
        amount:          _result!.amount,
        currencyCode:    _result!.currency,
        accountId:       accounts.first.id,
        categoryId:      categoryId,
        groupId:         groupId,
        isPrivate:       false,
        note:            _result!.description,
        transactionDate: DateTime.now().millisecondsSinceEpoch / 1000.0,
        receiptUrl:      _uploadedReceiptUrl ?? '',
        items: _result!.items.map((e) => e.toJson()).toList(),
      );

      setState(() => _result = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('记账成功'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── 本地/云端切换按钮 ─────────────────────────────────────────────

  Widget _buildModeToggle() {
    final isLoggedIn =
        ref.watch(authProvider).status == AuthStatus.authenticated;

    // Guest 模式：无切换选项，固定本地
    if (!isLoggedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android,
                size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('本地',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      );
    }

    // 已登录：可切换
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _useLocalOcr
              ? Icons.phone_android
              : Icons.cloud_outlined,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          _useLocalOcr ? '本地' : '云端',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  // ── Build ─────────────────────────────────────────────────────────

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
        result:    _result!,
        error:     _error,
        onConfirm: _confirm,
        onRetake:  () => setState(() {
          _result = null;
          _error  = null;
        }),
      );
    }

    return _PickerView(
      error:     _error,
      onCamera:  () => _pickAndOcr(ImageSource.camera),
      onGallery: () => _pickAndOcr(ImageSource.gallery),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. 初始引导页
// ─────────────────────────────────────────────────────────────────────────────

class _PickerView extends StatelessWidget {
  final String?      error;
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
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 说明卡片
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
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.scanReceipt,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.scanReceiptHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5),
              ),
            ]),
          ),
          const SizedBox(height: 40),

          // 相机按钮
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                l10n.camera,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 相册按钮
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: Colors.grey.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined,
                  color: Colors.black87),
              label: Text(
                l10n.gallery,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ),
          ),

          // 错误提示
          if (error != null) ...[
            const SizedBox(height: 32),
            VeeErrorBanner(message: error!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. 加载中
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 24),
          Text(
            l10n.ocrProcessing,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loading,
            style:
                TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. 结果确认页
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmView extends StatelessWidget {
  final Bill         result;
  final String?      error;
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
    final l10n   = AppLocalizations.of(context)!;
    final amount = kAmountFormat.format(result.amount);
    final emoji  = kCategoryEmoji[result.category] ?? '📦';

    return Column(
      children: [
        // 滚动区域
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 24),
            children: [
              // 金额头部
              Column(children: [
                Text(
                  l10n.ocrSuccess,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      result.currency,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 32),

              // 基本信息
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(children: [
                  _InfoRow(
                    icon: Icons.store_outlined,
                    label: l10n.account,
                    value: result.merchant ?? l10n.notSet,
                  ),
                  const Divider(height: 1, indent: 48),
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: l10n.category,
                    value:
                        '$emoji ${result.category ?? l10n.category}',
                  ),
                  const Divider(height: 1, indent: 48),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.date,
                    value: result.billDate ?? '',
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

              // 明细
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
                    side: BorderSide(
                        color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: result.items
                          .map((item) => BillItemRow.fromModel(item,
                              currency: result.currency))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 错误提示（确认失败时）
              if (error != null) VeeErrorBanner(message: error!),
            ],
          ),
        ),

        // 底部操作栏
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
                top: BorderSide(
                    color: Colors.grey.withOpacity(0.2))),
          ),
          child: Row(children: [
            // 重拍
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.grey.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onRetake,
                  child: Text(l10n.retake,
                      style: const TextStyle(
                          color: Colors.black87)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 确认
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onConfirm,
                  child: Text(
                    l10n.confirm,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── 信息行 ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[500]),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 14)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
}