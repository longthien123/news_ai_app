import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ionicons/ionicons.dart';
import '../../domain/entities/news.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/reply.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/reply_model.dart';
import '../../../../core/local/firebase_bookmark_manager.dart';
import '../../data/datasources/remote/news_remote_source.dart';
import '../../data/repositories/news_repo_impl.dart';
import '../widgets/news_details_widgets.dart';
import '../widgets/ai_summary_button.dart';
import '../widgets/ai_summary_bottom_sheet.dart';
import '../../data/datasources/remote/ai_summary_service.dart';
import '../../../notification/data/models/reading_session_model.dart';
import '../../../../core/utils/tts_service.dart';
import 'package:share_plus/share_plus.dart';

//news

class NewsDetailPage extends StatefulWidget {
  final News news;

  const NewsDetailPage({super.key, required this.news});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  bool _isBookmarked = false;
  bool _isLoading = true;
  late FirebaseBookmarkManager _bookmarkManager;
  List<News> _relatedNews = [];
  bool _isLoadingRelated = true;

  // Comment related
  List<Comment> _comments = [];
  bool _isLoadingComments = true;
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  int _displayedCommentsCount = 3;
  Set<String> _likedComments = {};

  // Reply related
  Map<String, List<Reply>> _repliesMap = {};
  Map<String, bool> _showRepliesMap = {};
  String? _replyingToCommentId;
  final TextEditingController _replyController = TextEditingController();

  // AI Summary related
  final AISummaryService _aiSummaryService = AISummaryServiceImpl();

  // Reading session tracking
  String? _sessionId;
  DateTime? _startedAt;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToBottom = false;

  // View tracking
  bool _viewCounted = false;

  // TTS related
  late TtsService _ttsService;
  bool _isTtsPlaying = false;

