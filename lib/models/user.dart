// lib/models/user.dart  （完整替换）
import 'dart:convert';

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final int? tgUserId;
  final bool isActive;
  final String role;             // ← 新增
  final List<String> permissions; // ← 新增
  final int aiQuotaMonthly;
  final int aiQuotaUsed;
  final double aiQuotaResetAt;
  final double createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.tgUserId,
    required this.isActive,
    this.role = 'user',
    this.permissions = const [],
    required this.aiQuotaMonthly,
    required this.aiQuotaUsed,
    required this.aiQuotaResetAt,
    required this.createdAt,
  });

  String get name =>
      displayName?.isNotEmpty == true ? displayName! : username;

  int get aiQuotaRemaining => aiQuotaMonthly == -1
      ? -1
      : (aiQuotaMonthly - aiQuotaUsed).clamp(0, aiQuotaMonthly);

  double get aiQuotaPercent => aiQuotaMonthly <= 0
      ? 0
      : (aiQuotaUsed / aiQuotaMonthly).clamp(0.0, 1.0);

  DateTime get quotaResetDate =>
      DateTime.fromMillisecondsSinceEpoch((aiQuotaResetAt * 1000).toInt());

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // permissions 可能是 JSON 字符串（后端存储方式）或已解析的 List
    List<String> parsePermissions(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return List<String>.from(raw);
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) return List<String>.from(decoded);
        } catch (_) {}
      }
      return [];
    }

    return UserProfile(
      id:               json['id'] as int,
      username:         json['username'] as String? ?? '',
      email:            json['email'] as String? ?? '',
      displayName:      json['display_name'] as String?,
      avatarUrl:        json['avatar_url'] as String?,
      tgUserId:         json['tg_user_id'] as int?,
      isActive:         (json['is_active'] as bool?) ?? false,
      role:             json['role'] as String? ?? 'user',           // ← 新增
      permissions:      parsePermissions(json['permissions']),       // ← 新增
      aiQuotaMonthly:   (json['ai_quota_monthly'] as num?)?.toInt() ?? 100,
      aiQuotaUsed:      (json['ai_quota_used'] as num?)?.toInt() ?? 0,
      aiQuotaResetAt:   (json['ai_quota_reset_at'] as num?)?.toDouble() ?? 0,
      createdAt:        (json['created_at'] as num?)?.toDouble() ?? 0,
    );
  }
}