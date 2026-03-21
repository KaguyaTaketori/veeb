// lib/screens/transactions/add_edit_transaction_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/transactions_api.dart';
import '../../models/transaction.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../utils/currency.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;     // null = 新建
  final DateTime     selectedMonth;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    required this.selectedMonth,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _amountCtrl  = TextEditingController();
  final _noteCtrl    = TextEditingController();
  final _picker      = ImagePicker();

  String  _type          = 'expense';
  String  _currencyCode  = 'JPY';
  int?    _accountId;
  int?    _toAccountId;
  int?    _categoryId;
  DateTime _txnDate      = DateTime.now();
  bool    _isPrivate     = false;
  String  _receiptUrl    = '';
  File?   _pendingImage;
  bool    _uploadingImg  = false;
  bool    _saving        = false;
  String? _error;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _type         = t.type;
      _currencyCode = t.currencyCode;
      _accountId    = t.accountId;
      _toAccountId  = t.toAccountId;
      _categoryId   = t.categoryId;
      _txnDate      = t.date;
      _isPrivate    = t.isPrivate;
      _receiptUrl   = t.receiptUrl;
      _amountCtrl.text = t.amount.toStringAsFixed(0);
      _noteCtrl.text   = t.note ?? '';
    } else {
      _txnDate = DateTime(
          widget.selectedMonth.year, widget.selectedMonth.month,
          DateTime.now().day);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── 类型 Tab ───────────────────────────────────────────────────────────────

  Widget _buildTypeSelector() {
    const types = [
      ('expense',  '支出', Colors.red),
      ('income',   '收入', Colors.green),
      ('transfer', '转账', Colors.blue),
    ];
    return Row(
      children: types.map((t) {
        final selected = _type == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _type = t.$1;
              _categoryId = null; // 切换类型清空分类
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? t.$3.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? t.$3 : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(t.$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? t.$3 : Colors.grey[600],
                  )),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 分类选择 ──────────────────────────────────────────────────────────────

  Widget _buildCategoryPicker(List<Category> categories) {
    final filtered = categories
        .where((c) => c.type == _type || c.type == 'both')
        .toList();
    final selected = filtered.firstWhere(
      (c) => c.id == _categoryId,
      orElse: () => filtered.isEmpty
          ? Category(id: -1, name: '未選択', icon: '❓',
                     color: '#95A5A6', type: 'both',
                     isSystem: false, sortOrder: 0)
          : filtered.first,
    );

    return InkWell(
      onTap: () => _showCategorySheet(filtered),
      child: _FormRow(
        icon: Icons.category_outlined,
        label: 'カテゴリ',
        child: Row(
          children: [
            Text(selected.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(selected.name,
                  style: const TextStyle(fontSize: 15)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategorySheet(
        categories: categories,
        selectedId: _categoryId,
        onSelected: (id) {
          setState(() => _categoryId = id);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── 账户选择 ──────────────────────────────────────────────────────────────

  Widget _buildAccountDropdown(
      List<dynamic> accounts, int? value, String label,
      ValueChanged<int?> onChanged) {
    return _FormRow(
      icon: Icons.account_balance_wallet_outlined,
      label: label,
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: const InputDecoration(
            border: InputBorder.none, contentPadding: EdgeInsets.zero,
            isDense: true),
        icon: const Icon(Icons.chevron_right, color: Colors.grey),
        items: accounts
            .map((a) => DropdownMenuItem<int>(
                  value: a.id as int,
                  child: Text('${a.typeIcon} ${a.name}'),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (_) => value == null ? '口座を選択してください' : null,
      ),
    );
  }

  // ── 图片 ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1920);
    if (xfile == null) return;
    setState(() {
      _pendingImage = File(xfile.path);
      _receiptUrl   = '';
    });
  }

  Future<String?> _uploadPendingImage() async {
    if (_pendingImage == null) return _receiptUrl;
    setState(() => _uploadingImg = true);
    try {
      final bytes    = await _pendingImage!.readAsBytes();
      final filename = _pendingImage!.path.split('/').last;
      final mime = filename.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      return await ref.read(transactionsApiProvider).uploadReceipt(
            fileBytes: bytes, filename: filename, mimeType: mime);
    } catch (e) {
      setState(() => _error = '画像アップロード失敗: $e');
      return null;
    } finally {
      setState(() => _uploadingImg = false);
    }
  }

  // ── 保存 ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = 'カテゴリを選択してください');
      return;
    }
    if (_type == 'transfer' && _toAccountId == null) {
      setState(() => _error = '振替先口座を選択してください');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final receiptUrl = await _uploadPendingImage();
      if (_pendingImage != null && receiptUrl == null) return;

      final groupId = ref.read(currentGroupIdProvider)!;
      final amount  = double.parse(_amountCtrl.text.trim());
      final txnDate = _txnDate.millisecondsSinceEpoch / 1000.0;

      final api = ref.read(transactionsApiProvider);

      if (_isEdit) {
        await api.patchTransaction(widget.transaction!.id, {
          'type':             _type,
          'amount':           amount,
          'currency_code':    _currencyCode,
          'account_id':       _accountId,
          if (_toAccountId != null) 'to_account_id': _toAccountId,
          'category_id':      _categoryId,
          'is_private':       _isPrivate,
          'note':             _noteCtrl.text.trim().isEmpty
              ? null
              : _noteCtrl.text.trim(),
          'transaction_date': txnDate,
          if (receiptUrl != null && receiptUrl.isNotEmpty)
            'receipt_url': receiptUrl,
        });
      } else {
        await api.createTransaction({
          'type':             _type,
          'amount':           amount,
          'currency_code':    _currencyCode,
          'exchange_rate':    1.0,
          'account_id':       _accountId,
          if (_toAccountId != null) 'to_account_id': _toAccountId,
          'category_id':      _categoryId,
          'group_id':         groupId,
          'is_private':       _isPrivate,
          'note':             _noteCtrl.text.trim().isEmpty
              ? null
              : _noteCtrl.text.trim(),
          'transaction_date': txnDate,
          'receipt_url':      receiptUrl ?? '',
          'items':            [],
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);
    final accounts      = accountsState.accounts;
    final categoriesAsync = ref.watch(currentCategoriesProvider);
    final groupId       = ref.watch(currentGroupIdProvider);

    // 初始化默认账户
    if (_accountId == null && accounts.isNotEmpty) {
      Future.microtask(
          () => setState(() => _accountId = accounts.first.id));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isEdit ? '編集' : '新規記録'),
        centerTitle: true,
        actions: [
          if (_saving || _uploadingImg)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                  onPressed: _save, child: const Text('保存')),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!,
                        style: TextStyle(color: Colors.red.shade700)),
                  ),

                // 类型选择
                _buildTypeSelector(),
                const SizedBox(height: 20),

                // 金额（大字）
                _buildAmountHeader(),
                const SizedBox(height: 20),

                // 基本信息卡片
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // 分类
                      categoriesAsync.when(
                        data: (cats) => _buildCategoryPicker(cats),
                        loading: () => const ListTile(
                            title: Text('カテゴリ読み込み中...')),
                        error: (e, _) =>
                            ListTile(title: Text('エラー: $e')),
                      ),
                      const Divider(height: 1, indent: 48),

                      // 账户
                      _buildAccountDropdown(accounts, _accountId, '口座',
                          (v) => setState(() => _accountId = v)),

                      // 转账目标账户
                      if (_type == 'transfer') ...[
                        const Divider(height: 1, indent: 48),
                        _buildAccountDropdown(accounts, _toAccountId,
                            '振替先',
                            (v) => setState(() => _toAccountId = v)),
                      ],

                      const Divider(height: 1, indent: 48),

                      // 日期
                      InkWell(
                        onTap: _pickDate,
                        child: _FormRow(
                          icon: Icons.calendar_today_outlined,
                          label: '日付',
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_txnDate.year}/${_txnDate.month.toString().padLeft(2, '0')}/${_txnDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 48),

                      // 备注
                      _FormRow(
                        icon: Icons.notes_outlined,
                        label: '備考',
                        child: TextFormField(
                          controller: _noteCtrl,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'メモ...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 48),

                      // 是否私密
                      SwitchListTile(
                        secondary: Icon(Icons.lock_outline,
                            color: Colors.grey[500]),
                        title: const Text('プライベート'),
                        subtitle: Text(
                          'グループメンバーに非表示',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                        value: _isPrivate,
                        onChanged: (v) => setState(() => _isPrivate = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 凭证图片
                _ReceiptSection(
                  pendingFile:   _pendingImage,
                  receiptUrl:    _receiptUrl,
                  uploading:     _uploadingImg,
                  onPickCamera:  () => _pickImage(ImageSource.camera),
                  onPickGallery: () => _pickImage(ImageSource.gallery),
                  onRemove: () => setState(() {
                    _pendingImage = null;
                    _receiptUrl   = '';
                  }),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 货币选择
        DropdownButton<String>(
          value: _currencyCode,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: ['JPY', 'CNY', 'USD', 'EUR', 'HKD']
              .map((c) =>
                  DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _currencyCode = v!),
        ),
        const SizedBox(width: 8),
        IntrinsicWidth(
          child: TextFormField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 48, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintText: '0',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '金額を入力';
              if (double.tryParse(v.trim()) == null) return '無効';
              if (double.parse(v.trim()) <= 0) return '0より大きく';
              return null;
            },
          ),
        ),
      ],
    );
  }
}


// ── 辅助 Widget ───────────────────────────────────────────────────────────────

class _FormRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Widget   child;

  const _FormRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[500]),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 14)),
            ),
            Expanded(child: child),
          ],
        ),
      );
}


class _CategorySheet extends StatelessWidget {
  final List<Category> categories;
  final int?           selectedId;
  final ValueChanged<int> onSelected;

  const _CategorySheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('カテゴリを選択',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat      = categories[i];
                final selected = cat.id == selectedId;
                final color = _parseColor(cat.color);
                return GestureDetector(
                  onTap: () => onSelected(cat.id),
                  child: Column(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.2)
                              : color.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: color, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(cat.icon,
                            style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected ? color : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      );

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}


class _ReceiptSection extends StatelessWidget {
  final File?   pendingFile;
  final String  receiptUrl;
  final bool    uploading;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  const _ReceiptSection({
    required this.pendingFile,
    required this.receiptUrl,
    required this.uploading,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  bool get _hasImage => pendingFile != null || receiptUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('レシート',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_hasImage)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8, right: 8,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        iconSize: 20),
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
                border: Border.all(
                    color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PickBtn(
                      icon: Icons.camera_alt_outlined,
                      label: 'カメラ',
                      onTap: onPickCamera),
                  const SizedBox(width: 48),
                  _PickBtn(
                      icon: Icons.photo_library_outlined,
                      label: 'アルバム',
                      onTap: onPickGallery),
                ],
              ),
            ),
        ],
      );
}

class _PickBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _PickBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[700])),
            ],
          ),
        ),
      );
}
