import 'dart:convert';

class Competition {
  final String id; // معرّف محلي بسيط
  String name;
  String description;
  String product;
  int completed; // عدد الطلبات المنجزة
  int target; // هدف الطلبات
  String prize; // قيمة الجائزة (نص)

  Competition({
    required this.id,
    required this.name,
    required this.description,
    required this.product,
    required this.completed,
    required this.target,
    required this.prize,
  });

  factory Competition.create({
    required String name,
    required String description,
    required String product,
    required int completed,
    required int target,
    required String prize,
  }) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    return Competition(
      id: id,
      name: name,
      description: description,
      product: product,
      completed: completed,
      target: target,
      prize: prize,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'product': product,
        'completed': completed,
        'target': target,
        'prize': prize,
      };

  factory Competition.fromMap(Map<String, dynamic> map) => Competition(
        id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        product: map['product'] ?? '',
        completed: (map['completed'] is int)
            ? map['completed'] as int
            : int.tryParse(map['completed']?.toString() ?? '0') ?? 0,
        target: (map['target'] is int)
            ? map['target'] as int
            : int.tryParse(map['target']?.toString() ?? '0') ?? 0,
        prize: map['prize']?.toString() ?? '',
      );

  String toJson() => jsonEncode(toMap());
  factory Competition.fromJson(String source) => Competition.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

