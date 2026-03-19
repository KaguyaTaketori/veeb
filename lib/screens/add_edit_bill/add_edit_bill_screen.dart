// lib/screens/add_edit_bill/add_edit_bill_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/bills_api.dart';
import '../../constants/categories.dart';
import '../../models/bill.dart';

class AddEditBillScreen extends ConsumerStatefulWidget {
  final Bill? bill;
  const AddEditBillScreen({super.key, this.bill});

  @override
  ConsumerState<AddEditBillScreen> createState() => _AddEditBillScreenState();
}

class _AddEditBillScreenState extends ConsumerState<AddEditBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _amountCtrl;
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _dateCtrl;

  String _currency = 'JPY';
  String _category = '其他';

  File? _pendingImageFile;
  String _receiptUrl = '';
  bool _uploadingImage = false;

  // 明细列表（可增删改）
  late List<_EditableBillItem> _items;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.bill != null;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    _amountCtrl = TextEditingController(
        text: b != null ? b.amount.toStringAsFixed(0) : '');
    _merchantCtrl = TextEditingController(text: b?.merchant ?? '');
    _descCtrl = TextEditingController(text: b?.description ?? '');
    _dateCtrl = TextEditingController(
        text: b?.billDate ??
            DateTime.now().toIso8601String().substring(0, 10));
    if (b != null) {
      _currency = b.currency;
      _category = b.category ?? '其他';
      _receiptUrl = b.receiptUrl;
    }
    // 初始化明细
    _items = (b?.items ?? [])
        .map((item) => _EditableBillItem.fromModel(item))
        .toList();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // ── 图片 ──────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1920);
    if (xfile == null) return;
    setState(() {
      _pendingImageFile = File(xfile.path);
      _receiptUrl = '';
    });
  }

  Future<String?> _uploadPendingImage() async {
    if (_pendingImageFile == null) return _receiptUrl;
    setState(() => _uploadingImage = true);
    try {
      final bytes = await _pendingImageFile!.readAsBytes();
      final filename = _pendingImageFile!.path.split('/').last;
      final mimeType =
          filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final url = await ref.read(billsApiProvider).uploadReceipt(
            fileBytes: bytes,
            filename: filename,
            mimeType: mimeType,
          );
      return url;
    } catch (e) {
      setState(() => _error = '图片上传失败：$e');
      return null;
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  void _removeImage() => setState(() {
        _pendingImageFile = null;
        _receiptUrl = '';
      });

  void _syncAmountFromItems() {
    if (_items.isEmpty) return;
    final total = _items.fold<double>(
        0.0,
        (sum, e) => sum + (double.tryParse(e.amountCtrl.text.trim()) ?? 0.0),
    );
    _amountCtrl.text = total.toStringAsFixed(0);
  }


  // ── 明细操作 ──────────────────────────────────────────────────────────

  void _addItem() {
    setState(() => _items.add(_EditableBillItem.empty()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
    _syncAmountFromItems();
  }

  /// 弹出单条明细编辑对话框
  Future<void> _editItem(int index) async {
    final item = _items[index];
    // 对话框内使用独立 controller，确认后才写回
    final nameCtrl = TextEditingController(text: item.nameCtrl.text);
    final amountCtrl = TextEditingController(text: item.amountCtrl.text);
    final qtyCtrl = TextEditingController(text: item.qtyCtrl.text);
    String itemType = item.itemType;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(index < _items.length ? '明細を編集' : '明細を追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 名称
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '商品名 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // 金额 + 数量（同行）
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: '金額 *',
                          prefixText: '¥',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: '数量',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 类型
                DropdownButtonFormField<String>(
                  value: itemType,
                  decoration: const InputDecoration(
                    labelText: '種別',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'item', child: Text('商品')),
                    DropdownMenuItem(value: 'discount', child: Text('割引')),
                    DropdownMenuItem(value: 'tax', child: Text('税金')),
                  ],
                  onChanged: (v) => setInner(() => itemType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                if (double.tryParse(amountCtrl.text.trim()) == null) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();

    if (confirmed == true) {
      setState(() {
        item.nameCtrl.text = nameCtrl.text.trim();
        item.amountCtrl.text = amountCtrl.text.trim();
        item.qtyCtrl.text =
            qtyCtrl.text.trim().isEmpty ? '1' : qtyCtrl.text.trim();
        item.itemType = itemType;
      });
      _syncAmountFromItems();
    }

    amountCtrl.dispose();
    qtyCtrl.dispose();
  }

  // ── 保存 ──────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // 校验明细：有明细时名称和金额不能为空
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.nameCtrl.text.trim().isEmpty) {
        setState(() => _error = '明細 ${i + 1} の商品名を入力してください');
        return;
      }
      if (double.tryParse(item.amountCtrl.text.trim()) == null) {
        setState(() => _error = '明細 ${i + 1} の金額が無効です');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final finalReceiptUrl = await _uploadPendingImage();
      if (_pendingImageFile != null && finalReceiptUrl == null) return;

      final amount = double.parse(_amountCtrl.text.trim());
      final itemsJson = _items
          .asMap()
          .entries
          .map((e) => {
                'name': e.value.nameCtrl.text.trim(),
                'name_raw': '',
                'quantity':
                    double.tryParse(e.value.qtyCtrl.text.trim()) ?? 1.0,
                'amount':
                    double.tryParse(e.value.amountCtrl.text.trim()) ?? 0.0,
                'item_type': e.value.itemType,
                'sort_order': e.key,
              })
          .toList();

      final api = ref.read(billsApiProvider);

      if (_isEdit) {
        final updates = <String, dynamic>{};
        if (amount != widget.bill!.amount) updates['amount'] = amount;
        if (_currency != widget.bill!.currency) updates['currency'] = _currency;
        if (_category != widget.bill!.category) updates['category'] = _category;
        if (_merchantCtrl.text.trim() != widget.bill!.merchant)
          updates['merchant'] = _merchantCtrl.text.trim();
        if (_descCtrl.text.trim() != widget.bill!.description)
          updates['description'] = _descCtrl.text.trim();
        if (_dateCtrl.text.trim() != widget.bill!.billDate)
          updates['bill_date'] = _dateCtrl.text.trim();
        if (finalReceiptUrl != null &&
            finalReceiptUrl != widget.bill!.receiptUrl)
          updates['receipt_url'] = finalReceiptUrl;
        // 明细变更：重新创建账单（PATCH 不支持 items，走 delete + create）
        if (_itemsChanged()) {
          await api.deleteBill(widget.bill!.id);
          await api.createBill({
            'amount': amount,
            'currency': _currency,
            'category': _category,
            'merchant': _merchantCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'bill_date': _dateCtrl.text.trim(),
            'receipt_url': finalReceiptUrl ?? widget.bill!.receiptUrl,
            'items': itemsJson,
          });
        } else if (updates.isNotEmpty) {
          await api.patchBill(widget.bill!.id, updates);
        }
      } else {
        await api.createBill({
          'amount': amount,
          'currency': _currency,
          'category': _category,
          'merchant': _merchantCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'bill_date': _dateCtrl.text.trim(),
          'receipt_url': finalReceiptUrl ?? '',
          'items': itemsJson,
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 判断明细是否有变动
  bool _itemsChanged() {
    final original = widget.bill?.items ?? [];
    if (original.length != _items.length) return true;
    for (int i = 0; i < original.length; i++) {
      final o = original[i];
      final n = _items[i];
      if (o.name != n.nameCtrl.text.trim()) return true;
      if (o.amount.toStringAsFixed(2) !=
          (double.tryParse(n.amountCtrl.text.trim()) ?? 0)
              .toStringAsFixed(2)) return true;
      if (o.quantity !=
          (double.tryParse(n.qtyCtrl.text.trim()) ?? 1)) return true;
      if (o.itemType != n.itemType) return true;
    }
    return false;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateCtrl.text) ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      _dateCtrl.text = picked.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '編集' : '手動記帳'),
        actions: [
          if (_saving || _uploadingImage)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:
                    Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            // 金额
            TextFormField(
            controller: _amountCtrl,
            // 有明细时只读，由明细合计驱动
            readOnly: _items.isNotEmpty,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: '金額 *',
                prefixText: '¥ ',
                border: const OutlineInputBorder(),
                filled: _items.isNotEmpty,
                fillColor: _items.isNotEmpty ? Colors.grey.shade100 : null,
                // 有明细时显示提示，说明金额来源
                helperText: _items.isNotEmpty ? '明細合計から自動計算' : null,
                helperStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
                suffixIcon: _items.isNotEmpty
                    ? const Tooltip(
                        message: '明細が存在する場合、金額は自動計算されます',
                        child: Icon(Icons.info_outline, size: 18),
                    )
                    : null,
            ),
            validator: (v) {
                if (v == null || v.trim().isEmpty) return '金額を入力してください';
                if (double.tryParse(v.trim()) == null) return '数字を入力してください';
                if (double.parse(v.trim()) <= 0) return '0より大きい金額を入力してください';
                return null;
            },
            ),
            const SizedBox(height: 12),

            // 货币 + 类别
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                        labelText: '通貨', border: OutlineInputBorder()),
                    items: ['JPY', 'CNY', 'USD', 'EUR', 'HKD']
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                        labelText: 'カテゴリ', border: OutlineInputBorder()),
                    items: kCategoryEmoji.keys
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${kCategoryEmoji[c] ?? ''} $c')))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 商家
            TextFormField(
              controller: _merchantCtrl,
              decoration: const InputDecoration(
                  labelText: '商家', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // 描述
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: '備考', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // 日期
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: '日付 *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '日付を選択してください' : null,
            ),
            const SizedBox(height: 20),

            // 图片凭证
            _ReceiptPicker(
              pendingFile: _pendingImageFile,
              receiptUrl: _receiptUrl,
              uploading: _uploadingImage,
              onPickCamera: () => _pickImage(ImageSource.camera),
              onPickGallery: () => _pickImage(ImageSource.gallery),
              onRemove: _removeImage,
            ),
            const SizedBox(height: 24),

            // ── 明细区块 ───────────────────────────────────────────────
            _ItemsSection(
              items: _items,
              onAdd: _addItem,
              onEdit: _editItem,
              onRemove: _removeItem,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 明细区块
// ---------------------------------------------------------------------------

class _ItemsSection extends StatelessWidget {
  final List<_EditableBillItem> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  const _ItemsSection({
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '明細 (${items.length}件)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('追加'),
            ),
          ],
        ),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 32, color: Colors.grey[400]),
                const SizedBox(height: 4),
                Text('明細なし',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                Text('「追加」をタップして明細を入力',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          )
        else
          // 使用 ReorderableListView 支持拖拽排序
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              // ReorderableListView 内部会在 onReorder 里通知，
              // 但 items 是外部传入的，通知父级需要回调；
              // 此处简化：直接在 StatefulWidget 层处理
            },
            itemBuilder: (ctx, index) {
              final item = items[index];
              final typeLabel = _typeLabel(item.itemType);
              final typeColor = _typeColor(item.itemType, ctx);
              final amount =
                  double.tryParse(item.amountCtrl.text) ?? 0;
              final qty = double.tryParse(item.qtyCtrl.text) ?? 1;

              return Card(
                key: ValueKey(item.key),
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: typeColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    item.nameCtrl.text.isNotEmpty
                        ? item.nameCtrl.text
                        : '(未入力)',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: qty != 1
                      ? Text('×${qty.toStringAsFixed(qty == qty.truncate() ? 0 : 1)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¥${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.itemType == 'discount'
                              ? Colors.red
                              : Theme.of(ctx).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => onEdit(index),
                        tooltip: '編集',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: Colors.red[300]),
                        onPressed: () => onRemove(index),
                        tooltip: '削除',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // 合计行
        if (items.isNotEmpty) ...[
        const Divider(),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(
                '明細合計',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                '¥${_calcTotal(items).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
            ),
        ),
        ],
        const SizedBox(height: 80), // FAB 留空
      ],
    );
  }

  double _calcTotal(List<_EditableBillItem> items) => items.fold(
      0.0, (sum, e) => sum + (double.tryParse(e.amountCtrl.text) ?? 0));

  String _typeLabel(String type) {
    switch (type) {
      case 'discount': return '割引';
      case 'tax':      return '税';
      default:         return '商品';
    }
  }

  Color _typeColor(String type, BuildContext ctx) {
    switch (type) {
      case 'discount': return Colors.red;
      case 'tax':      return Colors.orange;
      default:         return Theme.of(ctx).colorScheme.primary;
    }
  }
}

// ---------------------------------------------------------------------------
// 可编辑明细数据类
// ---------------------------------------------------------------------------

class _EditableBillItem {
  final String key; // 用于 ReorderableListView key
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController qtyCtrl;
  String itemType;

  _EditableBillItem({
    required this.key,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.qtyCtrl,
    required this.itemType,
  });

  factory _EditableBillItem.empty() => _EditableBillItem(
        key: UniqueKey().toString(),
        nameCtrl: TextEditingController(),
        amountCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(text: '1'),
        itemType: 'item',
      );

  factory _EditableBillItem.fromModel(BillItem item) => _EditableBillItem(
        key: UniqueKey().toString(),
        nameCtrl: TextEditingController(text: item.name),
        amountCtrl:
            TextEditingController(text: item.amount.toStringAsFixed(0)),
        qtyCtrl: TextEditingController(
            text: item.quantity.toStringAsFixed(
                item.quantity == item.quantity.truncate() ? 0 : 1)),
        itemType: item.itemType,
      );

  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
    qtyCtrl.dispose();
  }
}

// ---------------------------------------------------------------------------
// 图片选择组件（不变）
// ---------------------------------------------------------------------------

class _ReceiptPicker extends StatelessWidget {
  final File? pendingFile;
  final String receiptUrl;
  final bool uploading;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  const _ReceiptPicker({
    required this.pendingFile,
    required this.receiptUrl,
    required this.uploading,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  bool get _hasImage => pendingFile != null || receiptUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '凭证图片',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_hasImage)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: pendingFile != null
                    ? Image.file(pendingFile!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover)
                    : Image.network(receiptUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover),
              ),
              if (uploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.black54, iconSize: 18),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onRemove,
                ),
              ),
            ],
          )
        else
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PickButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'カメラ',
                    onTap: onPickCamera),
                const SizedBox(width: 32),
                _PickButton(
                    icon: Icons.photo_library_outlined,
                    label: 'アルバム',
                    onTap: onPickGallery),
              ],
            ),
          ),
        if (_hasImage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('再撮影'),
                ),
                TextButton.icon(
                  onPressed: onPickGallery,
                  icon:
                      const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('選び直す'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}