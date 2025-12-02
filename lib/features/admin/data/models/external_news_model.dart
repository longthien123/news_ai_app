import 'package:dart_rss/dart_rss.dart';

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

  factory ExternalNewsModel.fromRssItem({
    required RssItem item,
    required String sourceName,
    required String category,
  }) {
    String imageUrl = '';

    // Tìm ảnh từ enclosure
    if (item.enclosure?.url != null && item.enclosure!.url!.isNotEmpty) {
      imageUrl = item.enclosure!.url!;
    }
    // Hoặc từ media:content
    else if (item.content?.images != null && item.content!.images.isNotEmpty) {
      imageUrl = item.content!.images.first;
    }

    // Parse pubDate an toàn
    DateTime publishedDate = DateTime.now();
    try {
      if (item.pubDate != null) {
        if (item.pubDate is DateTime) {
          publishedDate = item.pubDate as DateTime;
        } else if (item.pubDate is String) {
          publishedDate =
              DateTime.tryParse(item.pubDate as String) ?? DateTime.now();
        }
      }
    } catch (e) {
      print('⚠️ Error parsing pubDate: $e');
    }

    // ✅ Lấy nội dung từ content:encoded hoặc description
    String content = '';
    if (item.content?.value != null && item.content!.value.isNotEmpty) {
      content = item.content!.value;
    } else if (item.description != null && item.description!.isNotEmpty) {
      content = item.description!;
    }

    // Làm sạch HTML
    content = _cleanHtml(content);

    return ExternalNewsModel(
      id:
          item.guid ??
          item.link ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: item.title ?? '',
      description: content,
      url: item.link ?? '',
      urlToImage: imageUrl,
      source: sourceName,
      category: category,
      publishedAt: publishedDate,
    );
  }

  // Xóa HTML tags khỏi description
  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Map<String, dynamic> toNewsData({String? overrideSource}) {
    return {
      'title': title,
      'content':
          description, // ✅ Dùng trực tiếp description (đã có nội dung hoặc lỗi từ webhook)
      'imageUrls': [if (urlToImage.isNotEmpty) urlToImage],
      'category': category == 'Tất cả' ? 'Tổng hợp' : category,
      'source': overrideSource ?? source,
    };
  }

  // String _mapCategory(String category) {
  //   final categoryMap = {
  //     'tất cả': 'Tổng hợp',
  //     'thời sự': 'Chính trị',
  //     'thế giới': 'Khác',
  //     'kinh doanh': 'Kinh tế',
  //     'kinh tế': 'Kinh tế',
  //     'giải trí': 'Giải trí',
  //     'thể thao': 'Thể thao',
  //     'công nghệ': 'Công nghệ',
  //     'số hóa': 'Công nghệ',
  //     'sức khỏe': 'Sức khỏe',
  //     'giáo dục': 'Giáo dục',
  //     'pháp luật': 'Chính trị',
  //     'đời sống': 'Tổng hợp',
  //     'du lịch': 'Tổng hợp',
  //     'xe': 'Khác',
  //     'xã hội': 'Tổng hợp',
  //     'văn hóa': 'Tổng hợp',
  //   };

  //   final lowerCategory = category.toLowerCase();
  //   return categoryMap[lowerCategory] ?? 'Tổng hợp';
  // }
}
