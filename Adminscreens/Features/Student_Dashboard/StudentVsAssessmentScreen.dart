import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StudentVsAssessmentScreen extends StatefulWidget {
  const StudentVsAssessmentScreen({Key? key}) : super(key: key);

  @override
  State<StudentVsAssessmentScreen> createState() => _StudentVsAssessmentScreenState();
}

class _StudentVsAssessmentScreenState extends State<StudentVsAssessmentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedFilter = 'All';
  String selectedTimeRange = 'Last 30 Days';
  String selectedLevel = 'All';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getAssessmentResults() {
    Query query = _firestore.collection('Assessment_result');

    // Apply filters
    if (selectedLevel != 'All') {
      query = query.where('level', isEqualTo: selectedLevel);
    }

    // Apply time range filter
    if (selectedTimeRange != 'All Time') {
      DateTime startDate;
      switch (selectedTimeRange) {
        case 'Last 7 Days':
          startDate = DateTime.now().subtract(Duration(days: 7));
          break;
        case 'Last 30 Days':
          startDate = DateTime.now().subtract(Duration(days: 30));
          break;
        case 'Last 3 Months':
          startDate = DateTime.now().subtract(Duration(days: 90));
          break;
        default:
          startDate = DateTime.now().subtract(Duration(days: 30));
      }
      query = query.where('timestamp', isGreaterThan: Timestamp.fromDate(startDate));
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildFilters(),
                _buildAnalyticsCards(),
                _buildChartsSection(),
                _buildRecentAssessments(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  'Assessment Analytics',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Real-time Performance Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildFilterChip('Level', selectedLevel, ['All', 'Beginner', 'Intermediate', 'Advanced'], (value) {
              setState(() => selectedLevel = value);
            })),
            SizedBox(width: 12),
            Expanded(child: _buildFilterChip('Time', selectedTimeRange, ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'All Time'], (value) {
              setState(() => selectedTimeRange = value);
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonFormField<String>(
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: Color(0xFF1A1A2E),
        style: TextStyle(color: Colors.white),
        items: options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(option),
        )).toList(),
        onChanged: (value) => onChanged(value!),
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: _getAssessmentResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingCards();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;
          final totalAssessments = docs.length;

          double avgScore = 0.0;
          int totalQuestions = 0;
          int totalCorrect = 0;

          for (var doc in docs) {
            // حساب الدرجة
            final rawPercentage = doc['percentage'];
            final percentage = rawPercentage is num
                ? rawPercentage.toDouble()
                : double.tryParse(rawPercentage.toString()) ?? 0.0;
            avgScore += percentage;

            // عدد الأسئلة
            final rawQuestions = doc['totalQuestions'];
            final questions = rawQuestions is int
                ? rawQuestions
                : int.tryParse(rawQuestions.toString()) ?? 0;
            totalQuestions += questions;

            // عدد الإجابات الصحيحة
            final rawCorrect = doc['totalCorrectAnswers'];
            final correct = rawCorrect is int
                ? rawCorrect
                : int.tryParse(rawCorrect.toString()) ?? 0;
            totalCorrect += correct;
          }

          avgScore = avgScore / (totalAssessments == 0 ? 1 : totalAssessments);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildAnalyticsCard('Total Assessments', totalAssessments.toString(), Icons.quiz, Color(0xFF667eea)),
                _buildAnalyticsCard('Average Score', '${avgScore.toStringAsFixed(1)}%', Icons.trending_up, Color(0xFF764ba2)),
                _buildAnalyticsCard('Total Questions', totalQuestions.toString(), Icons.help_outline, Color(0xFF48c6ef)),
                _buildAnalyticsCard('Correct Answers', totalCorrect.toString(), Icons.check_circle, Color(0xFF6a11cb)),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: _getAssessmentResults(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: _buildPerformanceChart(snapshot.data!.docs),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceChart(List<QueryDocumentSnapshot> docs) {
    final chartData = docs.take(7).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return FlSpot(
        docs.indexOf(doc).toDouble(),
        (data['percentage'] ?? 0).toDouble(),
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: true,
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Color(0xFF667eea),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF667eea).withOpacity(0.3),
                  Color(0xFF764ba2).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAssessments() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Assessments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _getAssessmentResults(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingList();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildAssessmentCard(data);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> data) {
    final percentage = data['percentage'] ?? 0;
    final assessmentName = data['assessmentName'] ?? 'Unknown Assessment';
    final level = data['level'] ?? 'Unknown';
    final totalQuestions = data['totalQuestions'] ?? 0;
    final correctAnswers = data['totalCorrectAnswers'] ?? 0;
    final timestamp = data['timestamp'] as Timestamp?;

    Color scoreColor;
    if (percentage >= 80) {
      scoreColor = Colors.green;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scoreColor.withOpacity(0.8), scoreColor.withOpacity(0.6)],
                ),
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assessmentName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _getLevelColor(level).withOpacity(0.2),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getLevelColor(level),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '$correctAnswers/$totalQuestions correct',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  if (timestamp != null) ...[
                    SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy - HH:mm').format(timestamp.toDate()),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildLoadingCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: List.generate(4, (index) => _buildShimmerCard()),
      ),
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(3, (index) => _buildShimmerListItem()),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF1A1A2E),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildShimmerListItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF1A1A2E),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
            'No assessments found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}