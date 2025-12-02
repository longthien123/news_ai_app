import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/news/data/models/news_model.dart';
import '../../features/news/presentation/pages/news_home_details.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Khởi tạo deep link service với navigator key
  void initializeWithNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _setupDeepLinkListener();
  }

  /// Setup listener cho deep link
  Future<void> _setupDeepLinkListener() async {
    // Xử lý initial link (khi app được mở từ deep link)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Lắng nghe các deep link khi app đang chạy
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  /// Xử lý deep link
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('🔗 Received deep link: $uri');
    debugPrint('   Host: ${uri.host}');
    debugPrint('   Path segments: ${uri.pathSegments}');
    debugPrint('   Query parameters: ${uri.queryParameters}');
    
    if (_navigatorKey?.currentContext == null) {
      debugPrint('❌ Navigator context not available yet');
      return;
    }
    
    // Các scheme và format được hỗ trợ:
    // newsai://open/ABC123 (recommended - path preserves case)
    // https://4tk-news-xxx.vercel.app/share?id=ABC123 (CLICKABLE - NEW!)

    String? newsId;
    
    // Kiểm tra scheme và path
    if (uri.scheme == 'newsai') {
      if (uri.pathSegments.isNotEmpty) {
        // newsai://open/ABC123 - lấy path segment cuối cùng
        newsId = uri.pathSegments.last;
        debugPrint('   Parsed newsId from path: $newsId');
      } else if (uri.host.isNotEmpty) {
        // newsai://ABC123 - fallback (sẽ bị lowercase)
        newsId = uri.host;
        debugPrint('   Parsed newsId from host (lowercase): $newsId');
      }
    } else if (uri.scheme == 'https' || uri.scheme == 'http') {
      // HTTPS link: https://domain.com/share?id=ABC123
      if (uri.queryParameters.containsKey('id')) {
        newsId = uri.queryParameters['id'];
        debugPrint('   Parsed newsId from HTTPS query param: $newsId');
      }
      // Legacy support: https://newsai.app/news/{newsId}
      else if (uri.host == 'newsai.app' && 
               uri.pathSegments.length >= 2 &&
               uri.pathSegments[0] == 'news') {
        newsId = uri.pathSegments[1];
        debugPrint('   Parsed newsId from HTTPS path: $newsId');
      }
    }

    if (newsId != null && newsId.isNotEmpty) {
      debugPrint('✓ Navigating to news: $newsId');
      await _navigateToNewsDetail(newsId);
    } else {
      debugPrint('❌ Invalid deep link format');
      _showError('Liên kết không hợp lệ');
    }
  }

  /// Điều hướng đến trang chi tiết tin tức
  Future<void> _navigateToNewsDetail(String newsId) async {
    // Đợi context sẵn sàng (quan trọng khi app mới start)
    int retries = 0;
    while (_navigatorKey?.currentContext == null && retries < 10) {
      debugPrint('⏳ Waiting for navigator context... (retry $retries)');
      await Future.delayed(const Duration(milliseconds: 300));
      retries++;
    }
    
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('❌ Navigator context still not available after retries');
      return;
    }

    try {
      debugPrint('📥 Loading news from Firestore: $newsId');
      
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Lấy tin tức từ Firestore
      final newsDoc = await FirebaseFirestore.instance
          .collection('news')
          .doc(newsId)
          .get();

      debugPrint('📦 News doc exists: ${newsDoc.exists}');

      // Đóng loading
      if (_navigatorKey?.currentContext != null) {
        Navigator.of(_navigatorKey!.currentContext!).pop();
      }

      if (!newsDoc.exists) {
        debugPrint('❌ News not found in Firestore');
        _showError('Không tìm thấy tin tức');
        return;
      }

      // Chuyển đổi sang News entity
      final news = NewsModel.fromFirestore(newsDoc);
      debugPrint('✅ News loaded: ${news.title}');

      // Điều hướng đến trang chi tiết
      if (_navigatorKey?.currentContext != null) {
        debugPrint('🚀 Navigating to NewsDetailPage...');
        await Navigator.of(_navigatorKey!.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(news: news),
          ),
        );
        debugPrint('✓ Navigation completed');
      }
    } catch (e) {
      debugPrint('❌ Error loading news: $e');
      if (_navigatorKey?.currentContext != null) {
        try {
          Navigator.of(_navigatorKey!.currentContext!).pop(); // Đóng loading nếu còn mở
        } catch (_) {}
      }
      _showError('Lỗi khi tải tin tức: $e');
    }
  }

  /// Hiển thị thông báo lỗi
  void _showError(String message) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Tạo deep link URL từ newsId
  static String createDeepLink(String newsId) {
    // Sử dụng path để preserve case sensitivity
    return 'newsai://open/$newsId';
  }

  /// Tạo web link (dùng cho production với domain thật)
  static String createWebLink(String newsId) {
    return 'https://newsai.app/news/$newsId';
  }

  /// Hủy subscription
  void dispose() {
    _linkSubscription?.cancel();
  }
}
