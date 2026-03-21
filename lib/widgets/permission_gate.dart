// lib/widgets/permission_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/permission_provider.dart';

/// 权限门卫组件 — 根据权限显示/隐藏子组件
///
/// 用法：
///   PermissionGate(
///     perm: 'app_ocr',
///     child: FilledButton(...),          // 有权限时显示
///     fallback: _NoPermissionHint(),     // 可选：无权限时的替代 UI
///   )
class PermissionGate extends ConsumerWidget {
  final String  perm;
  final Widget  child;
  final Widget? fallback;   // null = 直接隐藏（SizedBox.shrink）
  final bool    grayOut;    // true = 显示但置灰，false = 完全隐藏

  const PermissionGate({
    super.key,
    required this.perm,
    required this.child,
    this.fallback,
    this.grayOut = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(hasPermissionProvider(perm));

    if (allowed) return child;

    if (grayOut) {
      return Opacity(
        opacity: 0.35,
        child: IgnorePointer(child: child),
      );
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// 无权限时的统一提示组件（可选展示）
class NoPermissionHint extends StatelessWidget {
  final String? message;
  const NoPermissionHint({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(message ?? l10n.noPermission,
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }
}


// ============================================================
// lib/screens/ocr/ocr_screen.dart — 权限门卫改造示例
// ============================================================
// 将整个 OcrScreen 的 body 用 PermissionGate 包裹：
//
//   body: PermissionGate(
//     perm: 'app_ocr',
//     fallback: const _NoOcrPermission(),
//     child: Center(...原有内容...),
//   ),
//
// 并添加一个无权限占位页面：

class NoOcrPermissionPlaceholder extends StatelessWidget {
  const NoOcrPermissionPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              l10n.noAiPermission,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.contactAdminForOcr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// lib/screens/add_edit_bill/add_edit_bill_screen.dart — 上传权限控制
// ============================================================
// 将凭证图片上传区块用 PermissionGate 包裹：
//
//   PermissionGate(
//     perm: 'app_upload',
//     fallback: Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: NoPermissionHint(message: '暂无上传凭证图片的权限'),
//     ),
//     child: _ReceiptPicker(...),
//   ),
//
// ============================================================


// ============================================================
// lib/main.dart — NavigationBar 按权限隐藏 Tab 示例
// ============================================================
// 若要对普通用户隐藏 Admin Tab，在 HomeScreen 中：
//
//   final isAdmin = ref.watch(isAdminProvider);
//
//   // destinations 列表动态生成：
//   final destinations = [
//     const NavigationDestination(icon: ..., label: '流水'),
//     const NavigationDestination(icon: ..., label: '记录'),
//     const NavigationDestination(icon: ..., label: '统计'),
//     const NavigationDestination(icon: ..., label: '我的'),
//     if (isAdmin)
//       const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: '管理'),
//   ];
//
//   // _screens 列表同步：
//   final screens = [
//     const BillsListScreen(),
//     const OcrScreen(),
//     const StatsScreen(),
//     const ProfileScreen(),
//     if (isAdmin) const AdminDashboardScreen(),
//   ];
//
// ============================================================