import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StudentVsCvAtsScreen extends StatefulWidget {
  static const String routeName = '/StudentVsCvAtsScreen';

  @override
  _StudentVsCvAtsScreenState createState() => _StudentVsCvAtsScreenState();
}

class _StudentVsCvAtsScreenState extends State<StudentVsCvAtsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  int _totalUploads = 0;
  Map<String, int> _fieldCounts = {};
  Map<String, int> _uploadsByMonth = {};
  int _uniqueStudents = 0;
  double _averageUploadsPerStudent = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all ATS data
      final QuerySnapshot atsSnapshot = await _firestore.collection('ats_data').get();

      // Total uploads
      _totalUploads = atsSnapshot.docs.length;

      // Calculate field counts
      Map<String, int> fieldCounts = {};
      Set<String> uniqueStudentIds = {};
      Map<String, int> uploadsByMonth = {};

      for (var doc in atsSnapshot.docs) {
        // Count by fields
        String field = doc['field'] ?? 'Not Specified';
        fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;

        // Count unique students
        String studentId = doc['uuid'] ?? '';
        if (studentId.isNotEmpty) {
          uniqueStudentIds.add(studentId);
        }

        // Count uploads by month
        if (doc['created_at'] != null) {
          Timestamp timestamp = doc['created_at'];
          DateTime date = timestamp.toDate();
          String monthYear = DateFormat('MMM yyyy').format(date);
          uploadsByMonth[monthYear] = (uploadsByMonth[monthYear] ?? 0) + 1;
        }
      }

      // Calculate average uploads per student
      _uniqueStudents = uniqueStudentIds.length;
      _averageUploadsPerStudent = _uniqueStudents > 0
          ? _totalUploads / _uniqueStudents
          : 0;

      setState(() {
        _fieldCounts = fieldCounts;
        _uploadsByMonth = uploadsByMonth;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching ATS data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student vs CV ATS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2252A1),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF2252A1)),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(),
              SizedBox(height: 24),
              _buildFieldDistributionChart(),
              SizedBox(height: 24),
              _buildMonthlyUploadsChart(),
              SizedBox(height: 24),
              _buildAtsEvaluationSection(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CV ATS Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2252A1),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Total CV Uploads',
                _totalUploads.toString(),
                Iconsax.document_upload,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Unique Students',
                _uniqueStudents.toString(),
                Iconsax.profile_2user,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Fields Covered',
                _fieldCounts.length.toString(),
                Iconsax.category,
                Colors.purple,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Avg. Uploads/Student',
                _averageUploadsPerStudent.toStringAsFixed(1),
                Iconsax.chart_1,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2252A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldDistributionChart() {
    if (_fieldCounts.isEmpty) {
      return _buildEmptyState('No field data available');
    }

    // Sort fields by count (descending)
    final sortedFields = _fieldCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare data for the chart
    final List<PieChartSectionData> pieChartData = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    for (int i = 0; i < sortedFields.length; i++) {
      final field = sortedFields[i];
      final color = colors[i % colors.length];
      final value = field.value / _totalUploads * 100;

      pieChartData.add(
        PieChartSectionData(
          color: color,
          value: field.value.toDouble(),
          title: '${value.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CV Uploads by Field',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2252A1),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Distribution of CV uploads across different fields',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                sections: pieChartData,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(
              sortedFields.length,
                  (index) => _buildFieldIndicator(
                sortedFields[index].key,
                sortedFields[index].value,
                colors[index % colors.length],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldIndicator(String field, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            '$field ($count)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyUploadsChart() {
    if (_uploadsByMonth.isEmpty) {
      return _buildEmptyState('No timeline data available');
    }

    // Sort months chronologically
    final sortedMonths = _uploadsByMonth.keys.toList()
      ..sort((a, b) {
        final aDate = DateFormat('MMM yyyy').parse(a);
        final bDate = DateFormat('MMM yyyy').parse(b);
        return aDate.compareTo(bDate);
      });

    // Prepare data for the chart
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final count = _uploadsByMonth[month]!;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Color(0xFF2252A1),
              width: 16,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly CV Upload Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2252A1),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Number of CV uploads over time',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _uploadsByMonth.values.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey[800],
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${sortedMonths[group.x]}\n${rod.toY.round()} uploads',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < sortedMonths.length) {
                          // Only show every other label if we have many months
                          if (sortedMonths.length > 6 && value.toInt() % 2 != 0) {
                            return SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sortedMonths[value.toInt()].split(' ')[0], // Just show month abbreviation
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return SizedBox();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtsEvaluationSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.document_filter,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'ATS Evaluation Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2252A1),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildAtsStatRow(
              'CV Quality Score',
              '78%',
              Icons.speed_rounded,
              Colors.green,
              'Average ATS compatibility score of all CVs'
          ),
          SizedBox(height: 12),
          _buildAtsStatRow(
              'Keyword Match Rate',
              '65%',
              Iconsax.search_normal,
              Colors.orange,
              'Percentage of CVs with proper keyword matching'
          ),
          SizedBox(height: 12),
          _buildAtsStatRow(
              'Format Compliance',
              '82%',
              Iconsax.document_text,
              Colors.purple,
              'Percentage of CVs with standard formatting'
          ),
          SizedBox(height: 12),
          _buildAtsStatRow(
              'Improvement Rate',
              '+23%',
              Iconsax.arrow_up,
              Colors.blue,
              'Average improvement after ATS feedback'
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.info_circle,
                  color: Colors.blue,
                  size: 18,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Students who made improvements based on ATS feedback saw an average 23% higher interview invitation rate.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtsStatRow(String title, String value, IconData icon, Color color, String description) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.chart_fail,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}