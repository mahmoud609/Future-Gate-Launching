import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Add_screens/Add_Internship.dart';
import 'edit_internship_dialog.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/HomeScreen';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> jobList = [];
  List<Map<String, dynamic>> filteredJobList = [];
  Set<String> savedInternshipIds = {};
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInternships();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      filteredJobList = jobList.where((job) {
        String title = (job['title'] ?? '').toString().toLowerCase();
        String company = (job['company'] ?? '').toString().toLowerCase();
        String location = (job['location'] ?? '').toString().toLowerCase();
        return title.contains(searchQuery) || company.contains(searchQuery) || location.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _fetchInternships() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot internSnapshot = await _firestore
          .collection('interns')
          .orderBy('timestamp', descending: true)
          .get();

      QuerySnapshot savedSnapshot = await _firestore
          .collection('Saved_Internships')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      List<Map<String, dynamic>> tempJobList = [];

      for (var doc in internSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data["id"] = doc.id;

        String? companyId = data["companyId"];

        if (companyId != null && companyId.isNotEmpty) {
          try {
            DocumentSnapshot companyDoc = await _firestore
                .collection('company')
                .doc(companyId)
                .get();

            if (companyDoc.exists) {
              var companyData = companyDoc.data() as Map<String, dynamic>;
              data["company"] = companyData["CompanyName"] ?? "Unknown Company";
            } else {
              data["company"] = "Unknown Company";
            }

            data["companyId"] = companyId;
          } catch (e) {
            print("Error fetching company data: $e");
            data["company"] = "Unknown Company";
          }
        } else {
          data["company"] = data["company"] ?? "Unknown Company";
        }

        tempJobList.add(data);
      }

      setState(() {
        jobList = tempJobList;
        filteredJobList = List.from(jobList);
        savedInternshipIds = savedSnapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['internshipId'] as String)
            .toSet();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching internships: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshInternships() async {
    await _fetchInternships();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            SizedBox(height: 8), // Reduced from 16 to 8
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Available Internships",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredJobList.isEmpty
                  ? _buildEmptyState()
                  : _buildInternshipsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: Color(0xFF172B4D)),
          decoration: InputDecoration(
            hintText: "Search internships",
            hintStyle: TextStyle(color: Color(0xFF8993A4)),
            prefixIcon: Icon(Icons.search, color: Color(0xFF5E6C84)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Color(0xFF5E6C84)),
              onPressed: () {
                _searchController.clear();
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
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
            Icons.search_off,
            size: 80,
            color: Color(0xFFDFE1E6),
          ),
          SizedBox(height: 16),
          Text(
            "No internships found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5E6C84),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Try adjusting your search or add a new one",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8993A4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternshipsList() {
    return RefreshIndicator(
      onRefresh: _refreshInternships,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: filteredJobList.length,
        itemBuilder: (context, index) {
          var job = filteredJobList[index];
          bool isSaved = savedInternshipIds.contains(job["id"]);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildJobCard(job, isSaved),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, bool isSaved) {
    String internshipId = job["id"];
    final companyInitial = (job["company"]?.toString().isNotEmpty ?? false)
        ? job["company"].toString()[0].toUpperCase()
        : "C";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              // Handle internship selection
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: _fetchCompanyProfile(job["companyId"]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              ),
                            );
                          }
                          final hasError = snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty ||
                              snapshot.data!['img_url'] == null ||
                              (snapshot.data!['img_url'] as String).isEmpty;

                          if (hasError) {
                            return Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2684FF), Color(0xFF0052CC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  companyInitial,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(snapshot.data!['img_url']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job["title"] ?? "Unknown Title",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF172B4D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              job["company"] ?? "Unknown Company",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5E6C84),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          popupMenuTheme: PopupMenuThemeData(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            color: Colors.white,
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Color(0xFF5E6C84)),
                          offset: Offset(0, 40),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditInternshipScreen(
                                    internshipData: job,
                                    internshipId: internshipId,
                                    onUpdate: () {
                                      _fetchInternships();
                                    },
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(internshipId);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Container(
                                width: 170,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFDEEBFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF0052CC),
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Color(0xFF172B4D),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Container(
                                width: 170,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFEBE6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFDE350B),
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Color(0xFF172B4D),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFF5E6C84), size: 16),
                      SizedBox(width: 4),
                      Text(
                        job["location"] ?? "Unknown Location",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5E6C84),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTag(job["type"] ?? "Unknown Type"),
                      SizedBox(width: 8),
                      _buildTag(job["internship"] ?? "Unknown Type"),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchCompanyProfile(String? companyId) async {
    if (companyId == null || companyId.isEmpty) {
      return {};
    }

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('companies_profile')
          .select()
          .eq('company_id', companyId)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      print('Error fetching company profile: $e');
      return {};
    }
  }

  Future<void> _toggleSaveInternship(String internshipId, bool isSaved) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      if (isSaved) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('Saved_Internships')
            .where('userId', isEqualTo: userId)
            .where('internshipId', isEqualTo: internshipId)
            .get();

        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }

        setState(() {
          savedInternshipIds.remove(internshipId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed from saved internships"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF5E6C84),
          ),
        );
      } else {
        await _firestore.collection('Saved_Internships').add({
          'userId': userId,
          'internshipId': internshipId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          savedInternshipIds.add(internshipId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Saved to your internships"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0052CC),
          ),
        );
      }
    } catch (e) {
      print("Error toggling save: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating saved status"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String internshipId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Delete Internship",
            style: TextStyle(
              color: Color(0xFF172B4D),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFEBE6),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.delete_forever_outlined,
                  color: Color(0xFFDE350B),
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Are you sure you want to delete this internship?",
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Color(0xFF5E6C84),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDE350B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                "Delete",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                _deleteInternship(internshipId);
                Navigator.of(context).pop();
              },
            ),
          ],
          actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 8),
        );
      },
    );
  }

  Future<void> _deleteInternship(String internshipId) async {
    try {
      await _firestore.collection('interns').doc(internshipId).delete();
      _fetchInternships();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Internship deleted successfully"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error deleting internship: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting internship"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFDEEBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFF0052CC),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddInternship()),
        ).then((_) => _fetchInternships());
      },
      backgroundColor: Color(0xFF2252A1),
      child: Icon(Icons.add, color: Colors.white),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}