/// 🏛️ نموذج المحافظة
/// Province Model


class Province {
  final String id;
  final String name;
  final String externalId;

  const Province({required this.id, required this.name, required this.externalId});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      externalId: json['externalId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'externalId': externalId};
  }
}
