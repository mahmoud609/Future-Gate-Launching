import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'AnalysisPage.dart';
import 'Job-Card.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = "/HomeScreen";
  final String companyid;

  const HomeScreen({Key? key, required this.companyid}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: HomePageContent(companyId: widget.companyid),
        ),
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  final String companyId;

  const HomePageContent({required this.companyId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(),
          actions: [
            SizedBox(width: 1),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(),
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF196AB3),
                  ),
                ),
                CompanyHeader(companyId: companyId),
                SizedBox(height: 5),
                _buildDashboardSummary(companyId),
                SizedBox(height: 18),
                _buildSectionHeader(
                  "Your Active Listings",
                  "Manage your internship positions",
                  Icons.work_outline_rounded,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 80),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              height: 400,
              child: JobsList(companyId: companyId),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return "Good Morning!";
    } else if (hour < 17) {
      return "Good Afternoon!";
    } else {
      return "Good Evening!";
    }
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF196AB3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFF196AB3),
                size: 15,
              ),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardSummary(String companyId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('interns')
          .where('companyId', isEqualTo: companyId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final internshipDocs = snapshot.data!.docs;
        final internshipIds = internshipDocs.map((doc) => doc.id).toList();
        final totalJobs = internshipIds.length;

        if (internshipIds.isEmpty) {
          return _buildDashboardContainer(totalJobs, 0, 0, context);
        }

        return FutureBuilder<List<QuerySnapshot>>(
          future: Future.wait([
            FirebaseFirestore.instance
                .collection('Student_Applicant')
                .where('internshipId', whereIn: internshipIds.length > 10 ? internshipIds.sublist(0, 10) : internshipIds)
                .where('status', isEqualTo: 'pending')
                .get(),
            FirebaseFirestore.instance
                .collection('Student_Applicant')
                .where('internshipId', whereIn: internshipIds.length > 10 ? internshipIds.sublist(0, 10) : internshipIds)
                .where('status', isEqualTo: 'accepted')
                .get(),
          ]),
          builder: (context, applicantSnapshot) {
            if (!applicantSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final pendingApplicants = applicantSnapshot.data![0].docs.length;
            final acceptedApplicants = applicantSnapshot.data![1].docs.length;

            return _buildDashboardContainer(totalJobs, pendingApplicants, acceptedApplicants, context);
          },
        );
      },
    );
  }

  Widget _buildDashboardContainer(int totalJobs, int pending, int accepted, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF196AB3), Color(0xFF1977C9)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF196AB3).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dashboard Summary",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Total Jobs", totalJobs.toString()),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem("Pending Applicants", pending.toString()),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem("Accepted", accepted.toString()),
            ],
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsDashboard(companyId: companyId)),
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "View Full Analytics",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class CompanyHeader extends StatelessWidget {
  final String companyId;
  final SupabaseClient supabase = Supabase.instance.client;

  CompanyHeader({required this.companyId});

  Future<Map<String, String>> _fetchCompanyData() async {
    try {
      final firebaseDoc = await FirebaseFirestore.instance
          .collection('company')
          .doc(companyId)
          .get();

      final companyName = firebaseDoc['CompanyName'] ?? "Company";

      final response = await supabase
          .from('companies_profile')
          .select('img_url')
          .eq('company_id', companyId)
          .maybeSingle();

      final photoUrl = response?['img_url'] ?? "";

      return {
        'name': companyName,
        'photoUrl': photoUrl,
      };
    } on PostgrestException catch (e) {
      print("Supabase error: $e");
      return {
        'name': "Company",
        'photoUrl': "",
      };
    } catch (e) {
      print("Error fetching company data: $e");
      return {
        'name': "Company",
        'photoUrl': "",
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _fetchCompanyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return Text(
            "Error loading company data",
            style: TextStyle(
              fontSize: 15,
              color: Colors.red,
            ),
          );
        }
        final companyName = snapshot.data?['name'] ?? "Company";
        final companyPhotoUrl = snapshot.data?['photoUrl'] ?? "";

        return Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (companyPhotoUrl.isNotEmpty)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      companyPhotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Color(0xFF196AB3).withOpacity(0.1),
                          child: Icon(Icons.business, size: 30, color: Color(0xFF196AB3)),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF196AB3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.business, size: 30, color: Color(0xFF196AB3)),
                ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Company Dashboard",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class JobsList extends StatelessWidget {
  final String companyId;

  const JobsList({required this.companyId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interns')
          .where('companyId', isEqualTo: companyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final jobData = snapshot.data!.docs;

        return ListView.separated(
          physics: BouncingScrollPhysics(),
          itemCount: jobData.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final jobDoc = jobData[index];
            final job = jobDoc.data() as Map<String, dynamic>;
            final jobId = jobDoc.id;

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Student_Applicant')
                  .where('internshipId', isEqualTo: jobId)
                  .where('status', isEqualTo: 'pending')
                  .get(),
              builder: (context, applicantSnapshot) {
                String pendingApplicants = "0";

                if (applicantSnapshot.hasData) {
                  pendingApplicants = applicantSnapshot.data!.docs.length.toString();
                }

                return ModernJobCard(
                  jobId: jobId,
                  title: job['title'] ?? "No Title",
                  location: job['location'] ?? "No Location",
                  duration: job['duration'] ?? "No Duration",
                  applicants: pendingApplicants,
                  type: job['type'] ?? "No Type",
                  createdAt: job['timestamp'] != null
                      ? (job['timestamp'] as Timestamp).toDate()
                      : DateTime.now(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 100,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.withOpacity(0.8),
          ),
          SizedBox(height: 16),
          Text(
            "Failed to load jobs",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF196AB3),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Try Again"),
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
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF196AB3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_off_outlined,
              size: 60,
              color: Color(0xFF196AB3),
            ),
          ),
          SizedBox(height: 24),
          Text(
            "No Jobs Posted Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Create your first job listing to attract talent",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.add),
            label: Text("Post a New Job"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF196AB3),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}