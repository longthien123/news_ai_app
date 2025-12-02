import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _viewsData = [];
  Map<String, int> _categoryData = {};
  String _selectedPeriod = '7days'; // 7days, 30days, all

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Xác định thời gian bắt đầu dựa trên period
      DateTime? startDate;
      if (_selectedPeriod == '7days') {
        startDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (_selectedPeriod == '30days') {
        startDate = DateTime.now().subtract(const Duration(days: 30));
      }

      // Lấy dữ liệu từ daily_views collection
      Query dailyViewsQuery = FirebaseFirestore.instance.collection(
        'daily_views',
      );

      if (startDate != null) {
        final startDateOnly = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        dailyViewsQuery = dailyViewsQuery.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDateOnly),
        );
      }

      final dailyViewsSnapshot = await dailyViewsQuery.get();

      // Tính toán dữ liệu: views theo ngày và views theo thể loại
      Map<DateTime, int> viewsByDate = {};
      Map<String, int> categoryViews = {};

      for (var doc in dailyViewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final viewCount = (data['viewCount'] ?? 0) as int;
        final category = data['category'] ?? 'Tổng hợp';

        // Nhóm views theo ngày
        final dateOnly = DateTime(date.year, date.month, date.day);
        viewsByDate[dateOnly] = (viewsByDate[dateOnly] ?? 0) + viewCount;

        // Nhóm views theo thể loại
        categoryViews[category] = (categoryViews[category] ?? 0) + viewCount;
      }

      // Tạo list các ngày liên tiếp trong khoảng thời gian
      List<Map<String, dynamic>> viewsList = [];
      if (startDate != null) {
        final endDate = DateTime.now();
        DateTime currentDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );

        while (currentDate.isBefore(endDate) ||
            currentDate.isAtSameMomentAs(
              DateTime(endDate.year, endDate.month, endDate.day),
            )) {
          final count = viewsByDate[currentDate] ?? 0;
          viewsList.add({
            'date': DateFormat('dd/MM').format(currentDate),
            'views': count,
          });
          currentDate = currentDate.add(const Duration(days: 1));
        }
      } else {
        // Nếu chọn "Tất cả", chỉ lấy các ngày có views
        viewsList = viewsByDate.entries
            .map(
              (e) => {
                'date': DateFormat('dd/MM').format(e.key),
                'views': e.value,
              },
            )
            .toList();
        viewsList.sort(
          (a, b) => a['date'].toString().compareTo(b['date'].toString()),
        );
      }

      setState(() {
        _viewsData = viewsList;
        _categoryData = categoryViews;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  // Hàm migrate dữ liệu từ news sang daily_views
  Future<void> _migrateOldData() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đang migrate dữ liệu...')));

      final newsSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .get();

      for (var newsDoc in newsSnapshot.docs) {
        final data = newsDoc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final views = data['views'] ?? 0;
        final category = data['category'] ?? 'Tổng hợp';

        if (views > 0) {
          final dateKey =
              '${createdAt.year}${createdAt.month.toString().padLeft(2, '0')}${createdAt.day.toString().padLeft(2, '0')}';
          final dailyDocId = '${dateKey}_${newsDoc.id}';
          final dateOnly = DateTime(
            createdAt.year,
            createdAt.month,
            createdAt.day,
          );

          await FirebaseFirestore.instance
              .collection('daily_views')
              .doc(dailyDocId)
              .set({
                'date': Timestamp.fromDate(dateOnly),
                'newsId': newsDoc.id,
                'category': category,
                'viewCount': views,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Migrate dữ liệu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStatistics();
      }
    } catch (e) {
      debugPrint('Error migrating data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi migrate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thống kê',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phân tích lượt xem theo ngày và thể loại',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Period filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: '7days',
                            child: Text('7 ngày'),
                          ),
                          DropdownMenuItem(
                            value: '30days',
                            child: Text('30 ngày'),
                          ),
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedPeriod = value!);
                          _loadStatistics();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _migrateOldData,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Migrate dữ liệu cũ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _loadStatistics,
                      tooltip: 'Làm mới',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Biểu đồ đường - Lượt xem theo thời gian
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.trending_up,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Lượt xem theo ngày',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: _viewsData.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có dữ liệu',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : _buildLineChart(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Biểu đồ cột - Thể loại được đọc nhiều nhất
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.bar_chart,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Thể loại được đọc nhiều nhất',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 350,
                        child: _categoryData.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có dữ liệu',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : _buildBarChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_viewsData.isEmpty) return const SizedBox();

    final maxY = _viewsData
        .map((e) => (e['views'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);

    // Đảm bảo maxY không bằng 0 để tránh lỗi interval
    final safeMaxY = maxY > 0 ? maxY : 10;
    final horizontalInterval = safeMaxY / 5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: horizontalInterval > 0 ? horizontalInterval : 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < _viewsData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _viewsData[value.toInt()]['date'].toString(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: horizontalInterval > 0 ? horizontalInterval : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (_viewsData.length - 1).toDouble(),
        minY: 0,
        maxY: safeMaxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: _viewsData.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['views'] as int).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue.shade600,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue.shade600,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.shade600.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.shade700,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final date = _viewsData[touchedSpot.x.toInt()]['date'];
                final count = touchedSpot.y.toInt();
                return LineTooltipItem(
                  '$date\n$count lượt xem',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_categoryData.isEmpty) return const SizedBox();

    // Sắp xếp theo số lượt xem giảm dần
    final sortedEntries = _categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxY = sortedEntries.first.value.toDouble();

    // Đảm bảo maxY không bằng 0
    final safeMaxY = maxY > 0 ? maxY : 10;
    final horizontalInterval = safeMaxY / 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: safeMaxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.shade700,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final category = sortedEntries[group.x.toInt()].key;
              final views = rod.toY.toInt();
              return BarTooltipItem(
                '$category\n$views lượt xem',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedEntries.length) {
                  final category = sortedEntries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval > 0 ? horizontalInterval : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        barGroups: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: categoryEntry.value.toDouble(),
                color: _getCategoryColor(categoryEntry.key),
                width: 30,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: safeMaxY * 1.2,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Thể thao':
        return Colors.green;
      case 'Chính trị':
      case 'Thời sự':
        return Colors.red;
      case 'Kinh tế':
      case 'Kinh doanh':
        return Colors.blue;
      case 'Giải trí':
        return Colors.pink;
      case 'Công nghệ':
      case 'Số hóa':
        return Colors.purple;
      case 'Sức khỏe':
        return Colors.teal;
      case 'Giáo dục':
        return Colors.indigo;
      case 'Du lịch':
        return Colors.cyan;
      case 'Thế giới':
        return Colors.deepOrange;
      default:
        return Colors.orange;
    }
  }
}
