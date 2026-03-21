// lib/screens/settings/manage_accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_card.dart';
import '../../widgets/ui_core/vee_empty_state.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_amount_display.dart';

class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(accountsProvider);
    final groupId = ref.watch(currentGroupIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accounts),
        centerTitle: true,
      ),
      body: state.accounts.isEmpty && !state.loading
          ? VeeEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: '暂无账户',
              subtitle: '点击右下角按钮添加账户',
            )
          : ListView.separated(
              padding: VeeTokens.cardPadding,
              itemCount: state.accounts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: VeeTokens.spacingXs),
              itemBuilder: (_, i) {
                final a = state.accounts[i];
                return VeeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: VeeTokens.tilePadding,
                    leading: Text(a.typeIcon,
                        style: TextStyle(fontSize: VeeTokens.iconLg)),
                    title: Text(a.name,
                        style: context.veeText.cardTitle),
                    subtitle: Text(
                      '${a.typeLabel} · ${a.currencyCode}',
                      style: context.veeText.caption.copyWith(
                        color: VeeTokens.textSecondaryVal,
                      ),
                    ),
                    trailing: VeeAmountDisplay(
                      amount: a.balanceFloat,
                      currency: a.currencyCode,
                      size: VeeAmountSize.small,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VeeTokens.rLg)),
        onPressed: () => _showAddSheet(context, ref, groupId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, int? groupId) {
    if (groupId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(VeeTokens.rXl))),
      builder: (_) => _AddAccountSheet(groupId: groupId),
    );
  }
}

// ── 添加账户表单 ──────────────────────────────────────────────────────────────

class _AddAccountSheet extends ConsumerStatefulWidget {
  final int groupId;
  const _AddAccountSheet({required this.groupId});

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  String _type = 'cash';
  String _currency = 'JPY';
  bool _saving = false;
  String? _error;

  static const _types = [
    ('cash', '💵', '现金'),
    ('bank', '🏦', '银行卡'),
    ('credit_card', '💳', '信用卡'),
  ];

  static const _currencies = ['JPY', 'CNY', 'USD', 'EUR', 'HKD'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = '请输入账户名称');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(accountsProvider.notifier).createAccount(
            name: _nameCtrl.text.trim(),
            type: _type,
            currencyCode: _currency,
            groupId: widget.groupId,
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
      padding: VeeTokens.sheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('添加账户', style: context.veeText.sectionTitle),
          const SizedBox(height: VeeTokens.spacingLg),

          if (_error != null) VeeErrorBanner(message: _error!),

          // 账户名
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '账户名称'),
          ),
          const SizedBox(height: VeeTokens.spacingMd),

          // 账户类型
          Text('账户类型',
              style: context.veeText.caption.copyWith(color: Colors.grey)),
          const SizedBox(height: VeeTokens.spacingXs),
          Row(
            children: _types.map((t) {
              final selected = _type == t.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t.$1),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: VeeTokens.spacingXxs),
                    padding: const EdgeInsets.symmetric(
                        vertical: VeeTokens.s12),
                    decoration: BoxDecoration(
                      color: selected
                          ? VeeTokens.selectedTint(
                              Theme.of(context).colorScheme.primary)
                          : Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(VeeTokens.rMd),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(children: [
                      Text(t.$2,
                          style:
                              TextStyle(fontSize: VeeTokens.iconMd + 2)),
                      const SizedBox(height: VeeTokens.spacingXxs),
                      Text(t.$3,
                          style: context.veeText.micro.copyWith(
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[700],
                          )),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: VeeTokens.spacingMd),

          // 货币
          Text('货币',
              style: context.veeText.caption.copyWith(color: Colors.grey)),
          const SizedBox(height: VeeTokens.spacingXs),
          Wrap(
            spacing: VeeTokens.spacingXs,
            children: _currencies.map((c) {
              final selected = _currency == c;
              return GestureDetector(
                onTap: () => setState(() => _currency = c),
                child: Container(
                  padding: VeeTokens.chipPadding,
                  decoration: BoxDecoration(
                    color: selected
                        ? VeeTokens.selectedTint(
                            Theme.of(context).colorScheme.primary)
                        : Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(VeeTokens.rFull),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(c,
                      style: context.veeText.chipLabel.copyWith(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[700],
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: VeeTokens.spacingLg),

          SizedBox(
            height: VeeTokens.buttonHeight,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: VeeTokens.iconMd,
                      height: VeeTokens.iconMd,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('添加'),
            ),
          ),
        ],
      ),
    );
  }
}