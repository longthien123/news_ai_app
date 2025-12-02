import 'package:app_news_ai/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/news.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/reply.dart';

/// Hero image section with gradient overlay and navigation buttons
class NewsDetailHeroSection extends StatelessWidget {
  final News news;
  final bool isBookmarked;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final VoidCallback onMore;
  final VoidCallback? onToggleTts;
  final bool isTtsPlaying;

  const NewsDetailHeroSection({
    super.key,
    required this.news,
    required this.isBookmarked,
    required this.isLoading,
    required this.onBack,
    required this.onToggleBookmark,
    required this.onMore,
    this.onToggleTts,
    this.isTtsPlaying = false,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          width: double.infinity,
          child: news.imageUrls.isNotEmpty
              ? Image.network(news.imageUrls[0], fit: BoxFit.cover)
              : Container(color: Colors.grey[300]),
        ),

        // Gradient Overlay
        Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
        ),

        // Top Navigation Buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Ionicons.chevron_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: onBack,
                  ),
                ),

                // Right Actions
                Row(
                  children: [
                    // TTS Button
                    if (onToggleTts != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isTtsPlaying
                                ? Ionicons.pause
                                : Ionicons.volume_high,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: onToggleTts,
                        ),
                      ),
                    if (onToggleTts != null) const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Ionicons.bookmark
                                    : Ionicons.bookmark_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: onToggleBookmark,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Ionicons.ellipsis_horizontal,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: onMore,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Content Overlay on Image
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(90),
                  ),
                  child: Text(
                    news.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  news.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 12),

                // Author and Date
                Text(
                  '${news.source} - ${_formatDate(news.createdAt)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Content section with distributed images
class NewsDetailContentSection extends StatelessWidget {
  final News news;

  const NewsDetailContentSection({super.key, required this.news});

  List<String> _splitIntoParagraphs(String content) {
    // Remove URLs in square brackets (e.g., [https://example.com])
    content = content.replaceAll(RegExp(r'\[https?://[^\]]+\]'), '');
    
    // Remove any lines that only contain URLs
    content = content.split('\n')
        .where((line) => !line.trim().startsWith('http'))
        .join('\n');
    
    // First, try to split by existing newlines
    List<String> paragraphs = content
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // If content is one big block (no newlines), split by sentences
    // Create paragraphs of roughly 3-4 sentences each
    if (paragraphs.length <= 1 && content.length > 200) {
      // Split by periods followed by space and capital letter or end of string
      List<String> sentences = content
          .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])'))
          .where((s) => s.trim().isNotEmpty)
          .toList();

      paragraphs = [];
      List<String> currentParagraph = [];
      int sentenceCount = 0;

      for (var sentence in sentences) {
        currentParagraph.add(sentence);
        sentenceCount++;

        // Create a new paragraph after every 3-4 sentences
        if (sentenceCount >= 3) {
          paragraphs.add(currentParagraph.join(' ').trim());
          currentParagraph = [];
          sentenceCount = 0;
        }
      }

      // Add remaining sentences
      if (currentParagraph.isNotEmpty) {
        paragraphs.add(currentParagraph.join(' ').trim());
      }
    }

    return paragraphs;
  }

  List<Widget> _buildContentWithImages() {
    List<Widget> widgets = [];

    // Extract author name (text after last sentence punctuation)
    String contentToDisplay = news.content;
    String? authorName;

    // Find ALL sentence endings and get the text after the LAST one
    final matches = RegExp(r'[.!?]').allMatches(news.content.trim());
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      final textAfterLastPunctuation = news.content.substring(lastMatch.end).trim();
      
      // Check if there's text after the last punctuation
      if (textAfterLastPunctuation.isNotEmpty) {
        // Check if it looks like an author attribution
        if (textAfterLastPunctuation.contains('(') ||
            textAfterLastPunctuation.toLowerCase().contains('theo') ||
            textAfterLastPunctuation.length < 100) {
          authorName = textAfterLastPunctuation;
          // Remove author from content (keep the last punctuation)
          contentToDisplay = news.content.substring(0, lastMatch.end).trim();
        }
      }
    }

    // Split content into paragraphs intelligently
    List<String> paragraphs = _splitIntoParagraphs(contentToDisplay);

    // Images to distribute (skip the first one as it's the hero image)
    List<String> imagesToDistribute = news.imageUrls.length > 1
        ? news.imageUrls.skip(1).toList()
        : [];

    if (imagesToDistribute.isEmpty) {
      // No additional images, just show content with paragraphs
      for (int i = 0; i < paragraphs.length; i++) {
        widgets.add(
          Text(
            paragraphs[i],
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.7,
            ),
          ),
        );

        // Add spacing between paragraphs
        if (i < paragraphs.length - 1) {
          widgets.add(const SizedBox(height: 16));
        }
      }
    } else {
      // Calculate how many paragraphs between each image
      int totalParagraphs = paragraphs.length;
      int totalImages = imagesToDistribute.length;
      double paragraphsPerImage = totalParagraphs / (totalImages + 1);

      int currentParagraphIndex = 0;
      int currentImageIndex = 0;

      while (currentParagraphIndex < totalParagraphs ||
          currentImageIndex < totalImages) {
        // Add paragraphs
        int paragraphsToAdd = paragraphsPerImage.ceil();
        if (currentParagraphIndex < totalParagraphs) {
          int endIndex = (currentParagraphIndex + paragraphsToAdd).clamp(
            0,
            totalParagraphs,
          );

          for (int i = currentParagraphIndex; i < endIndex; i++) {
            widgets.add(
              Text(
                paragraphs[i],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.7,
                ),
              ),
            );

            // Add spacing between paragraphs
            if (i < endIndex - 1) {
              widgets.add(const SizedBox(height: 16));
            }
          }

          currentParagraphIndex = endIndex;

          // Add spacing after text
          widgets.add(const SizedBox(height: 20));
        }

        // Add image if available
        if (currentImageIndex < totalImages) {
          widgets.add(
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imagesToDistribute[currentImageIndex],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );

          currentImageIndex++;

          // Add spacing after image
          if (currentParagraphIndex < totalParagraphs) {
            widgets.add(const SizedBox(height: 20));
          }
        }
      }
    }

    // Add author name at the end, aligned to the right (if found in content)
    if (authorName != null && authorName.isNotEmpty) {
      widgets.add(const SizedBox(height: 24));
      widgets.add(
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            authorName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildContentWithImages(),
    );
  }
}

