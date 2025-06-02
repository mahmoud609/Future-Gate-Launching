import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsDashboard extends StatefulWidget {
  final String companyId;

  const AnalyticsDashboard({Key? key, required this.companyId}) : super(key: key);

  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  int totalApplications = 0;
  int totalInterns = 0;
  int pendingApplications = 0;

  Map<String, int> applicationsByStatus = {};
  Map<String, int> internsByField = {};
  List<Map<String, dynamic>> recentApplications = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnalyticsData();
  }

  Future<void> fetchAnalyticsData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        fetchApplicationCounts(), // Get accurate counts first
        fetchStudentApplications(), // Get recent applications for display
        fetchInterns(),
      ]);
    } catch (e) {
      print('Error fetching analytics data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchApplicationCounts() async {
    try {
      // Step 1: Get all Student_Applicant documents
      QuerySnapshot applicantSnapshot = await _firestore
          .collection('Student_Applicant')
          .get();

      int total = 0;
      int pending = 0;
      Map<String, int> statusCounts = {};

      for (var doc in applicantSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? internshipId = data['internshipId'];
        String? status = data['status']?.toString() ?? 'unknown';

        if (internshipId == null) continue;

        // Step 2: Get corresponding internship document
        DocumentSnapshot internshipDoc = await _firestore
            .collection('interns')
            .doc(internshipId)
            .get();

        if (!internshipDoc.exists) continue;

        Map<String, dynamic> internshipData =
        internshipDoc.data() as Map<String, dynamic>;
        String? companyId = internshipData['companyId'];

        // Step 3: Compare with current company's ID
        if (companyId == widget.companyId) {
          total++;

          // Count pending
          if (status == 'pending') pending++;

          // Count all statuses
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
      }

      setState(() {
        totalApplications = total;
        pendingApplications = pending;
        applicationsByStatus = statusCounts;
      });
    } catch (e) {
      print('Error fetching application counts: $e');
    }
  }


  Future<String> _getProfilePhotoUrl(String userId) async {
    try {
      final response = await _supabase
          .from('profile_images')
          .select('image_url')
          .eq('user_id', userId)
          .maybeSingle(); // Use maybeSingle() instead of single() to handle no results

      if (response != null && response['image_url'] != null) {
        final imagePath = response['image_url'] as String;

        if (imagePath.startsWith('http')) {
          return imagePath;
        } else {
          // Construct the public URL properly
          return _supabase.storage
              .from('profile-images')
              .getPublicUrl(imagePath);
        }
      }
    } catch (e) {
      print('Error fetching photo for user $userId: $e');
    }

    return ''; // Return empty string if no photo found
  }

  Future<void> fetchStudentApplications() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Student_Applicant')
          .where('companyId', isEqualTo: widget.companyId)
          .orderBy('appliedAt', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> detailedApplications = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String userId = data['userId'] ?? '';

        // Get user info
        DocumentSnapshot userSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        String fullName = data['email'] ?? 'Unknown';
        String photoUrl = '';

        if (userSnapshot.exists) {
          final userData = userSnapshot.data() as Map<String, dynamic>;
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';

          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            fullName = '$firstName $lastName';
          }

          // Get photo URL
          photoUrl = await _getProfilePhotoUrl(userSnapshot.id);
        }

        detailedApplications.add({
          'applicationId': doc.id,
          'fullName': fullName,
          'photoUrl': photoUrl,
          'email': data['email'] ?? 'N/A',
          'status': data['status'] ?? 'pending',
          'appliedAt': data['appliedAt'],
          'uploadMethod': data['uploadMethod'] ?? 'N/A',
          'nationalId': data['nationalId'] ?? 'N/A',
          'gpa': data['gpa']?.toString() ?? 'N/A',
        });
      }

      setState(() {
        recentApplications = detailedApplications;
      });
    } catch (e) {
      print('Error fetching applications: $e');
    }
  }

  Future<void> fetchInterns() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('interns')
          .where('companyId', isEqualTo: widget.companyId)
          .get();

      Map<String, int> fieldCounts = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String field = data['field'] ?? 'Other';
        fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
      }

      setState(() {
        totalInterns = snapshot.docs.length;
        internsByField = fieldCounts;
      });
    } catch (e) {
      print('Error fetching interns: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Internship Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF2252A1),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2252A1),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2252A1)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF2252A1)),
            onPressed: fetchAnalyticsData,
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2252A1)),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchAnalyticsData,
        color: Color(0xFF2252A1),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Applications',
                      totalApplications.toString(),
                      Icons.description,
                      Color(0xFF2252A1),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active Interns',
                      totalInterns.toString(),
                      Icons.person,
                      Color(0xFF2252A1),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pending Applications',
                      pendingApplications.toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(), // Empty container for spacing
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Application Status Chart
              Text(
                'Application Status Distribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2252A1),
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 300,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF2252A1).withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2252A1).withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: applicationsByStatus.isNotEmpty
                    ? PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(applicationsByStatus),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                  ),
                )
                    : Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: Color(0xFF2252A1)),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Interns by Field Chart
              Text(
                'Interns by Field',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2252A1),
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 300,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF2252A1).withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2252A1).withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: internsByField.isNotEmpty
                    ? BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: internsByField.values.isNotEmpty
                        ? internsByField.values.reduce((a, b) => a > b ? a : b).toDouble() + 1
                        : 1,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Color(0xFF2252A1),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            List<String> fields = internsByField.keys.toList();
                            if (value.toInt() < fields.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  fields[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF2252A1),
                                  ),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildBarGroups(internsByField),
                  ),
                )
                    : Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: Color(0xFF2252A1)),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Recent Applications
              Text(
                'Recent Applications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2252A1),
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF2252A1).withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2252A1).withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: recentApplications.isNotEmpty
                    ? ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: recentApplications.length,
                  itemBuilder: (context, index) {
                    var application = recentApplications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: application['photoUrl'].isNotEmpty
                            ? Colors.transparent
                            : _getStatusColor(application['status']),
                        child: application['photoUrl'].isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            application['photoUrl'],
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, color: Colors.white, size: 20);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return CircularProgressIndicator(strokeWidth: 2);
                            },
                          ),
                        )
                            : Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        application['fullName'],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2252A1),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application['email'],
                            style: TextStyle(color: Color(0xFF2252A1).withOpacity(0.7)),
                          ),
                          Text(
                            application['uploadMethod'],
                            style: TextStyle(color: Color(0xFF2252A1).withOpacity(0.7)),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(application['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          application['status'].toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(application['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                )
                    : Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No recent applications',
                      style: TextStyle(color: Color(0xFF2252A1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF2252A1).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2252A1).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2252A1),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2252A1).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> data) {
    List<Color> colors = [
      Color(0xFF2252A1),
      Color(0xFF2252A1).withOpacity(0.8),
      Color(0xFF2252A1).withOpacity(0.6),
      Colors.orange,
      Colors.red,
      Colors.green,
    ];

    int index = 0;
    return data.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 100,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, int> data) {
    int index = 0;
    return data.entries.map((entry) {
      final barGroup = BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Color(0xFF2252A1),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
      index++;
      return barGroup;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}