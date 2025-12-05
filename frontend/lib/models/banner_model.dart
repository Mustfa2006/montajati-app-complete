/// نموذج البانر الإعلاني
class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? actionUrl;
  final bool isActive;
  final int order;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.actionUrl,
    this.isActive = true,
    this.order = 0,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      title: json['title'],
      subtitle: json['subtitle'],
      actionUrl: json['action_url'] ?? json['actionUrl'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'action_url': actionUrl,
      'is_active': isActive,
      'order': order,
    };
  }

  @override
  String toString() => 'BannerModel(id: $id, title: $title)';
}

