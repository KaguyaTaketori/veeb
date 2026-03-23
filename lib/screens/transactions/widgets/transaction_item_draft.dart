class TransactionItemDraft {
  String name;
  double amount;
  double quantity;
  String itemType; // 'item' | 'discount'

  TransactionItemDraft({
    this.name = '',
    this.amount = 0,
    this.quantity = 1,
    this.itemType = 'item',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'name_raw': name,
    'quantity': quantity,
    'amount': amount,
    'item_type': itemType,
    'sort_order': 0,
  };
}
