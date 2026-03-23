import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/json_converters.dart';

part 'user.freezed.dart';
part 'user.g.dart';

// ── ファイル末尾のトップレベル関数 ─────────────────────────────────────────
List<String> _permissionsToJson(List<String> perms) => perms;

@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory UserProfile({
    required int id,
    @Default('') String username,
    @Default('') String email,
    String? displayName,
    String? avatarUrl,
    int? tgUserId,
    @Default(false) bool isActive,
    @Default('user') String role,
    // createFactory: false をやめ、@JsonKey のコンバータで特殊パースを実現
    @JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson)
    @Default([])
    List<String> permissions,
    @Default(100) int aiQuotaMonthly,
    @Default(0) int aiQuotaUsed,
    @JsonKey(fromJson: numToDouble) @Default(0.0) double aiQuotaResetAt,
    @JsonKey(fromJson: numToDouble) @Default(0.0) double createdAt,
  }) = _UserProfile;

  // _$UserProfileFromJson は json_serializable が正常に生成するようになる
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  String get name => displayName?.isNotEmpty == true ? displayName! : username;
  int get aiQuotaRemaining => aiQuotaMonthly == -1
      ? -1
      : (aiQuotaMonthly - aiQuotaUsed).clamp(0, aiQuotaMonthly);
  double get aiQuotaPercent =>
      aiQuotaMonthly <= 0 ? 0 : (aiQuotaUsed / aiQuotaMonthly).clamp(0.0, 1.0);
  DateTime get quotaResetDate =>
      DateTime.fromMillisecondsSinceEpoch((aiQuotaResetAt * 1000).toInt());
}
