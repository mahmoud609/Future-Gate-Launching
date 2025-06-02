import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class CvViewerPage extends StatefulWidget {
  final Map<String, dynamic> applicantData;
  const CvViewerPage({Key? key, required this.applicantData}) : super(key: key);

  @override
  _CvViewerPageState createState() => _CvViewerPageState();
}

class _CvViewerPageState extends State<CvViewerPage> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? pdfPath;
  TabController? _tabController;
  bool isPdfLoading = false;
  final supabase = Supabase.instance.client;

  // Data from Build_CV subcollections
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> languages = [];
  List<Map<String, dynamic>> workExperiences = [];

  // Assessment results data
  List<Map<String, dynamic>> assessmentResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load PDF or additional data
    if (widget.applicantData["uploadMethod"] == "upload") {
      _downloadPDF(widget.applicantData["cv"]);
    } else {
      _loadBuildCVData();
    }

    // Load assessment results separately
    _loadAssessmentResultsAndUpdate();
  }

  Future<void> _loadBuildCVData() async {
    try {
      final userId = widget.applicantData['userId'];
      if (userId == null) throw Exception('User ID not found');

      // Reference to the Build_CV document
      final buildCvDoc = FirebaseFirestore.instance
          .collection('Build_CV')
          .doc(userId);

      // Load data from subcollections
      final coursesQuery = await buildCvDoc.collection('Courses').get();
      final languagesQuery = await buildCvDoc.collection('Language').get();
      final workExpQuery = await buildCvDoc.collection('Work_Experience').get();
      final educationQuery = await buildCvDoc.collection('Education').get();

      setState(() {
        courses = coursesQuery.docs.map((doc) => doc.data()).toList();
        languages = languagesQuery.docs.map((doc) => doc.data()).toList();
        workExperiences = workExpQuery.docs.map((doc) => doc.data()).toList();

        // If there's education, add it to user data
        if (educationQuery.docs.isNotEmpty) {
          widget.applicantData["userData"].addAll({
            'degree': educationQuery.docs.first['degree'] ?? '',
            'major': educationQuery.docs.first['major'] ?? '',
            'university': educationQuery.docs.first['university'] ?? '',
          });
        }

        isLoading = false;
      });
    } catch (e) {
      print('Error loading Build_CV data: $e');
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load CV details: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadAssessmentResults() async {
    try {
      final userId = widget.applicantData['userId'];
      if (userId == null) return [];

      // Query the Assessment_result collection for this user
      final assessmentQuery = await FirebaseFirestore.instance
          .collection('Assessment_result')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true) // Most recent first
          .get();

      return assessmentQuery.docs.map((doc) {
        final data = doc.data();
        // Convert timestamp to a readable format if needed
        if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
          data['formattedDate'] = DateFormat('MMM dd, yyyy - hh:mm a')
              .format((data['timestamp'] as Timestamp).toDate());
        }
        return data;
      }).toList();
    } catch (e) {
      print('Error loading assessment results: $e');
      return [];
    }
  }

  Future<void> _loadAssessmentResultsAndUpdate() async {
    final results = await _loadAssessmentResults();
    setState(() {
      assessmentResults = results;
    });
  }

  Future<void> _downloadPDF(String url) async {
    try {
      setState(() {
        isPdfLoading = true;
      });

      final response = await http.get(Uri.parse(url));
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/temp_cv.pdf';

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        pdfPath = filePath;
        isPdfLoading = false;
        isLoading = false;
      });
    } catch (e) {
      print('Error downloading PDF: $e');
      setState(() {
        isPdfLoading = false;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.applicantData["userData"] as Map<String, dynamic>;
    final interestedFields = widget.applicantData["interestedFields"] as List<dynamic>;
    final appliedAt = widget.applicantData["appliedAt"] as Timestamp;
    final appliedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(appliedAt.toDate());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            widget.applicantData["name"],
            style: TextStyle(color: Color(0xFF2252A1), fontSize: 21, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2252A1)))
          : Column(
        children: [
          // Profile header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF2252A1), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(widget.applicantData["name"]),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 20),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.applicantData["name"],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2252A1),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              userData["email"] ?? "No email",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            userData["phone"] ?? "No phone",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            "Applied on: $appliedDate",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xFF2252A1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF2252A1),
              tabs: [
                Tab(text: "Profile"),
                Tab(text: "CV Details"),
                Tab(text: "Skills"),
                Tab(text: "Assessment"),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(userData),
                _buildCVTab(),
                _buildSkillsTab(userData, interestedFields),
                _buildAssessmentTab(assessmentResults),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Profile Tab
  Widget _buildProfileTab(Map<String, dynamic> userData) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Personal Information"),
          _buildInfoCard([
            _buildInfoRow("Full Name", "${userData['firstName']} ${userData['lastName']}"),
            _buildInfoRow("Gender", userData['gender'] ?? "Not specified"),
            _buildInfoRow("Date of Birth", userData['dateOfBirth'] ?? "Not specified"),
            _buildInfoRow("National ID", userData['nationalId'] ?? "Not specified"),
            _buildInfoRow("Location", userData['city'] ?? "Not specified"),
          ]),

          SizedBox(height: 20),

          _buildSectionTitle("Academic Information"),
          _buildInfoCard([
            _buildInfoRow("University", userData['university'] ?? "Not specified"),
            _buildInfoRow("Faculty", userData['faculty'] ?? "Not specified"),
            _buildInfoRow("Academic Year", userData['academicYear'] ?? "Not specified"),
            _buildInfoRow("GPA", widget.applicantData["gpa"]?.toString() ?? "Not specified"),
          ]),

          SizedBox(height: 20),

          _buildSectionTitle("Contact Information"),
          _buildInfoCard([
            _buildInfoRow("Email", userData['email'] ?? "Not specified", isEmail: true),
            _buildInfoRow("Phone", userData['phone'] ?? "Not specified", isPhone: true),
          ]),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  // CV Tab
  Widget _buildCVTab() {
    if (widget.applicantData["uploadMethod"] == "upload" && pdfPath != null) {
      return isPdfLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2252A1)))
          : Container(
        padding: EdgeInsets.all(8),
        child: PDFView(
          filePath: pdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
        ),
      );
    } else if (widget.applicantData["uploadMethod"] == "upload" && isPdfLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2252A1)),
            SizedBox(height: 16),
            Text("Loading PDF...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else if (widget.applicantData["uploadMethod"] == "upload") {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Unable to load PDF", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: widget.applicantData["cv"] != null
                  ? () => _downloadPDF(widget.applicantData["cv"])
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2252A1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text("Try Again", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } else {
      // Built-in CV View
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Courses Section
            _buildSectionTitle("Courses"),
            courses.isEmpty
                ? _buildEmptyState("No courses recorded")
                : Column(
                children: courses.map((course) => _buildCourseCard(course)).toList()
            ),

            // Languages Section
            SizedBox(height: 20),
            _buildSectionTitle("Languages"),
            languages.isEmpty
                ? _buildEmptyState("No language skills recorded")
                : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languages.map((lang) => _buildLanguageChip(lang)).toList()
            ),

            // Work Experience Section
            SizedBox(height: 20),
            _buildSectionTitle("Work Experience"),
            workExperiences.isEmpty
                ? _buildEmptyState("No work experience added")
                : Column(
                children: workExperiences.map((exp) => _buildExperienceCard(exp)).toList()
            ),

            SizedBox(height: 40),
          ],
        ),
      );
    }
  }

  // Skills Tab
  Widget _buildSkillsTab(Map<String, dynamic> userData, List<dynamic> interestedFields) {
    final skills = userData['skills'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Technical Skills"),
          skills.isEmpty
              ? _buildEmptyState("No skills added")
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
                skills.length,
                    (index) => _buildSkillChip(skills[index].toString())
            ),
          ),

          SizedBox(height: 24),

          _buildSectionTitle("Interested Fields"),
          interestedFields.isEmpty
              ? _buildEmptyState("No interested fields added")
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
                interestedFields.length,
                    (index) => _buildInterestChip(interestedFields[index].toString())
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  // Assessment Tab
  Widget _buildAssessmentTab(List<dynamic> assessmentResults) {
    return assessmentResults.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No assessment results available",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    )
        : ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: assessmentResults.length,
      itemBuilder: (context, index) {
        final assessment = assessmentResults[index] as Map<String, dynamic>;
        return _buildAssessmentCard(assessment);
      },
    );
  }

  // UI Helper Methods
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2252A1),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: isEmail
                ? GestureDetector(
              onTap: () => _launchEmail(value),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2252A1),
                  decoration: TextDecoration.underline,
                ),
              ),
            )
                : isPhone
                ? GestureDetector(
              onTap: () => _launchPhone(value),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2252A1),
                  decoration: TextDecoration.underline,
                ),
              ),
            )
                : Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course['courseName'] ?? 'Course Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2252A1),
              ),
            ),
            SizedBox(height: 4),
            Text(
              course['companyName'] ?? 'Company Name',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              "Duration: ${course['duration'] ?? 'N/A'} - ${course['startDate'] ?? 'N/A'} to ${course['endDate'] ?? 'N/A'}",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip(Map<String, dynamic> lang) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFD6E0FF)),
      ),
      child: Text(
        "${lang['language'] ?? 'Language'} (${lang['level'] ?? 'Level'})",
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF2252A1),
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFBBDEFB)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF2252A1),
        ),
      ),
    );
  }

  Widget _buildInterestChip(String interest) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFC8E6C9)),
      ),
      child: Text(
        interest,
        style: TextStyle(
          fontSize: 13,
          color: Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> experience) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              experience['jobTitle'] ?? 'Job Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2252A1),
              ),
            ),
            SizedBox(height: 4),
            Text(
              experience['companyName'] ?? 'Company Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "${experience['jobType'] ?? 'Job Type'} • ${experience['startDate'] ?? 'Start'} - ${experience['endDate'] ?? 'End'}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment) {
    final percentage = (assessment['percentage'] as num? ?? 0).toDouble();
    final scoreColor = percentage >= 70
        ? Colors.green[700]
        : percentage >= 50
        ? Colors.orange[700]
        : Colors.red[700];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    assessment['assessmentName'] ?? "Unknown Assessment",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2252A1),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: scoreColor ?? Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Add date information
            if (assessment['formattedDate'] != null)
              Text(
                "Completed: ${assessment['formattedDate']}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildAssessmentItem(
                  "Level",
                  assessment['level'] ?? "N/A",
                  Icons.bar_chart,
                ),
                SizedBox(width: 16),
                _buildAssessmentItem(
                  "Score",
                  "${assessment['score'] ?? 0}/${assessment['totalQuestions'] ?? 0}",
                  Icons.quiz,
                ),
              ],
            ),
            SizedBox(height: 8),
            // Add more detailed stats
            Row(
              children: [
                _buildAssessmentStatItem("Correct", assessment['totalCorrectAnswers'] ?? 0, Colors.green),
                SizedBox(width: 8),
                _buildAssessmentStatItem("Wrong", assessment['totalWrongAnswers'] ?? 0, Colors.red),
                SizedBox(width: 8),
                _buildAssessmentStatItem("Missed", assessment['totalMissedAnswers'] ?? 0, Colors.orange),
              ],
            ),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  scoreColor ?? Colors.grey,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey,
          ),
          SizedBox(width: 4),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method for assessment statistics
  Widget _buildAssessmentStatItem(String label, int value, Color? color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.grey,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color ?? Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(" ");
    if (nameParts.length > 1) {
      return "${nameParts[0][0]}${nameParts[1][0]}".toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return "?";
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}