/// Comment input field
class CommentInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onPost;
  final String? userAvatar;

  const CommentInputField({
    super.key,
    required this.controller,
    required this.isPosting,
    required this.onPost,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          backgroundImage: userAvatar != null && userAvatar!.isNotEmpty
              ? NetworkImage(userAvatar!)
              : null,
          child: userAvatar != null && userAvatar!.isNotEmpty
              ? null
              : Icon(Ionicons.person, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Viết bình luận...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: isPosting
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Ionicons.send, color: AppColors.primary),
                      onPressed: onPost,
                    ),
            ),
            maxLines: null,
          ),
        ),
      ],
    );
  }
}

/// Comments list with load more functionality
class CommentsListWidget extends StatelessWidget {
  final List<Comment> comments;
  final int displayedCount;
  final bool isLoading;
  final VoidCallback onLoadMore;
  final Function(Comment) onBuildComment;

  const CommentsListWidget({
    super.key,
    required this.comments,
    required this.displayedCount,
    required this.isLoading,
    required this.onLoadMore,
    required this.onBuildComment,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Chưa có bình luận nào',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    final displayedComments = comments.take(displayedCount).toList();
    final hasMore = comments.length > displayedCount;

    return Column(
      children: [
        ...displayedComments
            .map((comment) => onBuildComment(comment) as Widget)
            .toList(),

        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: TextButton.icon(
              onPressed: onLoadMore,
              icon: Icon(Ionicons.chevron_down, color: AppColors.primary),
              label: Text(
                'Xem thêm bình luận (${comments.length - displayedCount})',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Comment card widget
class CommentCard extends StatelessWidget {
  final Comment comment;
  final bool isLiked;
  final bool isReplying;
  final bool showReplies;
  final List<Reply>? replies;
  final TextEditingController? replyController;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onToggleReplies;
  final VoidCallback? onPostReply;
  final VoidCallback? onCancelReply;
  final VoidCallback? onDelete;
  final Function(Reply)? onBuildReply;

  const CommentCard({
    super.key,
    required this.comment,
    required this.isLiked,
    required this.isReplying,
    required this.showReplies,
    this.replies,
    this.replyController,
    required this.onLike,
    required this.onReply,
    required this.onToggleReplies,
    this.onPostReply,
    this.onCancelReply,
    this.onDelete,
    this.onBuildReply,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == comment.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                    ? NetworkImage(comment.userAvatar!)
                    : null,
                child: comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                    ? null
                    : Icon(
                        Ionicons.person,
                        size: 16,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isOwner && onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Ionicons.ellipsis_horizontal,
                    size: 18,
                    color: Colors.black,
                  ),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.trash_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete!();
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Like button
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Ionicons.heart : Ionicons.heart_outline,
                        size: 16,
                        color: isLiked ? Colors.red : Colors.grey[600],
                      ),
                      if (comment.likes > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${comment.likes}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Reply button
              InkWell(
                onTap: onReply,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Ionicons.chatbubble_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      if (comment.repliesCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${comment.repliesCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Reply input field
          if (isReplying && replyController != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: TextField(
                    controller: replyController,
                    decoration: InputDecoration(
                      hintText: 'Viết câu trả lời...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onPostReply != null)
                            IconButton(
                              icon: Icon(
                                Ionicons.send,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              onPressed: onPostReply,
                            ),
                          if (onCancelReply != null)
                            IconButton(
                              icon: Icon(
                                Ionicons.close,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                              onPressed: onCancelReply,
                            ),
                        ],
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ],

          // Show/Hide replies button
          if (comment.repliesCount > 0) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onToggleReplies,
              child: Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Text(
                  showReplies
                      ? 'Ẩn ${comment.repliesCount} câu trả lời'
                      : 'Xem ${comment.repliesCount} câu trả lời',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // Replies list
          if (showReplies && replies != null && onBuildReply != null) ...[
            const SizedBox(height: 8),
            ...replies!.map((reply) => onBuildReply!(reply) as Widget),
          ],
        ],
      ),
    );
  }
}

/// Reply card widget
class ReplyCard extends StatelessWidget {
  final Reply reply;
  final VoidCallback? onDelete;

  const ReplyCard({super.key, required this.reply, this.onDelete});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == reply.userId;

    return Container(
      margin: const EdgeInsets.only(left: 32, top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: reply.userAvatar != null && reply.userAvatar!.isNotEmpty
                    ? NetworkImage(reply.userAvatar!)
                    : null,
                child: reply.userAvatar != null && reply.userAvatar!.isNotEmpty
                    ? null
                    : Icon(
                        Ionicons.person,
                        size: 14,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _formatDate(reply.createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isOwner && onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Ionicons.ellipsis_horizontal,
                    size: 16,
                    color: Colors.black,
                  ),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.trash_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Xóa',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete!();
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reply.content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Related news card widget
class RelatedNewsCard extends StatelessWidget {
  final News news;
  final VoidCallback onTap;

  const RelatedNewsCard({super.key, required this.news, required this.onTap});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: news.imageUrls.isNotEmpty
                  ? Image.network(
                      news.imageUrls[0],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        news.category,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date
                    Text(
                      _formatDate(news.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Related news list widget
class RelatedNewsListWidget extends StatelessWidget {
  final List<News> relatedNews;
  final bool isLoading;
  final Function(News) onNewsTap;

  const RelatedNewsListWidget({
    super.key,
    required this.relatedNews,
    required this.isLoading,
    required this.onNewsTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: relatedNews
          .map(
            (news) => RelatedNewsCard(news: news, onTap: () => onNewsTap(news)),
          )
          .toList(),
    );
  }
}

/// Fixed close button widget
class FixedCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FixedCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
