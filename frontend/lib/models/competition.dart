import 'dart:convert';

class Competition {
  final String id; // معرّف محلي بسيط
  String name;
  String product;
  int completed; // عدد الطلبات المنجزة
  int target; // هدف الطلبات
  String prize; // قيمة الجائزة (نص)
  DateTime? startsAt;
  DateTime? endsAt;

  Competition({
    required this.id,
    required this.name,
    required this.product,
    required this.completed,
    required this.target,
    required this.prize,
    this.startsAt,
    this.endsAt,
  });

  factory Competition.create({
    required String name,
    required String product,
    required int completed,
    required int target,
    required String prize,
    DateTime? startsAt,
    DateTime? endsAt,
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
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'product': product,
    'completed': completed,
    'target': target,
    'prize': prize,
    'starts_at': startsAt?.toIso8601String(),
    'ends_at': endsAt?.toIso8601String(),
  };

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  factory Competition.fromMap(Map<String, dynamic> map) => Competition(
    id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: map['name'] ?? '',
    product: map['product'] ?? '',
    completed: (map['completed'] is int)
        ? map['completed'] as int
        : int.tryParse(map['completed']?.toString() ?? '0') ?? 0,
    target: (map['target'] is int) ? map['target'] as int : int.tryParse(map['target']?.toString() ?? '0') ?? 0,
    prize: map['prize']?.toString() ?? '',
    startsAt: _parseDate(map['starts_at']),
    endsAt: _parseDate(map['ends_at']),
  );

  String toJson() => jsonEncode(toMap());
  factory Competition.fromJson(String source) => Competition.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
