import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Map<String, String> kCategoryEmoji = {
  '餐饮': '🍜',
  '交通': '🚇',
  '购物': '🛍️',
  '娱乐': '🎮',
  '医疗': '💊',
  '住房': '🏠',
  '水电煤': '💡',
  '食品': '🛒',
  '加油': '⛽',
  '其他': '📦',
};


const List<Color> kCategoryColors = [
  Color(0xFFE85D30),
  Color(0xFF3B8BD4),
  Color(0xFF1D9E75),
  Color(0xFFEF9F27),
  Color(0xFF9B59B6),
  Color(0xFFE74C3C),
  Color(0xFF2ECC71),
  Color(0xFF1ABC9C),
];

final kAmountFormat = NumberFormat('#,###');