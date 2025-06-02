import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart'; // Add this package for loading effects
import 'package:intl/intl.dart'; // Add this package for date formatting
import '../details/internship_details_screen.dart';
import 'chatbot/chat_bot_screen.dart';
import 'dart:math';


class HomeScreen extends StatefulWidget {
  static const String routeName = '/HomeScreen';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> jobList = [];
  String _searchQuery = "";
  bool _isLoading = true;
  late AnimationController _animationController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fetchInternships();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchInternships() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Query with orderBy to get newest internships first
      QuerySnapshot querySnapshot = await _firestore
          .collection('interns')
          .orderBy('timestamp', descending: true)
          .get();

      // Convert QuerySnapshot to a List
      List<Map<String, dynamic>> internships = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data["id"] = doc.id; // Add ID to identify each internship
        return data;
      }).toList();

      // Process internships in parallel for better performance
      await Future.wait(
        internships.map((job) async {
          // Get company ID
          String companyId = job["companyId"] ?? "unknown";

          // Retrieve company name from company collection
          if (companyId != "unknown") {
            try {
              DocumentSnapshot companyDoc = await _firestore.collection('company').doc(companyId).get();
              if (companyDoc.exists) {
                var companyData = companyDoc.data() as Map<String, dynamic>;
                job["CompanyName"] = companyData["CompanyName"] ?? "Unknown Company";
              }
            } catch (e) {
              print("Error fetching company data: $e");
            }
          }

          job["img_url"] = await _getCompanyImageUrl(companyId);

          // Format dates if available
          if (job["timestamp"] != null) {
            try {
              if (job["timestamp"] is Timestamp) {
                job["formattedDate"] = DateFormat('MMM d, yyyy').format(job["timestamp"].toDate());
              }
            } catch (e) {
              print("Error formatting date: $e");
            }
          }
        }),
      );

      setState(() {
        jobList = internships;
        _isLoading = false;
      });

      // Start animation
      _animationController.forward();
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getCompanyImageUrl(String companyId) async {
    try {
      // Query by company_id
      final response = await _supabase
          .from('companies_profile')
          .select('img_url')
          .eq('company_id', companyId)
          .maybeSingle();

      final imgPath = response?['img_url'];

      if (imgPath != null) {
        // Check if it's already a full URL
        if (imgPath.toString().startsWith('http')) {
          return imgPath;
        } else {
          // Generate public URL from storage
          final String imageUrl = _supabase
              .storage
              .from('company-profile-img')
              .getPublicUrl(imgPath);
          return imageUrl;
        }
      }

      return null;
    } catch (e) {
      print("Error fetching company image for $companyId: $e");
      return null;
    }
  }


  Future<bool> _checkIfSaved(String internshipId) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      var snapshot = await _firestore
          .collection('Saved_Internships')
          .where('internshipId', isEqualTo: internshipId)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking saved status: $e");
      return false;
    }
  }

  List<Map<String, dynamic>> _getFilteredJobs() {
    final query = _searchQuery.toLowerCase();

    return jobList.where((job) {
      final title = job["title"]?.toString().toLowerCase() ?? "";
      final company = job["CompanyName"]?.toString().toLowerCase() ?? "";
      final location = job["location"]?.toString().toLowerCase() ?? "";
      final jobType = job["type"]?.toString().toLowerCase() ?? ""; // لازم يكون عندك type في بيانات التدريب

      bool matchesSearch = title.contains(query) || company.contains(query) || location.contains(query);
      bool matchesCategory = _selectedCategory == "All" || jobType == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final filteredJobs = _getFilteredJobs();

    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFFF9FAFC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),
              _buildHeader(screenWidth),
              SizedBox(height: screenHeight * 0.02),
              _buildSearchBar(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.015),
              _buildCategoriesRow(screenWidth),
              SizedBox(height: screenHeight * 0.015),
              _buildInternshipsHeader(screenWidth, filteredJobs.length),
              SizedBox(height: screenHeight * 0.01),
              _isLoading
                  ? _buildLoadingShimmer(screenWidth, screenHeight)
                  : _buildInternshipsList(filteredJobs, screenWidth, screenHeight),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingChatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome To Your Future!",
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Color(0xFF196AB3),
              ),
            ),
            Text(
              "Find your perfect internship",
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(double screenWidth, double screenHeight) {
    return Container(
      height: screenHeight * 0.06,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(color: Colors.black87),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Search internships...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: screenWidth * 0.04),
          prefixIcon: Icon(Icons.search, color: Color(0xFF196AB3), size: screenWidth * 0.055),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategoriesRow(double screenWidth) {
    final categories = [
      {"name": "All", "icon": Icons.all_inclusive},
      {"name": "Remote", "icon": Icons.home_work},
      {"name": "Full Time", "icon": Icons.work},
      {"name": "Part Time", "icon": Icons.schedule},
    ];

    return SizedBox(
      height: screenWidth * 0.12,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category["name"];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category["name"] as String;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF196AB3) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF196AB3)),
              ),
              child: Row(
                children: [
                  Icon(category["icon"] as IconData, size: 18, color: isSelected ? Colors.white : Color(0xFF196AB3)),
                  SizedBox(width: 6),
                  Text(
                    category["name"] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Color(0xFF196AB3),
                      fontWeight: FontWeight.w500,
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

  Widget _buildInternshipsHeader(double screenWidth, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Latest Internships",
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          "$count results",
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer(double screenWidth, double screenHeight) {
    return Expanded(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.02),
              child: Container(
                height: screenHeight * 0.15,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInternshipsList(List<Map<String, dynamic>> jobs, double screenWidth, double screenHeight) {
    if (jobs.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: screenWidth * 0.15,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                "No internships found",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              if (_searchQuery.isNotEmpty)
                Text(
                  "Try different search terms",
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return FutureBuilder<bool>(
            future: _checkIfSaved(job["id"]),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;
              // Apply staggered animation
              final animation = Tween<Offset>(
                begin: Offset(0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (1 / jobs.length) * index,
                    min(1, (1 / jobs.length) * (index + 3)),
                    curve: Curves.easeOutQuart,
                  ),
                ),
              );

              return SlideTransition(
                position: animation,
                child: FadeTransition(
                  opacity: _animationController,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                    child: _buildJobCard(job, screenWidth, screenHeight, isSaved),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, double screenWidth, double screenHeight, bool isSaved) {
    final internshipId = job["id"];
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final imageUrl = job["img_url"];
    final postedDate = job["formattedDate"] ?? "Recently";

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCompanyLogo(job, imageUrl, screenWidth),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job["title"] ?? "Unknown Title",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.042,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      job["CompanyName"] ?? "Unknown Company",
                      style: TextStyle(
                        color: Color(0xFF196AB3),
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.035,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Color(0xFF196AB3) : Colors.grey,
                ),
                onPressed: () async {
                  if (!isSaved) {
                    await _firestore.collection('Saved_Internships').add({
                      "internshipId": internshipId,
                      "userId": userId,
                      "savedAt": FieldValue.serverTimestamp(),
                    });
                  } else {
                    var snapshot = await _firestore
                        .collection('Saved_Internships')
                        .where('internshipId', isEqualTo: internshipId)
                        .where('userId', isEqualTo: userId)
                        .get();
                    for (var doc in snapshot.docs) {
                      await doc.reference.delete();
                    }
                  }
                  setState(() {});
                },
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  job["location"] ?? "Unknown Location",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: screenWidth * 0.033,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Posted: $postedDate",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: screenWidth * 0.03,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(job["type"] ?? "Unknown Type", Icons.work_outline),
              _buildTag(job["internship"] ?? "Internship", Icons.school_outlined),
              if (job["salary"] != null)
                _buildTag("\$${job["salary"]}", Icons.attach_money),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.045,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InternshipDetailsScreen(internshipData: job),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF196AB3),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "View Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogo(Map<String, dynamic> job, String? imageUrl, double screenWidth) {
    return Hero(
      tag: "company-${job["id"]}",
      child: Container(
        width: screenWidth * 0.15,
        height: screenWidth * 0.15,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: imageUrl != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildCompanyInitial(job, screenWidth);
            },
          ),
        )
            : _buildCompanyInitial(job, screenWidth),
      ),
    );
  }

  Widget _buildCompanyInitial(Map<String, dynamic> job, double screenWidth) {
    final companyName = job["CompanyName"] ?? "?";
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : "?";

    // Generate a consistent color based on company name
    final colorIndex = companyName.codeUnitAt(0) % 5;
    final colors = [
      Color(0xFF196AB3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFF44336), // Red
      Color(0xFFFFC107), // Amber
      Color(0xFF9C27B0), // Purple
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors[colorIndex].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.06,
            color: colors[colorIndex],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color(0xFF196AB3).withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFF196AB3), size: 14),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Color(0xFF196AB3),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingChatButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatBotScreen()),
          );
        },
        backgroundColor: Color(0xFF196AB3),
        child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
        elevation: 0,
      ),
    );
  }
}