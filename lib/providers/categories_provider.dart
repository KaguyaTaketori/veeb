import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transactions_api.dart';
import '../models/transaction.dart';
import 'group_provider.dart';
 
final categoriesProvider =
    FutureProvider.family<List<Category>, int?>((ref, groupId) async {
  final api = ref.watch(categoriesApiProvider);
  return api.listCategories(groupId: groupId);
});
 
/// 当前 group 的分类，在多处用到
final currentCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final groupId = ref.watch(currentGroupIdProvider);
  final api     = ref.watch(categoriesApiProvider);
  return api.listCategories(groupId: groupId);
});