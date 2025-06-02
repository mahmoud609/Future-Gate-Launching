import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StudentVsInternshipScreen extends StatefulWidget {
  const StudentVsInternshipScreen({Key? key}) : super(key: key);

  @override
  State<StudentVsInternshipScreen> createState() => _StudentVsInternshipScreenState();
}

class _StudentVsInternshipScreenState extends State<StudentVsInternshipScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedStatus = 'All';
  String selectedCvType = 'All';
  String selectedTimeRange = 'Last 30 Days';
  String selectedInternshipTitle = 'All';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
      begin: const Offset(0, 0.5),
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

  Stream<QuerySnapshot> _getStudentApplications() {
    Query query = _firestore.collection('Student_Applicant');

    // Apply filters
    if (selectedStatus != 'All') {
      query = query.where('status', isEqualTo: selectedStatus);
    }

    if (selectedCvType != 'All') {
      query = query.where('cvType', isEqualTo: selectedCvType);
    }

    if (selectedInternshipTitle != 'All') {
      query = query.where('internshipTitle', isEqualTo: selectedInternshipTitle);
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
      query = query.where('appliedAt', isGreaterThan: Timestamp.fromDate(startDate));
    }

    return query.orderBy('appliedAt', descending: true).snapshots();
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
                _buildStatisticsCards(),
                _buildChartsSection(),
                _buildApplicationsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
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
                Color(0xFF48c6ef),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Icon(
                  Icons.assignment_ind,
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Student Applications',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Real-time Applicant Analytics',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
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
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Student_Applicant').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildLoadingFilters();
          }

          final docs = snapshot.data!.docs;
          final statuses = _extractUniqueValues(docs, 'status');
          final cvTypes = _extractUniqueValues(docs, 'cvType');
          final internshipTitles = _extractUniqueValues(docs, 'internshipTitle');

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown('Status', selectedStatus, ['All', ...statuses], (value) {
                      setState(() => selectedStatus = value);
                    })),
                    SizedBox(width: 12),
                    Expanded(child: _buildFilterDropdown('CV Type', selectedCvType, ['All', ...cvTypes], (value) {
                      setState(() => selectedCvType = value);
                    })),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown('Position', selectedInternshipTitle, ['All', ...internshipTitles], (value) {
                      setState(() => selectedInternshipTitle = value);
                    })),
                    SizedBox(width: 12),
                    Expanded(child: _buildFilterDropdown('Time Range', selectedTimeRange, ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'All Time'], (value) {
                      setState(() => selectedTimeRange = value);
                    })),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _extractUniqueValues(List<QueryDocumentSnapshot> docs, String field) {
    final values = docs
        .map((doc) => (doc.data() as Map<String, dynamic>)[field])
        .whereType<String>() // فقط القيم اللي هي String
        .where((value) => value.isNotEmpty) // استبعاد الفارغين
        .toSet()
        .toList();

    values.sort();
    return values;
  }


  Widget _buildFilterDropdown(String label, String selected, List<String> options, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonFormField<String>(
        value: options.contains(selected) ? selected : 'All',
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        dropdownColor: Color(0xFF1A1A2E),
        style: TextStyle(color: Colors.white, fontSize: 14),
        isExpanded: true,
        items: options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(
            option,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13),
          ),
        )).toList(),
        onChanged: (value) => onChanged(value!),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: _getStudentApplications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingCards();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;
          final totalApplications = docs.length;
          final statusStats = _getStatusStatistics(docs);
          final cvTypeStats = _getCvTypeStatistics(docs);
          final uniqueApplicants = _getUniqueApplicants(docs);

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
                _buildStatCard('Total Applications', totalApplications.toString(), Icons.assignment, Color(0xFF667eea)),
                _buildStatCard('Unique Applicants', uniqueApplicants.toString(), Icons.people, Color(0xFF764ba2)),
                _buildStatCard('Pending Review', statusStats['pending']?.toString() ?? '0', Icons.hourglass_empty, Color(0xFF48c6ef)),
                _buildStatCard('Built CVs', cvTypeStats['built']?.toString() ?? '0', Icons.build, Color(0xFF6a11cb)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
        stream: _getStudentApplications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SizedBox.shrink();
          }

          final docs = snapshot.data!.docs;
          return Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Status Distribution Chart
                _buildChartContainer(
                  'Application Status Distribution',
                  _buildStatusPieChart(docs),
                ),
                SizedBox(height: 16),
                // Applications Timeline
                _buildChartContainer(
                  'Applications Over Time',
                  _buildTimelineChart(docs),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
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
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart(List<QueryDocumentSnapshot> docs) {
    final statusStats = _getStatusStatistics(docs);
    final colors = [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF48c6ef), Color(0xFF6a11cb)];

    return PieChart(
      PieChartData(
        sections: statusStats.entries.map((entry) {
          final index = statusStats.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.key}\n${entry.value}',
            color: colors[index % colors.length],
            radius: 80,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildTimelineChart(List<QueryDocumentSnapshot> docs) {
    final timelineData = _getTimelineData(docs);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: timelineData,
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

  Widget _buildApplicationsList() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Applications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _getStudentApplications(),
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
                    return _buildApplicationCard(data);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'Unknown';
    final internshipTitle = data['internshipTitle'] ?? 'Unknown Position';
    final email = data['email'] ?? 'No Email';
    final cvType = data['cvType'] ?? 'Unknown';
    final appliedAt = data['appliedAt'] as Timestamp?;

    Color statusColor = _getStatusColor(status);

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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.8), statusColor.withOpacity(0.6)],
                ),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    internshipTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: statusColor.withOpacity(0.2),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blue.withOpacity(0.2),
                        ),
                        child: Text(
                          cvType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (appliedAt != null) ...[
                    SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy - HH:mm').format(appliedAt.toDate()),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'accepted':
        return Colors.green;
      case 'rejected':
      case 'declined':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Map<String, int> _getStatusStatistics(List<QueryDocumentSnapshot> docs) {
    final stats = <String, int>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'Unknown';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> _getCvTypeStatistics(List<QueryDocumentSnapshot> docs) {
    final stats = <String, int>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cvType = data['cvType']?.toString() ?? 'Unknown';
      stats[cvType] = (stats[cvType] ?? 0) + 1;
    }
    return stats;
  }

  int _getUniqueApplicants(List<QueryDocumentSnapshot> docs) {
    final uniqueEmails = <String>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final email = data['email']?.toString();
      if (email != null && email.isNotEmpty) {
        uniqueEmails.add(email);
      }
    }
    return uniqueEmails.length;
  }

  List<FlSpot> _getTimelineData(List<QueryDocumentSnapshot> docs) {
    final dailyApplications = <String, int>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final appliedAt = data['appliedAt'] as Timestamp?;
      if (appliedAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(appliedAt.toDate());
        dailyApplications[dateKey] = (dailyApplications[dateKey] ?? 0) + 1;
      }
    }

    final sortedDates = dailyApplications.keys.toList()..sort();
    return sortedDates.take(7).map((date) {
      final index = sortedDates.indexOf(date).toDouble();
      final count = dailyApplications[date]!.toDouble();
      return FlSpot(index, count);
    }).toList();
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

  Widget _buildLoadingFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildShimmerFilter()),
              SizedBox(width: 12),
              Expanded(child: _buildShimmerFilter()),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildShimmerFilter()),
              SizedBox(width: 12),
              Expanded(child: _buildShimmerFilter()),
            ],
          ),
        ],
      ),
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

  Widget _buildShimmerFilter() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFF1A1A2E),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
            'No applications found',
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