// lib/screens/transactions/add_edit_transaction_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/transactions_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final types = [
      ('expense',  l10n.expense, Colors.red),
      ('income',   l10n.income, Colors.green),
      ('transfer', l10n.transfer, Colors.blue),
    ];
    return Row(
      children: types.map((t) {
        final selected = _type == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _type = t.$1;
              _categoryId = null;
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
    final l10n = AppLocalizations.of(context)!;
    final filtered = categories
        .where((c) => c.type == _type || c.type == 'both')
        .toList();
    final selected = filtered.firstWhere(
      (c) => c.id == _categoryId,
      orElse: () => filtered.isEmpty
          ? Category(id: -1, name: l10n.pleaseSelect, icon: '❓',
                     color: '#95A5A6', type: 'both',
                     isSystem: false, sortOrder: 0)
          : filtered.first,
    );

    return InkWell(
      onTap: () => _showCategorySheet(filtered),
      child: _FormRow(
        icon: Icons.category_outlined,
        label: l10n.category,
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
    final l10n = AppLocalizations.of(context)!;
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
        validator: (_) => value == null ? l10n.required : null,
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
      return await ref.read(transactionsProvider.notifier).uploadReceipt(
            fileBytes: bytes, filename: filename, mimeType: mime);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.operationFailed(e.toString()));
      return null;
    } finally {
      setState(() => _uploadingImg = false);
    }
  }

  // ── 保存 ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = l10n.required);
      return;
    }
    if (_type == 'transfer' && _toAccountId == null) {
      setState(() => _error = l10n.required);
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final receiptUrl = await _uploadPendingImage();
      if (_pendingImage != null && receiptUrl == null) return;

      final groupId = ref.read(currentGroupIdProvider)!;
      final amount  = double.parse(_amountCtrl.text.trim());
      final txnDate = _txnDate.millisecondsSinceEpoch / 1000.0;
      final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

      final notifier = ref.read(transactionsProvider.notifier);

      if (_isEdit) {
        await notifier.updateTransaction(
          id: widget.transaction!.id,
          type: _type,
          amount: amount,
          currencyCode: _currencyCode,
          accountId: _accountId,
          toAccountId: _toAccountId,
          categoryId: _categoryId,
          isPrivate: _isPrivate,
          note: note,
          transactionDate: txnDate,
          receiptUrl: receiptUrl,
        );
      } else {
        await notifier.createTransaction(
          type: _type,
          amount: amount,
          currencyCode: _currencyCode,
          accountId: _accountId!,
          toAccountId: _toAccountId,
          categoryId: _categoryId!,
          groupId: groupId,
          isPrivate: _isPrivate,
          note: note,
          transactionDate: txnDate,
          receiptUrl: receiptUrl,
        );
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

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isEdit ? l10n.edit : l10n.addTransaction),
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
                  onPressed: _save, child: Text(l10n.save)),
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
                        loading: () => ListTile(
                            title: Text(l10n.categoryLoading)),
                        error: (e, _) =>
                            ListTile(title: Text(l10n.categoryLoadError(e.toString()))),
                      ),
                      const Divider(height: 1, indent: 48),

                      // 账户
                      _buildAccountDropdown(accounts, _accountId, l10n.account,
                          (v) => setState(() => _accountId = v)),

                      // 转账目标账户
                      if (_type == 'transfer') ...[
                        const Divider(height: 1, indent: 48),
                        _buildAccountDropdown(accounts, _toAccountId,
                            l10n.to,
                            (v) => setState(() => _toAccountId = v)),
                      ],

                      const Divider(height: 1, indent: 48),

                      // 日期
                      InkWell(
                        onTap: _pickDate,
                        child: _FormRow(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.date,
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
                        label: l10n.note,
                        child: TextFormField(
                          controller: _noteCtrl,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: l10n.note,
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
                        title: Text(l10n.private),
                        subtitle: Text(
                          l10n.shareTransactions,
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
              final l10n = AppLocalizations.of(context)!;
              if (v == null || v.trim().isEmpty) return l10n.required;
              if (double.tryParse(v.trim()) == null) return l10n.error;
              if (double.parse(v.trim()) <= 0) return l10n.error;
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
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
          Text(l10n.category,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  }

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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.scanReceipt,
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
                      label: l10n.camera,
                      onTap: onPickCamera),
                  const SizedBox(width: 48),
                  _PickBtn(
                      icon: Icons.photo_library_outlined,
                      label: l10n.gallery,
                      onTap: onPickGallery),
                ],
              ),
            ),
        ],
      );
  }
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
