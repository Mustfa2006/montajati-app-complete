/// 🏙️ نموذج المدينة
/// City Model


class City {
  final String id;
  final String name;
  final String externalId;
  final String provinceId;

  const City({required this.id, required this.name, required this.externalId, required this.provinceId});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      externalId: json['externalId']?.toString() ?? '',
      provinceId: json['provinceId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'externalId': externalId, 'provinceId': provinceId};
  }
}