  @override
  void initState() {
    super.initState();
    _bookmarkManager = FirebaseBookmarkManager.getInstance();
    _ttsService = TtsService();
    _initBookmark();
    _loadRelatedNews();
    _loadComments();
    _loadLikedComments();
    _startReadingSession();
    _scrollController.addListener(_onScroll);
    _initializeTts();
    _startViewTracking();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _scrollController.dispose();
    _ttsService.dispose();
    _endReadingSession();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    try {
      await _ttsService.initialize();
      debugPrint('TTS service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> _toggleTts() async {
    try {
      if (_isTtsPlaying) {
        // Nếu đang phát, dừng lại
        await _ttsService.stop();
        setState(() {
          _isTtsPlaying = false;
        });
      } else {
        // Nếu không phát, bắt đầu đọc
        String contentToSpeak = "${widget.news.title}. ${widget.news.content}";
        
        // Loại bỏ các ký tự đặc biệt có thể gây lỗi
        contentToSpeak = contentToSpeak
            .replaceAll(RegExp(r'<[^>]*>'), '') // Loại bỏ HTML tags
            .replaceAll(RegExp(r'&[^;]+;'), '') // Loại bỏ HTML entities
            .replaceAll(RegExp(r'\s+'), ' ') // Loại bỏ khoảng trắng thừa
            .trim();
        
        await _ttsService.speak(contentToSpeak);
        setState(() {
          _isTtsPlaying = true;
        });

        // Lắng nghe khi TTS kết thúc để cập nhật UI
        _checkTtsStatus();
      }
    } catch (e) {
      debugPrint('Error toggling TTS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phát âm thanh: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _checkTtsStatus() async {
    // Kiểm tra định kỳ xem TTS còn đang chạy không
    while (_isTtsPlaying && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_ttsService.isSpeaking && _isTtsPlaying) {
        setState(() {
          _isTtsPlaying = false;
        });
        break;
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (!_isScrolledToBottom) {
        setState(() => _isScrolledToBottom = true);
      }
    }
  }

  Future<void> _startViewTracking() async {
    // Wait for 10 seconds
    await Future.delayed(const Duration(seconds: 10));
    
    // Check if widget is still mounted and view hasn't been counted yet
    if (mounted && !_viewCounted) {
      await _incrementViewCount();
      _viewCounted = true;
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      // Increment view count in Firestore
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .update({
        'views': FieldValue.increment(1),
      });
      
      debugPrint('📊 View count incremented for: ${widget.news.title}');
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> _startReadingSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${widget.news.id}';
    _startedAt = DateTime.now();

    final session = ReadingSessionModel(
      userId: user.uid,
      newsId: widget.news.id,
      category: widget.news.category,
      title: widget.news.title,
      startedAt: _startedAt!,
      durationSeconds: 0,
      isBookmarked: _isBookmarked,
      isCompleted: false,
    );

    // Save to Firestore với id là sessionId
    final sessionData = session.toJson();
    sessionData['id'] = _sessionId; // Add id to JSON

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingSessions')
        .doc(_sessionId)
        .set(sessionData);

    print('📖 Started reading session: ${widget.news.title.substring(0, 30)}...');
  }

  Future<void> _endReadingSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionId == null || _startedAt == null) return;

    final duration = DateTime.now().difference(_startedAt!).inSeconds;

    // Update session
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingSessions')
        .doc(_sessionId)
        .update({
      'durationSeconds': duration,
      'isBookmarked': _isBookmarked,
      'isCompleted': _isScrolledToBottom,
    });

    print('📖 Ended reading session: ${duration}s, bookmarked: $_isBookmarked, completed: $_isScrolledToBottom');
  }

  Future<void> _initBookmark() async {
    try {
      final isBookmarked = await _bookmarkManager.isBookmarked(widget.news.id);
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing bookmark: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRelatedNews() async {
    try {
      final remoteSource = NewsRemoteSourceImpl(
        firestore: FirebaseFirestore.instance,
      );
      final repository = NewsRepositoryImpl(remoteSource: remoteSource);

      final allRelatedNews = await repository.getNewsByCategory(
        widget.news.category,
      );

      // Filter out current news and limit to 3
      final filtered = allRelatedNews
          .where((news) => news.id != widget.news.id)
          .take(3)
          .toList();

      if (mounted) {
        setState(() {
          _relatedNews = filtered;
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading related news: $e');
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      final comments = await Future.wait(
        querySnapshot.docs.map((doc) => CommentModel.fromFirestoreWithUserData(doc)),
      );

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _loadLikedComments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load all comments and check which ones user has liked
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .get();

      final likedIds = <String>{};
      for (var doc in commentsSnapshot.docs) {
        final data = doc.data();
        final likedBy = data['likedBy'] as List<dynamic>?;
        if (likedBy != null && likedBy.contains(user.uid)) {
          likedIds.add(doc.id);
        }
      }

      if (mounted) {
        setState(() {
          _likedComments = likedIds;
        });
      }
    } catch (e) {
      debugPrint('Error loading liked comments: $e');
    }
  }

  Future<void> _toggleLikeComment(Comment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để thích bình luận'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final commentRef = FirebaseFirestore.instance
        .collection('news')
        .doc(widget.news.id)
        .collection('comments')
        .doc(comment.id);

    try {
      final isLiked = _likedComments.contains(comment.id);

      if (isLiked) {
        // Unlike
        await commentRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid]),
        });
        setState(() {
          _likedComments.remove(comment.id);
        });
      } else {
        // Like
        await commentRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
        });
        setState(() {
          _likedComments.add(comment.id);
        });
      }

      await _loadComments();
    } catch (e) {
      debugPrint('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != comment.userId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bình luận'),
        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .doc(comment.id)
          .delete();

      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bình luận'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadReplies(String commentId) async {
    try {
      final repliesSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .get();

      final replies = await Future.wait(
        repliesSnapshot.docs.map((doc) => ReplyModel.fromFirestoreWithUserData(doc)),
      );

      if (mounted) {
        setState(() {
          _repliesMap[commentId] = replies.cast<Reply>();
        });
      }
    } catch (e) {
      debugPrint('Error loading replies: $e');
    }
  }

  Future<void> _postReply(Comment comment) async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để trả lời'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final replyData = {
        'commentId': comment.id,
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Anonymous',
        'content': replyText,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add reply
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .doc(comment.id)
          .collection('replies')
          .add(replyData);

      // Update replies count
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .doc(comment.id)
          .update({'repliesCount': FieldValue.increment(1)});

      _replyController.clear();
      setState(() {
        _replyingToCommentId = null;
      });

      await _loadReplies(comment.id);
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã trả lời'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error posting reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleReplies(String commentId) {
    setState(() {
      final isShowing = _showRepliesMap[commentId] ?? false;
      _showRepliesMap[commentId] = !isShowing;

      if (!isShowing && !_repliesMap.containsKey(commentId)) {
        _loadReplies(commentId);
      }
    });
  }

  Future<void> _deleteReply(String commentId, Reply reply) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != reply.userId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa trả lời'),
        content: const Text('Bạn có chắc muốn xóa trả lời này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete reply
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(reply.id)
          .delete();

      // Update replies count
      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .doc(commentId)
          .update({'repliesCount': FieldValue.increment(-1)});

      await _loadReplies(commentId);
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa trả lời'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _postComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để bình luận'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isPostingComment = true;
    });

    try {
      final commentData = {
        'newsId': widget.news.id,
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Anonymous',
        'content': commentText,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'repliesCount': 0,
        'likedBy': [],
      };

      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news.id)
          .collection('comments')
          .add(commentData);

      _commentController.clear();
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đăng bình luận'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading) return;

    try {
      if (!_bookmarkManager.isUserLoggedIn()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để lưu tin tức'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final isBookmarked = await _bookmarkManager.toggleBookmark(
        widget.news.id,
      );

      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBookmarked ? 'Đã lưu tin tức' : 'Đã bỏ lưu tin tức',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAISummary() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => AISummaryBottomSheetWrapper(
        onLoad: () => _aiSummaryService.summarizeNews(
          widget.news.title,
          widget.news.content,
        ),
      ),
    );
  }

