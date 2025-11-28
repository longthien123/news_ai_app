import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NewsManagementPage extends StatefulWidget {
  const NewsManagementPage({super.key});

  @override
  State<NewsManagementPage> createState() => _NewsManagementPageState();
}

class _NewsManagementPageState extends State<NewsManagementPage> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  
  final List<String> _categories = [
    'all',
    'Thể thao',
    'Chính trị',
    'Kinh tế',
    'Giải trí',
    'Công nghệ',
    'Sức khỏe',
    'Giáo dục',
    'Tổng hợp',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý Tin tức',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search and Filter
                Row(
                  children: [
                    // Search box
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value.toLowerCase());
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tiêu đề...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Category filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        underline: const SizedBox(),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat == 'all' ? 'Tất cả' : cat),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // News list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('news')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var newsList = snapshot.data!.docs;
                
                // Filter by search
                if (_searchQuery.isNotEmpty) {
                  newsList = newsList.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery);
                  }).toList();
                }
                
                // Filter by category
                if (_selectedCategory != 'all') {
                  newsList = newsList.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['category'] == _selectedCategory;
                  }).toList();
                }

                if (newsList.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy tin tức nào'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final newsDoc = newsList[index];
                    final newsData = newsDoc.data() as Map<String, dynamic>;
                    return _buildNewsCard(newsDoc.id, newsData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(String newsId, Map<String, dynamic> newsData) {
    final title = newsData['title'] ?? 'Không có tiêu đề';
    final category = newsData['category'] ?? 'Tổng hợp';
    final source = newsData['source'] ?? '';
    final createdAt = newsData['createdAt'] as Timestamp?;
    final imageUrls = newsData['imageUrls'] as List<dynamic>?;
    final imageUrl = (imageUrls != null && imageUrls.isNotEmpty) 
        ? imageUrls[0] as String 
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showNewsDetails(newsId, newsData),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.article, size: 40),
                ),
              const SizedBox(width: 16),
              
              // News info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(category),
                            ),
                          ),
                        ),
                        if (source.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• $source',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Xem chi tiết'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Xóa tin', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _showNewsDetails(newsId, newsData);
                      break;
                    case 'delete':
                      _deleteNews(newsId, title);
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Thể thao':
        return Colors.green;
      case 'Chính trị':
        return Colors.red;
      case 'Kinh tế':
        return Colors.blue;
      case 'Giải trí':
        return Colors.pink;
      case 'Công nghệ':
        return Colors.purple;
      case 'Sức khỏe':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  void _showNewsDetails(String newsId, Map<String, dynamic> newsData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chi tiết Tin tức',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Images
                if (newsData['imageUrls'] != null && 
                    (newsData['imageUrls'] as List).isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (newsData['imageUrls'] as List).length,
                      itemBuilder: (context, index) {
                        final url = (newsData['imageUrls'] as List)[index] as String;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                
                _buildDetailRow('ID', newsId),
                _buildDetailRow('Tiêu đề', newsData['title'] ?? 'N/A'),
                _buildDetailRow('Category', newsData['category'] ?? 'N/A'),
                _buildDetailRow('Nguồn', newsData['source'] ?? 'N/A'),
                _buildDetailRow('Nội dung', newsData['content'] ?? 'N/A', maxLines: 10),
                if (newsData['createdAt'] != null)
                  _buildDetailRow(
                    'Ngày tạo',
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format((newsData['createdAt'] as Timestamp).toDate()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNews(String newsId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa tin "$title"?\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('news')
            .doc(newsId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tin tức')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }
}
