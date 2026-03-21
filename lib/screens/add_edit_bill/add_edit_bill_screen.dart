// lib/screens/add_edit_bill/add_edit_bill_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/categories.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bill.dart';
import '../../providers/bills_provider.dart';
import '../../widgets/ui_core/vee_error_banner.dart';

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
  String _category = '';

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
      _category = b.category ?? '';
      _receiptUrl = b.receiptUrl;
    }
    // 初始化明细
    _items = (b?.items ??[])
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

  // ── 图片操作 ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1920);
    if (xfile == null) return;
    setState(() {
      _pendingImageFile = File(xfile.path);
      _receiptUrl = '';
    });
  }

  Future<String?> _uploadPendingImage([AppLocalizations? l10n]) async {
    if (_pendingImageFile == null) return _receiptUrl;
    setState(() => _uploadingImage = true);
    try {
      final bytes = await _pendingImageFile!.readAsBytes();
      final filename = _pendingImageFile!.path.split('/').last;
      final mimeType =
          filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final url = await ref.read(billsProvider.notifier).uploadReceipt(
            fileBytes: bytes,
            filename: filename,
            mimeType: mimeType,
          );
      return url;
    } catch (e) {
      setState(() => _error = l10n?.imageUploadFailed(e.toString()) ?? 'Image upload failed: $e');
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
    final l10n = AppLocalizations.of(context)!;
    final item = _items[index];
    final nameCtrl = TextEditingController(text: item.nameCtrl.text);
    final amountCtrl = TextEditingController(text: item.amountCtrl.text);
    final qtyCtrl = TextEditingController(text: item.qtyCtrl.text);
    String itemType = item.itemType;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(index < _items.length ? l10n.edit : l10n.addDetail),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:[
                // 种别切换：使用 SegmentedButton 替代下拉菜单，减少点击次数
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'item', label: Text(l10n.product)),
                    ButtonSegment(value: 'discount', label: Text(l10n.discount)),
                    ButtonSegment(value: 'tax', label: Text(l10n.tax)),
                  ],
                  selected: {itemType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setInner(() => itemType = newSelection.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: '${l10n.productName} *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children:[
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: '${l10n.amount} *',
                          prefixText: '¥ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.quantity,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions:[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                if (double.tryParse(amountCtrl.text.trim()) == null) return;
                Navigator.pop(ctx, true);
              },
              child: Text(l10n.confirm),
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

    final l10n = AppLocalizations.of(context)!;
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.nameCtrl.text.trim().isEmpty) {
        setState(() => _error = l10n.enterProductName);
        return;
      }
      if (double.tryParse(item.amountCtrl.text.trim()) == null) {
        setState(() => _error = l10n.invalidAmountForItem(i + 1));
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final finalReceiptUrl = await _uploadPendingImage(l10n);
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

      final notifier = ref.read(billsProvider.notifier);

      if (_isEdit) {
        if (_itemsChanged()) {
          await notifier.deleteBill(widget.bill!.id);
          await notifier.createBill(
            amount: amount,
            currency: _currency,
            category: _category,
            merchant: _merchantCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            billDate: _dateCtrl.text.trim(),
            receiptUrl: finalReceiptUrl ?? widget.bill!.receiptUrl,
            items: itemsJson,
          );
        } else {
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

          if (updates.isNotEmpty) {
            await notifier.updateBill(
              id: widget.bill!.id,
              amount: updates['amount'] as double?,
              currency: updates['currency'] as String?,
              category: updates['category'] as String?,
              merchant: updates['merchant'] as String?,
              description: updates['description'] as String?,
              billDate: updates['bill_date'] as String?,
              receiptUrl: updates['receipt_url'] as String?,
            );
          }
        }
      } else {
        await notifier.createBill(
          amount: amount,
          currency: _currency,
          category: _category,
          merchant: _merchantCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          billDate: _dateCtrl.text.trim(),
          receiptUrl: finalReceiptUrl,
          items: itemsJson,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _itemsChanged() {
    final original = widget.bill?.items ??[];
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

  // ── 构建 UI ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isEdit ? l10n.edit : l10n.addBill),
        centerTitle: true,
        actions:[
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
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.tonal(
                onPressed: _save,
                child: Text(l10n.save),
              ),
            ),
        ],
      ),
      // 优化点 1：使用 Center + ConstrainedBox 防止宽屏下无限拉伸
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children:[
                if (_error != null)
                  VeeErrorBanner(message: _error!),

                // 优化点 2：突出核心要素（大字号金额输入）
                _buildAmountHeader(l10n),
                const SizedBox(height: 24),

                // 优化点 3：基本信息卡片化，摒弃 OutlineInputBorder
                _buildBasicDetailsCard(l10n),
                const SizedBox(height: 16),

                // 凭证图片区块
                _ReceiptPicker(
                  l10n: l10n,
                  pendingFile: _pendingImageFile,
                  receiptUrl: _receiptUrl,
                  uploading: _uploadingImage,
                  onPickCamera: () => _pickImage(ImageSource.camera),
                  onPickGallery: () => _pickImage(ImageSource.gallery),
                  onRemove: _removeImage,
                ),
                const SizedBox(height: 24),

                // 明细区块
                _ItemsSection(
                  l10n: l10n,
                  items: _items,
                  onAdd: _addItem,
                  onEdit: _editItem,
                  onRemove: _removeItem,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建顶部巨大金额区域
  Widget _buildAmountHeader(AppLocalizations l10n) {
    final hasItems = _items.isNotEmpty;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children:[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children:[
            // 币种选择器（极简化）
            DropdownButton<String>(
              value: _currency,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              items:['JPY', 'CNY', 'USD', 'EUR', 'HKD']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(width: 8),
            // 巨大金额输入框
            IntrinsicWidth(
              child: TextFormField(
                controller: _amountCtrl,
                readOnly: hasItems,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  // 如果是明细汇总的金额，颜色高亮
                  color: hasItems ? primaryColor : null,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: '0',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.enterAmount;
                  if (double.tryParse(v.trim()) == null) return l10n.invalidAmount;
                  if (double.parse(v.trim()) <= 0) return l10n.amountGreaterThanZero;
                  return null;
                },
              ),
            ),
          ],
        ),
          if (hasItems)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Icon(Icons.auto_awesome, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  l10n.calculatedFromTotal,
                  style: TextStyle(fontSize: 12, color: primaryColor),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 18), // 占位保持布局稳定
      ],
    );
  }

  // 构建类 iOS / 设置项风格的信息表单卡片
  Widget _buildBasicDetailsCard(AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children:[
          // 类别
          _buildFormRow(
            icon: Icons.category_outlined,
            label: l10n.category,
            child: DropdownButtonFormField<String>(
              value: _category.isEmpty ? null : _category,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              hint: Text(l10n.defaultCategory),
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
              items: kCategoryEmoji.keys
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${kCategoryEmoji[c] ?? ''} $c')))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
          ),
          const Divider(height: 1, indent: 48),

          // 日期
          _buildFormRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.date,
            child: InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children:[
                    Expanded(
                      child: Text(
                        _dateCtrl.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 48),

          // 商家
          _buildFormRow(
            icon: Icons.store_outlined,
            label: l10n.merchant,
            child: TextFormField(
              controller: _merchantCtrl,
              decoration: InputDecoration(
                hintText: l10n.notEntered,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1, indent: 48),

          // 备注
          _buildFormRow(
            icon: Icons.notes_outlined,
            label: l10n.note,
            child: TextFormField(
              controller: _descCtrl,
              maxLines: null, // 支持多行
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.additionalInfo,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法：构建卡片内的一行
  Widget _buildFormRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children:[
          Icon(icon, size: 22, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 明细区块 (优化版：卡片化 + 增大点击区域)
// ---------------------------------------------------------------------------

class _ItemsSection extends StatelessWidget {
  final AppLocalizations l10n;
  final List<_EditableBillItem> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  const _ItemsSection({
    required this.l10n,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            Text(
              '${l10n.bills} (${items.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                children:[
                  Icon(Icons.receipt_long_outlined,
                      size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(l10n.addDetail,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )
        else ...[
          // 使用卡片包裹整个列表，去除原本每行一个的 Card
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (ctx, index) {
                final item = items[index];
                final l10n = AppLocalizations.of(ctx)!;
                final typeLabel = _typeLabel(item.itemType, l10n);
                final typeColor = _typeColor(item.itemType, ctx);
                final amount = double.tryParse(item.amountCtrl.text) ?? 0;
                final qty = double.tryParse(item.qtyCtrl.text) ?? 1;

                return InkWell(
                  onTap: () => onEdit(index), // 整个区域可点击编辑
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children:[
                        // 类型角标
                        Container(
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
                        const SizedBox(width: 12),
                        // 名称与数量
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Text(
                                item.nameCtrl.text.isNotEmpty
                                    ? item.nameCtrl.text
                                    : l10n.notEnteredYet,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                              if (qty != 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                      '×${qty.toStringAsFixed(qty == qty.truncate() ? 0 : 1)}',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey[600])),
                                ),
                            ],
                          ),
                        ),
                        // 金额与删除按钮
                        Text(
                          '¥${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: item.itemType == 'discount'
                                ? Colors.red
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 优化点：放大 IconButton 点击区域
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          icon: Icon(Icons.remove_circle_outline,
                              color: Colors.red[300]),
                          onPressed: () => onRemove(index),
                          tooltip: l10n.delete,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 优化点：添加明细通栏按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addDetail),
            ),
          ),
          const SizedBox(height: 80), // 为底部 FAB / 滚动预留空间
        ],
      ],
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'discount': return l10n.discount;
      case 'tax':      return l10n.tax;
      default:         return l10n.product;
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
// 可编辑明细数据类 (未修改)
// ---------------------------------------------------------------------------

class _EditableBillItem {
  final String key;
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
// 图片选择组件 (微调样式融合卡片感)
// ---------------------------------------------------------------------------

class _ReceiptPicker extends StatelessWidget {
  final AppLocalizations l10n;
  final File? pendingFile;
  final String receiptUrl;
  final bool uploading;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  const _ReceiptPicker({
    required this.l10n,
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
      children:[
        Text(
          l10n.scanReceipt,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_hasImage)
          Stack(
            children:[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: pendingFile != null
                    ? Image.file(pendingFile!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover)
                    : Image.network(receiptUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover),
              ),
              if (uploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.black54, iconSize: 20),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onRemove,
                ),
              ),
            ],
          )
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                _PickButton(
                    icon: Icons.camera_alt_outlined,
                    label: l10n.camera,
                    onTap: onPickCamera),
                const SizedBox(width: 48),
                _PickButton(
                    icon: Icons.photo_library_outlined,
                    label: l10n.gallery,
                    onTap: onPickGallery),
              ],
            ),
          ),
        if (_hasImage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:[
                TextButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(l10n.retake),
                ),
                TextButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(l10n.chooseAgain),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}