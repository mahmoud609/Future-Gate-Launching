import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryScreen extends StatefulWidget {
  final String companyid;

  const HistoryScreen({Key? key, required this.companyid}) : super(key: key);
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  String? companyId;
  String? companyName;
  List<String> internshipIds = [];
  bool isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      companyId = widget.companyid; // استخدام الـ ID المرسل
    });

    await _getCompanyNameById(companyId!); // بديل لـ _getCompanyNameByEmail

    if (companyId != null) {
      print("🔐 Retrieved companyId = $companyId");
      await _fetchInternshipIds();
    } else {
      print("❌ Failed to get companyId");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getCompanyNameById(String companyId) async {
    try {
      final doc = await _firestore.collection('company').doc(companyId).get();

      if (doc.exists) {
        setState(() {
          companyName = doc['CompanyName'];
        });
        print("🏢 Company Name: $companyName");
      } else {
        print("❌ No company found with ID: $companyId");
      }
    } catch (e) {
      print("🔥 Error getting company name by ID: $e");
    }
  }


  Future<void> _fetchInternshipIds() async {
    if (companyId == null) return;

    try {
      final snapshot = await _firestore
          .collection('interns')
          .where('companyId', isEqualTo: companyId)
          .get();

      internshipIds = snapshot.docs.map((doc) => doc.id).toList();
      print("✅ Internships Found: ${internshipIds.length}");
      for (var doc in snapshot.docs) {
        print("🎓 Internship Loaded: ${doc['title']}");
        print("🔑 Internship ID: ${doc.id}");
      }
    } catch (e) {
      print('❌ Error fetching internships: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _initData();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF196AB3), Color(0xFF1977C9)],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Accepted Interns',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF196AB3), Color(0xFF1977C9)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 30),
                      Icon(
                        Icons.business_center,
                        color: Colors.white.withOpacity(0.8),
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        companyName ?? 'Unknown Company',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Accepted Interns',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF196AB3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        '${internshipIds.length} Internships',
                        style: TextStyle(
                          color: Color(0xFF196AB3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            internshipIds.isEmpty
                ? SliverFillRemaining(
              child: _buildEmptyState(),
            )
                : _buildInternsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 86,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No accepted interns yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When students are accepted, they will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Student_Applicant')
          .where('status', isEqualTo: 'accepted')
          .where('internshipId', whereIn: internshipIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final application = snapshot.data!.docs[index];
                final userId = application['userId'];
                final internshipId = application['internshipId'];

                return FutureBuilder(
                  future: Future.wait([
                    _getInternshipDetails(internshipId),
                    _getStudentDetails(userId), // تم التعديل هنا
                    _getStudentProfileImage(userId),
                  ]),
                  builder: (context, AsyncSnapshot<List<dynamic>> combinedSnapshot) {
                    if (combinedSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildSkeletonCard();
                    }

                    if (combinedSnapshot.hasError) {
                      return _buildErrorCard(combinedSnapshot.error.toString());
                    }

                    final internshipData = combinedSnapshot.data![0] as Map<String, dynamic>?;
                    final studentData = combinedSnapshot.data![1] as Map<String, dynamic>?;
                    final imageUrl = combinedSnapshot.data![2] as String?;

                    return _buildInternCard(
                      studentName: studentData?['firstName'] ?? 'Unknown Student', // استخدم الاسم من users
                      position: internshipData?['title'] ?? 'Unknown Position',
                      appliedDate: application['appliedAt']?.toDate() ?? DateTime.now(),
                      imageUrl: imageUrl,
                      university: studentData?['university'] ?? 'University not specified',
                    );
                  },
                );
              },
              childCount: snapshot.data!.docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 180,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 80,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Error loading data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternCard({
    required String studentName,
    required String position,
    required DateTime appliedDate,
    String? imageUrl,
    required String university,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to student details
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.work_outline, size: 14, color: Color(0xFF196AB3)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            position,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            university,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF196AB3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Accepted',
                            style: TextStyle(
                              color: Color(0xFF196AB3),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          'Applied: ${_formatDate(appliedDate)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get internship details
  Future<Map<String, dynamic>?> _getInternshipDetails(String internshipId) async {
    try {
      final doc = await _firestore.collection('interns').doc(internshipId).get();
      return doc.data();
    } catch (e) {
      print('Error getting internship details: $e');
      return null;
    }
  }
  Future<Map<String, dynamic>?> _getStudentDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      return userDoc.data();
    } else {
      return null;
    }
  }




  // Get student profile image
  Future<String?> _getStudentProfileImage(String userId) async {
    try {
      final response = await _supabase
          .from('profile_images')
          .select('image_url')
          .eq('user_id', userId)
          .single();

      return response['image_url'];
    } catch (e) {
      print('Error getting profile image: $e');
      return null;
    }
  }
}