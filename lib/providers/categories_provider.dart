import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transactions_api.dart';
import '../models/transaction.dart';
import 'group_provider.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
 
final categoriesProvider =
    FutureProvider.family<List<Category>, int?>((ref, groupId) async {
  final isLoggedIn =
      ref.watch(authProvider).status == AuthStatus.authenticated;
  
  if (isLoggedIn) {
    return ref.watch(categoriesApiProvider).listCategories(groupId: groupId);
  } else {
    final db = ref.watch(appDatabaseProvider);
    final rows = await db.categoryDao.getAvailable(groupId);
    return rows.map((r) => Category(
      id: r.id,
      name: r.name,
      icon: r.icon ?? '📦',
      color: r.color ?? '#95A5A6',
      type: r.type,
      isSystem: r.isSystem,
      groupId: r.groupId,
      sortOrder: r.sortOrder,
    )).toList();
  }
});

final currentCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final groupId = ref.watch(currentGroupIdProvider);
  return ref.watch(categoriesProvider(groupId).future);
});