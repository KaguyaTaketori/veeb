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

    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final bytes = await File(xfile.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      final mimeType = xfile.mimeType ?? 'image/jpeg';
      final data = await _billsApi.ocrBill(base64Str, mimeType);
      setState(() { _result = Bill.fromJson(data); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _confirm() async {
    if (_result == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _billsApi.createBill(_result!.toJson());
      setState(() { _result = null; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記帳しました！')),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('拍照記帳')),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI解析中...'),
                ],
              ),
            )
          : _result != null
              ? _ConfirmView(
                  result: _result!,
                  onConfirm: _confirm,
                  onRetake: () => setState(() => _result = null),
                )
              : _PickerView(
                  error: _error,
                  onCamera: () => _pickAndOcr(ImageSource.camera),
                  onGallery: () => _pickAndOcr(ImageSource.gallery),
                ),
    );
  }
}


class _PickerView extends StatelessWidget {
  final String? error;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PickerView({this.error, required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text('レシートを撮影してAIが自動解析します',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          FilledButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('カメラで撮影')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('アルバムから選択')),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}


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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '¥$amount ${result.currency}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: '商家', value: result.merchant ?? '不明'),
          _InfoRow(label: 'カテゴリ', value: '$emoji ${result.category ?? 'その他'}'),
          _InfoRow(label: '日付', value: result.billDate ?? ''),
          if (result.items.isNotEmpty) ...[
            const Divider(height: 24),
            Text('明細', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...result.items.map((item) => BillItemRow.fromModel(item)),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: onRetake, child: const Text('撮り直す')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                    onPressed: onConfirm, child: const Text('確認・保存')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}