  Future<void> _showShareOptions() async {
    // Link HTTPS - CÓ THỂ CLICK trực tiếp trong mọi app!
    final encodedTitle = Uri.encodeComponent(widget.news.title);
    final clickableLink = 'https://4tk-news.vercel.app/share?id=${widget.news.id}&t=$encodedTitle';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chia sẻ tin tức',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.news.title,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Ionicons.link, color: AppColors.primary),
              title: const Text('Copy link'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: clickableLink));
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Đã sao chép link vào clipboard!'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.share, color: AppColors.primary),
              title: const Text('Chia sẻ qua ứng dụng khác'),
              subtitle: const Text('Messenger, Zalo, Email...'),
              onTap: () async {
                Navigator.pop(context);
                // Chỉ gửi link - không thể tránh duplicate nếu có text
                final shareText = clickableLink;
                try {
                  await Share.share(shareText, subject: widget.news.title);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Hero Image Section
                NewsDetailHeroSection(
                  news: widget.news,
                  isBookmarked: _isBookmarked,
                  isLoading: _isLoading,
                  onBack: () => Navigator.pop(context),
                  onToggleBookmark: _toggleBookmark,
                  onMore: _showShareOptions,
                  onToggleTts: _toggleTts,
                  isTtsPlaying: _isTtsPlaying,
                ),

                // Content Section
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -30, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content with images distributed evenly
                        NewsDetailContentSection(news: widget.news),

                        const SizedBox(height: 10),

                        // Divider
                        Divider(color: Colors.grey[300], thickness: 1),
                        const SizedBox(height: 20),

                        // Comments Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bình luận (${_comments.length})',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Comment Input Field
                        CommentInputField(
                          controller: _commentController,
                          isPosting: _isPostingComment,
                          onPost: _postComment,
                          userAvatar: FirebaseAuth.instance.currentUser?.photoURL,
                        ),
                        const SizedBox(height: 20),

                        // Comments List
                        _buildCommentsList(),

                        const SizedBox(height: 30),

                        // Related News Section
                        if (_relatedNews.isNotEmpty) ...[
                          const Text(
                            'Tin tức liên quan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          RelatedNewsListWidget(
                            relatedNews: _relatedNews,
                            isLoading: _isLoadingRelated,
                            onNewsTap: (news) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NewsDetailPage(news: news),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fixed X button at bottom left
          FixedCloseButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),

          // AI Summary floating button
          AISummaryButton(onPressed: _showAISummary),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return CommentsListWidget(
      comments: _comments,
      displayedCount: _displayedCommentsCount,
      isLoading: _isLoadingComments,
      onLoadMore: () {
        setState(() {
          _displayedCommentsCount += 3;
        });
      },
      onBuildComment: (comment) => _buildCommentCard(comment),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    final isLiked = _likedComments.contains(comment.id);
    final isReplying = _replyingToCommentId == comment.id;
    final showReplies = _showRepliesMap[comment.id] ?? false;
    final replies = _repliesMap[comment.id];

    return CommentCard(
      comment: comment,
      isLiked: isLiked,
      isReplying: isReplying,
      showReplies: showReplies,
      replies: replies,
      replyController: _replyController,
      onLike: () => _toggleLikeComment(comment),
      onReply: () {
        setState(() {
          _replyingToCommentId = comment.id;
        });
      },
      onToggleReplies: () => _toggleReplies(comment.id),
      onPostReply: () => _postReply(comment),
      onCancelReply: () {
        setState(() {
          _replyingToCommentId = null;
          _replyController.clear();
        });
      },
      onDelete: () => _deleteComment(comment),
      onBuildReply: (reply) => _buildReplyCard(comment.id, reply),
    );
  }

  Widget _buildReplyCard(String commentId, Reply reply) {
    return ReplyCard(
      reply: reply,
      onDelete: () => _deleteReply(commentId, reply),
    );
  }
}
