import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/json_converters.dart';

part 'group.freezed.dart';
part 'group.g.dart';

@freezed
abstract class Group with _$Group {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Group({
    required int id,
    required String name,
    required int ownerId,
    String? inviteCode,
    @Default('JPY') String baseCurrency,
    @Default(true) bool isActive,
    @JsonKey(fromJson: numToDouble) required double createdAt,
    @JsonKey(fromJson: numToDouble) required double updatedAt,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}
