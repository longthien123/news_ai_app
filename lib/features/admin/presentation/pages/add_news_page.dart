import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/news_cubit.dart';
import '../../data/models/external_news_model.dart';
import '../widgets/rss_picker_dialog.dart';

class AddNewsPage extends StatefulWidget {
  const AddNewsPage({Key? key}) : super(key: key);

  @override
  State<AddNewsPage> createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _sourceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final List<String> _imageUrls = [];
  String _selectedCategory = 'Tổng hợp';

  final List<String> _categories = [
    'Thể thao',
    'Chính trị',
    'Kinh tế',
    'Giải trí',
    'Công nghệ',
    'Sức khỏe',
    'Giáo dục',
    'Tổng hợp',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    context.read<NewsCubit>().resetToInitial();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _fillFromExternal(ExternalNewsModel item) {
    // ✅ Dùng toNewsData để chuyển đổi, nó sẽ lấy item.description (đã có nội dung từ webhook)
    final data = item.toNewsData(overrideSource: item.source);

    // Kiểm tra xem danh mục trả về có trong list không, nếu không thì dùng "Tổng hợp"
    String mappedCategory = data['category'] as String;
    if (!_categories.contains(mappedCategory)) {
      mappedCategory = 'Tổng hợp';
    }

    setState(() {
      _titleController.text = data['title'] as String;
      _contentController.text =
          data['content'] as String; // ✅ Điền nội dung hoặc lỗi từ webhook
      _selectedCategory = mappedCategory;
      _imageUrls.clear();
      final imgs = data['imageUrls'] as List<dynamic>;
      _imageUrls.addAll(imgs.map((e) => e.toString()));
      _sourceController.text = data['source'] as String;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã tải và điền thông tin từ ${item.source}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRssDialog() {
    context.read<NewsCubit>().loadRssSources();

    showDialog(
      context: context,
      builder: (dialogContext) => RssPickerDialog(onSelect: _fillFromExternal),
    );
  }

  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _imageUrls.add(url);
      _imageUrlController.clear();
    });
  }

  void _removeImageAt(int idx) {
    setState(() => _imageUrls.removeAt(idx));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 ảnh')),
      );
      return;
    }

    context.read<NewsCubit>().addNews(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      imageUrls: _imageUrls,
      category: _selectedCategory,
      source: _sourceController.text.isEmpty
          ? 'Không rõ'
          : _sourceController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm tin tức'),
        actions: [
          TextButton.icon(
            onPressed: _showRssDialog,
            icon: const Icon(Icons.flash_on, color: Colors.black),
            label: const Text(
              'Thêm nhanh',
              style: TextStyle(color: Colors.black),
            ),
          ),
          IconButton(onPressed: _submit, icon: const Icon(Icons.check)),
        ],
      ),
      body: BlocConsumer<NewsCubit, NewsState>(
        listener: (c, state) {
          if (state is NewsAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Thêm tin thành công')),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
          } else if (state is NewsError && state is! ExternalNewsLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (c, state) {
          if (state is NewsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    maxLines: 2,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nhập tiêu đề' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 8,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nhập nội dung' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Loại tin *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sourceController,
                    decoration: const InputDecoration(
                      labelText: 'Nguồn tin *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.source),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nhập nguồn tin' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL ảnh',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.image),
                          ),
                          onSubmitted: (_) => _addImageUrl(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addImageUrl,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_imageUrls.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ảnh minh họa (${_imageUrls.length}):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: _imageUrls.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final url = entry.value;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    url,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeImageAt(idx),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text('Thêm tin tức'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
