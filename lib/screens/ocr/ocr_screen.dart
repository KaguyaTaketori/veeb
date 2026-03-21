// lib/screens/ocr/ocr_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/bills_api.dart';
import '../../constants/categories.dart';
import '../../models/bill.dart' show Bill;
import '../../widgets/bill_item_row.dart';

class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  final _picker = ImagePicker();
  bool _loading = false;
  String? _error;
  Bill? _result;

  BillsApi get _billsApi => ref.read(billsApiProvider);

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
      final bytes = await File(xfile.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      final mimeType = xfile.mimeType ?? 'image/jpeg';
      final data = await _billsApi.ocrBill(base64Str, mimeType);
      setState(() {
        _result = Bill.fromJson(data);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_result == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groupId = ref.read(currentGroupIdProvider);
      final accounts = ref.read(accountsProvider).accounts;
      if (groupId == null || accounts.isEmpty) {
        // 提示用户先创建账本
        return;
      }
      await ref.read(transactionsApiProvider).createTransaction({
        'type':             'expense',
        'amount':           _result!.amount,
        'currency_code':    _result!.currency,
        'exchange_rate':    1.0,
        'account_id':       accounts.first.id,
        'category_id':      _getCategoryId(_result!.category),
        'group_id':         groupId,
        'note':             _result!.description,
        'transaction_date': DateTime.now().millisecondsSinceEpoch / 1000.0,
        'receipt_url':      _uploadedReceiptUrl ?? '',
        'items':            _result!.items.map((e) => e.toJson()).toList(),
      });
      setState(() {
        _result = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('記帳が完了しました！'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // 统一的浅灰色背景
      appBar: AppBar(
        title: const Text('AI 読取', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680), // 宽屏保护
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _LoadingView();
    }
    if (_result != null) {
      return _ConfirmView(
        result: _result!,
        onConfirm: _confirm,
        onRetake: () => setState(() => _result = null),
      );
    }
    return _PickerView(
      error: _error,
      onCamera: () => _pickAndOcr(ImageSource.camera),
      onGallery: () => _pickAndOcr(ImageSource.gallery),
    );
  }
}

// ── 1. 初始上传引导页 ───────────────────────────────────────────────────

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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          // 巨大的引导卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              children:[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.document_scanner_outlined,
                      size: 64, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'レシートを自動解析',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'AIが画像を読み取り、金額や明細を\n自動で入力します',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // 操作按钮
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('カメラで撮影する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined, color: Colors.black87),
              label: const Text('アルバムから選ぶ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
          ),
          
          if (error != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 2. 加载中状态页 ─────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow:[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          const Text(
            'AIがレシートを解析中...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '数秒かかる場合があります',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── 3. 结果确认页 (极致统一的设计语言) ──────────────────────────────────

class _ConfirmView extends StatelessWidget {
  final Bill result;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const _ConfirmView({
    required this.result,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final amount = kAmountFormat.format(result.amount);
    final emoji = kCategoryEmoji[result.category] ?? '📦';

    return Column(
      children:[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children:[
              // 居中大视觉金额提示
              Column(
                children:[
                  Text('解析結果', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children:[
                      Text(
                        result.currency,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 基本信息卡片
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children:[
                    _buildInfoRow(
                      icon: Icons.store_outlined,
                      label: '商家',
                      value: result.merchant ?? '不明',
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildInfoRow(
                      icon: Icons.category_outlined,
                      label: 'カテゴリ',
                      value: '$emoji ${result.category ?? 'その他'}',
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: '日付',
                      value: result.billDate ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 明细卡片
              if (result.items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    '読み取った明細 (${result.items.length}件)',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
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
                      children: result.items
                          .map((item) => BillItemRow.fromModel(item))
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),

        // 底部固定的操作按钮区
        Container(
          padding: const EdgeInsets.all(16).copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Row(
            children:[
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onRetake,
                    child: const Text('撮り直す', style: TextStyle(color: Colors.black87)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2, // 让确认保存按钮占据更大比例
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onConfirm,
                    child: const Text('確認して保存', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}