class Group {
  final int    id;
  final String name;
  final int    ownerId;
  final String? inviteCode;
  final String baseCurrency;
  final bool   isActive;
  final double createdAt;
  final double updatedAt;
  
  const Group({
    required this.id,
    required this.name,
    required this.ownerId,
    this.inviteCode,
    required this.baseCurrency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id:           j['id'] as int,
        name:         j['name'] as String,
        ownerId:      j['owner_id'] as int,
        inviteCode:   j['invite_code'] as String?,
        baseCurrency: j['base_currency'] as String? ?? 'JPY',
        isActive:     j['is_active'] as bool? ?? true,
        createdAt:    (j['created_at'] as num).toDouble(),
        updatedAt:    (j['updated_at'] as num).toDouble(),
      );
}