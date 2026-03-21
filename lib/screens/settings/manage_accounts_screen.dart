// lib/screens/settings/manage_accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/group_provider.dart';

class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n    = AppLocalizations.of(context)!;
    final state   = ref.watch(accountsProvider);
    final groupId = ref.watch(currentGroupIdProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.manageAccounts),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.accounts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final a = state.accounts[i];
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: Text(a.typeIcon,
                  style: const TextStyle(fontSize: 24)),
              title: Text(a.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${a.typeLabel} · ${a.currencyCode}'),
              trailing: Text(
                a.formattedBalance,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showAddSheet(context, ref, groupId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(
      BuildContext context, WidgetRef ref, int? groupId) {
    if (groupId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddAccountSheet(groupId: groupId),
    );
  }
}

class _AddAccountSheet extends ConsumerStatefulWidget {
  final int groupId;
  const _AddAccountSheet({required this.groupId});

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  String _type     = 'cash';
  String _currency = 'JPY';
  bool   _saving   = false;
  String? _error;

  static const _types = [
    ('cash',        '💵', '现金'),
    ('bank',        '🏦', '银行卡'),
    ('credit_card', '💳', '信用卡'),
  ];

  static const _currencies = ['JPY', 'CNY', 'USD', 'EUR', 'HKD'];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = '请输入账户名称');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(accountsProvider.notifier).createAccount(
        name:         _nameCtrl.text.trim(),
        type:         _type,
        currencyCode: _currency,
        groupId:      widget.groupId,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('添加账户',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          if (_error != null) ...[
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
            const SizedBox(height: 12),
          ],

          // 账户名
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: '账户名称',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // 类型
          const Text('账户类型',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: _types.map((t) {
              final selected = _type == t.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t.$1),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(children: [
                      Text(t.$2,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(t.$3,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                  : Colors.grey[700])),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 货币
          const Text('货币',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _currencies.map((c) {
              final selected = _currency == c;
              return GestureDetector(
                onTap: () => setState(() => _currency = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(c,
                      style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('添加',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}