import 'dart:convert';

class Competition {
  final String id;
  String name;
  String product;
  String? productId;
  int completed;
  int target;
  String prize;
  DateTime? startsAt;
  DateTime? endsAt;
  String targetType; // 'all' or 'specific'
  List<String> assignedUserIds;

  Competition({
    required this.id,
    required this.name,
    required this.product,
    this.productId,
    required this.completed,
    required this.target,
    required this.prize,
    this.startsAt,
    this.endsAt,
    this.targetType = 'all',
    this.assignedUserIds = const [],
  });

  factory Competition.create({
    required String name,
    required String product,
    required int completed,
    required int target,
    required String prize,
    DateTime? startsAt,
    DateTime? endsAt,
    String targetType = 'all',
    List<String> assignedUserIds = const [],
  }) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    return Competition(
      id: id,
      name: name,
      product: product,
      completed: completed,
      target: target,
      prize: prize,
      startsAt: startsAt,
      endsAt: endsAt,
      targetType: targetType,
      assignedUserIds: assignedUserIds,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'product': product,
    'product_id': productId,
    'completed': completed,
    'target': target,
    'prize': prize,
    'starts_at': startsAt?.toIso8601String(),
    'ends_at': endsAt?.toIso8601String(),
    'target_type': targetType,
    'user_ids': assignedUserIds,
  };

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  factory Competition.fromMap(Map<String, dynamic> map) {
    List<String> userIds = [];
    if (map['assigned_user_ids'] is List) {
      userIds = (map['assigned_user_ids'] as List).map((e) => e.toString()).toList();
    }
    return Competition(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? '',
      product: map['product'] ?? '',
      productId: map['product_id']?.toString(),
      completed: (map['completed'] is int)
          ? map['completed'] as int
          : int.tryParse(map['completed']?.toString() ?? '0') ?? 0,
      target: (map['target'] is int) ? map['target'] as int : int.tryParse(map['target']?.toString() ?? '0') ?? 0,
      prize: map['prize']?.toString() ?? '',
      startsAt: _parseDate(map['starts_at']),
      endsAt: _parseDate(map['ends_at']),
      targetType: map['target_type']?.toString() ?? 'all',
      assignedUserIds: userIds,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory Competition.fromJson(String source) => Competition.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
