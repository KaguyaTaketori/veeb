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
import '../../providers/bills_provider.dart';
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
  final _picker        = ImagePicker();
  final _mlKitService  = MlKitOcrService();
  bool  _loading       = false;
  bool  _useLocalOcr   = false;
  String? _error;
  Bill?   _result;

  @override
  void dispose() {
    _mlKitService.dispose();
    super.dispose();
  }

  Future<void> _pickAndOcr(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1920);
    if (xfile == null) return;

    setState(() { _loading = true; _error = null; _result = null; });

    try {
      if (_useLocalOcr) {
        await _runLocalOcr(xfile.path);
      } else {
        await _runCloudOcr(File(xfile.path));
      }
    } catch (e) {
      if (!_useLocalOcr) {
        try {
          await _runLocalOcr(xfile.path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('云端识别失败，已切换至本地模式')),
            );
          }
        } catch (e2) {
          setState(() => _error = e2.toString());
        }
      } else {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runLocalOcr(String imagePath) async {
    final rawText = await _mlKitService.recognizeFromFile(imagePath);
    final parsed  = LocalReceiptParser.parse(rawText);
    setState(() => _result = Bill.fromJson({
      ...parsed,
      'id':         0,
      'created_at': DateTime.now().millisecondsSinceEpoch / 1000,
      'updated_at': DateTime.now().millisecondsSinceEpoch / 1000,
      'receipt_url': '',
      'source':     'local',
    }));
  }

  Future<void> _runCloudOcr(File file) async {
    final bytes    = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final bill = await ref
        .read(billsProvider.notifier)
        .ocrBill(base64Str, 'image/jpeg');
    setState(() => _result = bill);
  }

  Widget _buildModeToggle() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        _useLocalOcr ? Icons.phone_android : Icons.cloud_outlined,
        size: 16, color: Colors.grey,
      ),
      const SizedBox(width: 4),
      Text(_useLocalOcr ? '本地' : '云端',
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      Switch(
        value: _useLocalOcr,
        onChanged: (v) => setState(() => _useLocalOcr = v),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _LoadingView();
    } else if (_result != null) {
      return _ConfirmView(
        result: _result!,
        onConfirm: () => Navigator.pop(context, _result),
        onRetake: () => setState(() => _result = null),
      );
    } else {
      return _PickerView(
        error: _error,
        onCamera: () => _pickAndOcr(ImageSource.camera),
        onGallery: () => _pickAndOcr(ImageSource.gallery),
      );
    }
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
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
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
                Text(
                  l10n.scanReceipt,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.scanReceiptHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(l10n.camera, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
              label: Text(l10n.gallery, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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

// ── 2. 加载中状态页 ─────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.ocrProcessing,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loading,
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
    final l10n = AppLocalizations.of(context)!;
    final amount = kAmountFormat.format(result.amount);
    final emoji = kCategoryEmoji[result.category] ?? '📦';

    return Column(
      children:[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children:[
              Column(
                children:[
                  Text(l10n.ocrSuccess, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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
                      label: l10n.account,
                      value: result.merchant ?? l10n.notSet,
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildInfoRow(
                      icon: Icons.category_outlined,
                      label: l10n.category,
                      value: '$emoji ${result.category ?? l10n.category}',
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.date,
                      value: result.billDate ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (result.items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    '${l10n.description} (${result.items.length})',
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
                    child: Text(l10n.retake, style: const TextStyle(color: Colors.black87)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onConfirm,
                    child: Text(l10n.confirm, style: const TextStyle(fontWeight: FontWeight.bold)),
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