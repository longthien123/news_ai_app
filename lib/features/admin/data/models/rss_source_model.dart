class RssSourceModel {
  final String id;
  final String name;
  final List<RssCategoryModel> categories;

  RssSourceModel({
    required this.id,
    required this.name,
    required this.categories,
  });

  factory RssSourceModel.fromJson(Map<String, dynamic> json) {
    return RssSourceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      categories: (json['categories'] as List)
          .map((c) => RssCategoryModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RssCategoryModel {
  final String name;
  final String rssUrl;

  RssCategoryModel({required this.name, required this.rssUrl});

  factory RssCategoryModel.fromJson(Map<String, dynamic> json) {
    return RssCategoryModel(
      name: json['name'] as String,
      rssUrl: json['rssUrl'] as String,
    );
  }
}
