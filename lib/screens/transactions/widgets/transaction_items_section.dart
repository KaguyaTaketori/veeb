//   )

import 'package:flutter/material.dart';
import '../../../widgets/ui_core/vee_tokens.dart';
import '../../../widgets/ui_core/vee_text_styles.dart';
import '../../../widgets/ui_core/vee_card.dart';
import 'transaction_item_draft.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionItemsSection
// ─────────────────────────────────────────────────────────────────────────────

class TransactionItemsSection extends StatelessWidget {
  /// 明细草稿列表（由父级 setState 管理）
  final List<TransactionItemDraft> items;

  final String currency;

  /// 任意变更（增删改）后的回调，父级调用 setState
  final VoidCallback onChanged;

  const TransactionItemsSection({
    super.key,
    required this.items,
    required this.currency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 标题行 ────────────────────────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: VeeTokens.iconSm,
              color: VeeTokens.textSecondaryVal,
            ),
            const SizedBox(width: VeeTokens.spacingXxs),
            Text('商品明细', style: context.veeText.sectionTitle),
            const Spacer(),
            if (items.isNotEmpty)
              Text(
                '${items.length} 项',
                style: context.veeText.micro.copyWith(
                  color: VeeTokens.textSecondaryVal,
                ),
              ),
          ],
        ),
        const SizedBox(height: VeeTokens.spacingXs),

        // ── 明细列表 ──────────────────────────────────────────────────
        if (items.isNotEmpty)
          VeeCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: items.asMap().entries.map((entry) {
                final idx = entry.key;
                return Column(
                  children: [
                    if (idx > 0)
                      const Divider(height: 1, indent: VeeTokens.s16),
                    TransactionItemEditRow(
                      item: items[idx],
                      currency: currency,
                      onChanged: onChanged,
                      onDelete: () {
                        items.removeAt(idx);
                        onChanged();
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: VeeTokens.spacingXs),

        // ── 添加按钮行 ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: VeeTokens.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VeeTokens.rMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: VeeTokens.s12),
                ),
                onPressed: () {
                  items.add(TransactionItemDraft());
                  onChanged();
                },
                icon: const Icon(Icons.add, size: VeeTokens.iconSm),
                label: const Text('商品'),
              ),
            ),
            const SizedBox(width: VeeTokens.spacingXs),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: VeeTokens.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VeeTokens.rMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: VeeTokens.s12),
                ),
                onPressed: () {
                  items.add(TransactionItemDraft(itemType: 'discount'));
                  onChanged();
                },
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: VeeTokens.iconSm,
                ),
                label: const Text('折扣'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TransactionItemEditRow — 单行明细编辑
//
// 从 add_edit_transaction_screen.dart 的私有 _ItemEditRow 提取，
// new_transaction_sheet 中的内联写法同步升级为此完整版（补齐 qty 字段）。
// ─────────────────────────────────────────────────────────────────────────────

class TransactionItemEditRow extends StatefulWidget {
  final TransactionItemDraft item;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const TransactionItemEditRow({
    super.key,
    required this.item,
    required this.currency,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<TransactionItemEditRow> createState() => _TransactionItemEditRowState();
}

class _TransactionItemEditRowState extends State<TransactionItemEditRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amtCtrl;
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _amtCtrl = TextEditingController(
      text: widget.item.amount > 0 ? widget.item.amount.toStringAsFixed(0) : '',
    );
    _qtyCtrl = TextEditingController(
      text: widget.item.quantity == 1.0
          ? '1'
          : widget.item.quantity.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDiscount = widget.item.itemType == 'discount';
    final accentColor = isDiscount
        ? VeeTokens.error
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VeeTokens.s12,
        vertical: VeeTokens.s10,
      ),
      child: Row(
        children: [
          // ── 类型切换按钮 ────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() {
                widget.item.itemType = isDiscount ? 'item' : 'discount';
              });
              widget.onChanged();
            },
            child: Container(
              width: VeeTokens.s32,
              height: VeeTokens.s32,
              decoration: BoxDecoration(
                color: VeeTokens.selectedTint(accentColor),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                isDiscount ? '➖' : '•',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: VeeTokens.spacingXs),

          // ── 商品名称 ────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: isDiscount ? '折扣/优惠' : '商品名称',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: context.veeText.caption.copyWith(fontSize: 14),
              onChanged: (v) {
                widget.item.name = v;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: VeeTokens.spacingXxs),

          // ── 数量（折扣行隐藏）─────────────────────────────────────
          if (!isDiscount) ...[
            SizedBox(
              width: 36,
              child: TextField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '×1',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: VeeTokens.textPlaceholderVal,
                  ),
                  prefix: Text(
                    '×',
                    style: TextStyle(
                      fontSize: 11,
                      color: VeeTokens.textSecondaryVal,
                    ),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
                onChanged: (v) {
                  widget.item.quantity = double.tryParse(v) ?? 1.0;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: VeeTokens.spacingXxs),
          ],

          // ── 金额 ────────────────────────────────────────────────────
          SizedBox(
            width: 72,
            child: TextField(
              controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDiscount ? VeeTokens.error : null,
              ),
              textAlign: TextAlign.right,
              onChanged: (v) {
                widget.item.amount = double.tryParse(v) ?? 0;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: VeeTokens.spacingXxs),

          // ── 删除 ────────────────────────────────────────────────────
          GestureDetector(
            onTap: widget.onDelete,
            child: const Icon(
              Icons.close,
              size: VeeTokens.iconSm,
              color: VeeTokens.textPlaceholderVal,
            ),
          ),
        ],
      ),
    );
  }
}
