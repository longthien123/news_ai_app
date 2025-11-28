import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/external_news_model.dart';
import '../../data/models/rss_source_model.dart';
import '../cubit/news_cubit.dart';

class RssPickerDialog extends StatefulWidget {
  final Function(ExternalNewsModel) onSelect;

  const RssPickerDialog({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<RssPickerDialog> createState() => _RssPickerDialogState();
}

class _RssPickerDialogState extends State<RssPickerDialog> {
  RssSourceModel? _selectedSource;
  RssCategoryModel? _selectedRssCategory;
  List<ExternalNewsModel> _currentNewsList = [];
  final _searchController = TextEditingController();
  bool _isLoadingWebhook = false;

  // ✅ Webhook URL của bạn
  static const String webhookUrl =
      'https://longthien.duckdns.org/webhook/send-news';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Hàm gọi webhook, trả về nội dung hoặc lỗi
  Future<String> _fetchContentFromWebhook(
    String articleUrl,
    String category,
  ) async {
    try {
      final requestBody = json.encode({
        'url': articleUrl,
        'category': category,
      });

      final response = await http
          .post(
            Uri.parse(webhookUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 60)); // Timeout 60s

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        dynamic contentData = (data is List && data.isNotEmpty)
            ? data[0]
            : data;

        final textContent = contentData['textContent'];
        if (textContent != null && textContent.toString().isNotEmpty) {
          return textContent.toString();
        } else {
          return 'LỖI: Webhook không trả về "textContent".\n\nResponse nhận được:\n${json.encode(data)}';
        }
      } else {
        return 'LỖI: Webhook trả về mã lỗi ${response.statusCode}.\n\nNội dung lỗi:\n${response.body}';
      }
    } on TimeoutException {
      return 'LỖI: Webhook quá thời gian (60 giây).';
    } catch (e) {
      return 'LỖI: Không thể kết nối tới webhook.\n\nChi tiết:\n$e';
    }
  }

  // ✅ Xử lý khi chọn tin
  Future<void> _onNewsSelected(ExternalNewsModel news) async {
    setState(() {
      _isLoadingWebhook = true;
    });

    // Gọi webhook và nhận kết quả (nội dung hoặc lỗi)
    final String webhookResult = await _fetchContentFromWebhook(
      news.url,
      news.category,
    );

    // Tạo một bản sao của tin tức và cập nhật description bằng kết quả từ webhook
    final updatedNews = ExternalNewsModel(
      id: news.id,
      title: news.title,
      description: webhookResult, // Gán nội dung hoặc lỗi vào đây
      url: news.url,
      urlToImage: news.urlToImage,
      source: news.source,
      category: news.category,
      publishedAt: news.publishedAt,
    );

    if (mounted) {
      Navigator.of(context).pop(); // Đóng dialog
      widget.onSelect(updatedNews); // Gửi tin đã cập nhật về trang AddNewsPage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            _buildHeader(),
            // ✅ Hiển thị loading UI khi đang gọi webhook
            if (_isLoadingWebhook)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Đang tải nội dung từ bản gốc...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(child: _buildNewsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rss_feed, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Thêm tin nhanh từ RSS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tin...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        if (_currentNewsList.isNotEmpty) {
                          context.read<NewsCubit>().searchInCurrentList(
                            _currentNewsList,
                            '',
                          );
                        }
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (query) {
              if (_currentNewsList.isNotEmpty) {
                context.read<NewsCubit>().searchInCurrentList(
                  _currentNewsList,
                  query,
                );
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // ✅ Nguồn và Danh mục - LUÔN HIỂN THỊ
          _buildSourceAndCategoryRow(),
        ],
      ),
    );
  }

  Widget _buildSourceAndCategoryRow() {
    return BlocBuilder<NewsCubit, NewsState>(
      buildWhen: (previous, current) {
        // ✅ CHỈ rebuild khi load sources, KHÔNG rebuild khi load news
        return current is RssSourcesLoaded || current is RssSourcesLoading;
      },
      builder: (context, state) {
        final sources = state is RssSourcesLoaded
            ? state.sources
            : <RssSourceModel>[];

        return Row(
          children: [
            // Nguồn bên trái
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nguồn',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButton<RssSourceModel>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Chọn trang tin'),
                      value: _selectedSource,
                      items: sources.map((source) {
                        return DropdownMenuItem(
                          value: source,
                          child: Text(source.name),
                        );
                      }).toList(),
                      onChanged: (source) {
                        setState(() {
                          _selectedSource = source;
                          _selectedRssCategory = null;
                          _currentNewsList = [];
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Danh mục bên phải
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danh mục',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedSource != null
                          ? Colors.white
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedSource != null
                            ? Colors.grey[300]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: DropdownButton<RssCategoryModel>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: Text(
                        'Chọn danh mục',
                        style: TextStyle(
                          color: _selectedSource != null
                              ? Colors.black87
                              : Colors.grey[400],
                        ),
                      ),
                      value: _selectedRssCategory,
                      items: _selectedSource?.categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: _selectedSource != null
                          ? (cat) {
                              if (cat != null) {
                                setState(() {
                                  _selectedRssCategory = cat;
                                });

                                context.read<NewsCubit>().fetchFromRss(
                                  rssUrl: cat.rssUrl,
                                  sourceName: _selectedSource!.name,
                                  category: cat.name,
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewsList() {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state is RssSourcesLoading) {
          return _buildLoadingState('Đang tải danh sách nguồn...');
        } else if (state is ExternalNewsLoading) {
          return _buildLoadingState('Đang tải tin tức...');
        } else if (state is ExternalNewsLoaded) {
          if (_searchController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentNewsList = state.newsList;
                });
              }
            });
          }

          if (state.newsList.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNewsListView(state.newsList);
        } else if (state is NewsError) {
          return _buildErrorState(state.message);
        }

        return _buildInitialState();
      },
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '⏱️ Thời gian ước tính: 5-15 giây',
                  style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '📦 Tải 15 tin mới nhất',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Không có tin tức nào'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Có thể do:\n'
              '• Nguồn RSS không khả dụng\n'
              '• Proxy bị quá tải\n'
              '• Kết nối mạng chậm',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (_selectedRssCategory != null && _selectedSource != null) {
                  context.read<NewsCubit>().fetchFromRss(
                    rssUrl: _selectedRssCategory!.rssUrl,
                    sourceName: _selectedSource!.name,
                    category: _selectedRssCategory!.name,
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rss_feed, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chọn nguồn tin và danh mục\nđể bắt đầu',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsListView(List<ExternalNewsModel> newsList) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final news = newsList[index];
        return _buildNewsCard(news);
      },
    );
  }

  Widget _buildNewsCard(ExternalNewsModel news) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _onNewsSelected(news),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNewsImage(news.urlToImage),
              const SizedBox(width: 12),
              Expanded(child: _buildNewsContent(news)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 40),
              ),
            )
          : Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child: const Icon(Icons.article, size: 40),
            ),
    );
  }

  Widget _buildNewsContent(ExternalNewsModel news) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          news.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          news.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.source, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${news.source} • ${news.category}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
