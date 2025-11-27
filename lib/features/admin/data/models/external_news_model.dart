class ExternalNewsModel {
  final String id;
  final String title;
  final String description;
  final String url;
  final String urlToImage;
  final String source;
  final String category;
  final DateTime publishedAt;

  ExternalNewsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.source,
    required this.category,
    required this.publishedAt,
  });

  factory ExternalNewsModel.fromJson(Map<String, dynamic> json) {
    return ExternalNewsModel(
      id: json['url'] ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? json['content'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'] ?? '',
      source: json['source']?['name'] ?? 'newsorg',
      category: json['category'] ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert to data expected by addNews usecase (map)
  Map<String, dynamic> toNewsData({String overrideSource = 'newsorg'}) {
    return {
      'title': title,
      'content': description,
      'imageUrls': [if (urlToImage.isNotEmpty) urlToImage],
      'category': _mapCategory(category),
      'source': overrideSource,
    };
  }

  String _mapCategory(String category) {
    final m = {
      'technology': 'Công nghệ',
      'tech': 'Công nghệ',
      'sports': 'Thể thao',
      'business': 'Kinh tế',
      'entertainment': 'Giải trí',
      'health': 'Sức khỏe',
      'science': 'Khoa học',
      'general': 'Tổng hợp',
    };
    if (category.isEmpty) return 'Tổng hợp';
    return m[category.toLowerCase()] ?? 'Tổng hợp';
  }
}
