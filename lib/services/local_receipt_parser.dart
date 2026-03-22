class LocalReceiptParser {
  static Map<String, dynamic> parse(String rawText) {
    return {
      'amount': _extractAmount(rawText),
      'currency': _extractCurrency(rawText),
      'payee': _extractPayee(rawText),
      'bill_date': _extractDate(rawText),
      'category': _guessCategory(rawText),
      'description': '',
      'items': _extractItems(rawText),
    };
  }

  // ── 金额：优先取合計行 ─────────────────────────────────────────────

  static double _extractAmount(String text) {
    final totalPatterns = [
      RegExp(r'合[計计]\s*[¥￥]?\s*([\d,，]+)', caseSensitive: false),
      RegExp(r'Grand\s*Total\s*[¥￥\$]?\s*([\d,\.]+)', caseSensitive: false),
      RegExp(r'Total\s*Amount\s*[¥￥\$]?\s*([\d,\.]+)', caseSensitive: false),
      RegExp(r'お会計\s*[¥￥]?\s*([\d,]+)'),
    ];

    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '').replaceAll('，', '');
        final val = double.tryParse(raw);
        if (val != null && val > 0) return val;
      }
    }

    final allAmounts = _extractAllAmounts(text);
    if (allAmounts.isNotEmpty) {
      allAmounts.sort((a, b) => b.compareTo(a));
      return allAmounts.first;
    }
    return 0.0;
  }

  static List<double> _extractAllAmounts(String text) {
    final pattern = RegExp(r'[¥￥\$]?\s*([\d,]{2,}(?:\.\d{1,2})?)');
    return pattern
        .allMatches(text)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0.0)
        .where((v) => v > 0)
        .toList();
  }

  // ── 货币 ──────────────────────────────────────────────────────────

  static String _extractCurrency(String text) {
    if (text.contains('¥') ||
        text.contains('￥') ||
        text.contains('円') ||
        text.contains('JPY'))
      return 'JPY';
    if (text.contains('元') || text.contains('CNY') || text.contains('RMB'))
      return 'CNY';
    if (text.contains('\$') || text.contains('USD')) return 'USD';
    if (text.contains('€') || text.contains('EUR')) return 'EUR';
    return 'JPY';
  }

  // ── 收款方：取第一行非空文字 ───────────────────────────────────────
  //
  // 对应个人记账场景：扫描的对象基本是 expense，
  // 小票第一行通常是店名，即 payee（收款方）。

  static String _extractPayee(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 1)
        .toList();

    for (final line in lines.take(5)) {
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      if (RegExp(r'\d{4}[-/年]\d{1,2}').hasMatch(line)) continue;
      if (RegExp(r'^[¥￥\$\d,\.]+$').hasMatch(line)) continue;
      return line;
    }
    return '';
  }

  // ── 日期 ──────────────────────────────────────────────────────────

  static String _extractDate(String text) {
    final patterns = [
      RegExp(r'(\d{4})[年\-/](\d{1,2})[月\-/](\d{1,2})'),
      RegExp(r'(\d{2})[年\-/](\d{1,2})[月\-/](\d{1,2})'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        var year = int.parse(m.group(1)!);
        if (year < 100) year += 2000;
        final month = int.parse(m.group(2)!);
        final day = int.parse(m.group(3)!);
        return '${year.toString().padLeft(4, '0')}'
            '-${month.toString().padLeft(2, '0')}'
            '-${day.toString().padLeft(2, '0')}';
      }
    }
    return DateTime.now().toIso8601String().substring(0, 10);
  }

  // ── 类别猜测 ──────────────────────────────────────────────────────

  static String _guessCategory(String text) {
    final lower = text.toLowerCase();
    final rules = {
      '餐饮': [
        'レストラン',
        '食堂',
        '定食',
        'cafe',
        'coffee',
        'restaurant',
        'ラーメン',
        '寿司',
        '焼肉',
        '居酒屋',
      ],
      '交通': ['バス', 'タクシー', '電車', 'suica', 'pasmo', 'taxi', 'metro', '地铁', '公交'],
      '购物': ['スーパー', 'コンビニ', 'ドラッグ', 'mall', 'shopping', '超市', '便利店'],
      '医疗': ['薬局', '病院', 'クリニック', 'pharmacy', 'hospital', '药店', '医院'],
      '娱乐': ['映画', 'cinema', 'game', 'netflix', '游戏'],
    };

    for (final entry in rules.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw.toLowerCase())) return entry.key;
      }
    }
    return '其他';
  }

  // ── 明细：尝试解析品名+金额的行 ──────────────────────────────────

  static List<Map<String, dynamic>> _extractItems(String text) {
    final items = <Map<String, dynamic>>[];
    final pattern = RegExp(
      r'^(.{2,20})\s+[¥￥]?\s*(\d[\d,]{1,6})$',
      multiLine: true,
    );

    int order = 0;
    for (final m in pattern.allMatches(text)) {
      final name = m.group(1)!.trim();
      final amount = double.tryParse(m.group(2)!.replaceAll(',', '')) ?? 0.0;

      if (RegExp(r'合[計计]|Total|小計').hasMatch(name)) continue;
      if (amount <= 0) continue;

      items.add({
        'name': name,
        'name_raw': name,
        'quantity': 1.0,
        'unit_price': null,
        'amount': amount,
        'item_type': 'item',
        'sort_order': order++,
      });
    }
    return items;
  }
}
