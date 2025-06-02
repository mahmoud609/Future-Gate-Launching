import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'CvViewerPage.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ViewStudentsInfo extends StatefulWidget {
  final String internshipId;
  const ViewStudentsInfo({Key? key, required this.internshipId}) : super(key: key);

  @override
  _ViewStudentsInfoState createState() => _ViewStudentsInfoState();
}

class _ViewStudentsInfoState extends State<ViewStudentsInfo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool isLoading = true;
  List<Map<String, dynamic>> applicants = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    print('Received Internship ID: ${widget.internshipId}');
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 1))..repeat(reverse: true);
    _rotationAnimation = Tween<double>(begin: 0, end: 3.14).animate(_controller);
    loadApplicants();
  }

  Future<void> loadApplicants() async {
    try {
      setState(() => isLoading = true);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Student_Applicant')
          .where('internshipId', isEqualTo: widget.internshipId)
          .get();

      List<Map<String, dynamic>> tempApplicants = [];
      List<Future<void>> futures = [];

      for (var doc in querySnapshot.docs) {
        futures.add(_processApplicant(doc, tempApplicants));
      }

      await Future.wait(futures);

      setState(() {
        applicants = tempApplicants;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print("Error loading applicants: $e");
      print("Stack trace: $stackTrace");
      setState(() => isLoading = false);
    }
  }

  Future<void> _processApplicant(
      QueryDocumentSnapshot doc, List<Map<String, dynamic>> tempApplicants) async {
    try {
      final docData = doc.data() as Map<String, dynamic>? ?? {};
      final userId = docData['userId'] as String?;
      final cvType = docData['cvType'] as String? ?? 'built';
      final uploadMethod = docData['uploadMethod'] as String? ?? 'built';

      if (userId == null || userId.isEmpty) return;

      // 1. Get basic user information
      final userData = await _fetchUserData(userId);
      if (userData == null) return;

      String fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
      if (fullName.isEmpty) fullName = 'Unknown';

      // 2. Handle CV data based on upload method
      final cvInfo = {
        'cvData': docData['cvId'] ?? userId,
        'cvType': cvType,
        'uploadMethod': uploadMethod,
      };

      // 3. Get assessment results
      final assessmentResults = await _fetchAssessmentResults(userId);

      // 4. Get interested fields
      final interestedFields = await _fetchInterestedFields(userId);

      // 5. Get CV details (Build_CV)
      final cvDetails = await _fetchCvDetails(userId);

      // Compile all data into one object
      tempApplicants.add({
        "id": doc.id,
        "name": fullName,
        "cv": cvInfo['cvData'],
        "cvType": cvInfo['cvType'],
        "uploadMethod": cvInfo['uploadMethod'],
        "accepted": docData['status'] == 'accepted',
        "appliedAt": docData['appliedAt'] ?? Timestamp.now(),
        "userId": userId,
        "email": userData['email'] ?? '',
        "phone": userData['phone'] ?? '',
        "assessmentResults": assessmentResults,
        "interestedFields": interestedFields,
        "cvDetails": cvDetails,
        "userData": {
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'dateOfBirth': userData['dateOfBirth'] ?? '',
          'gender': userData['gender'] ?? '',
          'city': userData['city'] ?? '',
          'university': userData['university'] ?? '',
          'faculty': userData['faculty'] ?? '',
          'academicYear': userData['level'] ?? '',
          'nationalId': cvDetails['nationalId'] ?? '',
          'email': userData['email'] ?? '',
          'phone': userData['phone'] ?? '',
          'skills': cvDetails['skills'] ?? [],
          'experiences': cvDetails['Work_Experience'] ?? [],
        },
      });
    } catch (e, stackTrace) {
      print("Error processing applicant ${doc.id}: $e");
      print("Stack trace: $stackTrace");
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;
      return userDoc.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchCvDetails(String userId) async {
    Map<String, dynamic> cvDetails = {
      'gpa': 'N/A',
      'nationalId': '',
      'skills': [],
      'Work_Experience': [],
      'Courses': [],
      'languages': [],
      'education': null,
    };

    try {
      DocumentSnapshot cvDoc = await FirebaseFirestore.instance
          .collection('Build_CV')
          .doc(userId)
          .get();

      if (cvDoc.exists) {
        final cvData = cvDoc.data() as Map<String, dynamic>;
        cvDetails['gpa'] = cvData['gpa']?.toString() ?? 'N/A';
        cvDetails['nationalId'] = cvData['nationalId'] ?? '';
        cvDetails['skills'] = List<String>.from(cvData['skills'] ?? []);

        // Get education
        final educationQuery = await cvDoc.reference.collection('Education').get();
        if (educationQuery.docs.isNotEmpty) {
          cvDetails['education'] = educationQuery.docs.first.data();
        }

        // Get work experience
        final workExpQuery = await cvDoc.reference.collection('Work_Experience').get();
        cvDetails['Work_Experience'] = workExpQuery.docs.map((doc) => doc.data()).toList();

        // Get courses
        final coursesQuery = await cvDoc.reference.collection('Courses').get();
        cvDetails['Courses'] = coursesQuery.docs.map((doc) => doc.data()).toList();

        // Get languages
        final languagesQuery = await cvDoc.reference.collection('Language').get();
        cvDetails['languages'] = languagesQuery.docs.map((doc) => doc.data()).toList();
      }
    } catch (e) {
      print("Error fetching CV details: $e");
    }

    return cvDetails;
  }

  Future<List<Map<String, dynamic>>> _fetchAssessmentResults(String userId) async {
    try {
      QuerySnapshot assessmentSnapshot = await FirebaseFirestore.instance
          .collection('Assessment_Results')
          .where('UserId', isEqualTo: userId)
          .get();

      return assessmentSnapshot.docs.map((aDoc) {
        final data = aDoc.data() as Map<String, dynamic>;
        return {
          'id': aDoc.id,
          'assessmentId': data['AssessmentId'],
          'level': data['level'] ?? 'No Level',
          'percentage': data['percentage'] ?? 0,
          'quizTitle': data['quizTitle'] ?? 'No Title',
          'score': data['score'] ?? 0,
          'totalQuestions': data['totalQuestions'] ?? 0,
          'date': data['timestamp'] ?? Timestamp.now(),
        };
      }).toList();
    } catch (e) {
      print("Error fetching assessment results: $e");
      return [];
    }
  }

  Future<List<String>> _fetchInterestedFields(String userId) async {
    try {
      QuerySnapshot fieldSnapshot = await FirebaseFirestore.instance
          .collection('User_Field')
          .where('userId', isEqualTo: userId)
          .get();

      if (fieldSnapshot.docs.isNotEmpty) {
        final fieldData = fieldSnapshot.docs.first.data() as Map<String, dynamic>;
        return List<String>.from(fieldData['Interested_Fields'] ?? []);
      }
      return [];
    } catch (e) {
      print("Error fetching interested fields: $e");
      return [];
    }
  }

  Future<void> acceptApplicant(int index) async {
    try {
      String docId = applicants[index]["id"];
      String applicantUserId = applicants[index]["userId"];
      String applicantName = applicants[index]["name"];

      // 1. Get the Student_Applicant document
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Student_Applicant')
          .doc(docId)
          .get();

      if (!docSnapshot.exists) {
        print("Student_Applicant document does not exist");
        return;
      }

      Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

      if (data == null || data['internshipId'] == null) {
        print("internshipId not found in Student_Applicant");
        return;
      }

      String internshipId = data['internshipId'];

      // 2. Get the internship document to get companyId
      DocumentSnapshot internshipDoc = await FirebaseFirestore.instance
          .collection('interns')
          .doc(internshipId)
          .get();

      if (!internshipDoc.exists || internshipDoc['companyId'] == null) {
        print("Internship document or companyId not found");
        return;
      }

      String companyId = internshipDoc['companyId'];

      // 3. Update Student_Applicant with accepted status and companyId
      await FirebaseFirestore.instance
          .collection('Student_Applicant')
          .doc(docId)
          .update({
        'status': 'accepted',
        'companyId': companyId,
      });

      // 4. Get player's ID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(applicantUserId)
          .get();

      if (!userDoc.exists || userDoc['playerId'] == null) {
        print("User document or playerId not found");
        return;
      }

      String playerId = userDoc['playerId'];

      // 5. Send OneSignal notification
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Basic ${dotenv.get('ONESIGNAL_API_KEY')}',
        },
        body: jsonEncode({
          'app_id': dotenv.get('ONESIGNAL_APP_ID'),
          'include_player_ids': [playerId],
          'contents': {'en': 'Congratulations! Your application has been accepted.'},
          'headings': {'en': 'Application Accepted'},
          'data': {
            'type': 'application_accepted',
            'applicantId': docId,
            'status': 'accepted'
          },
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to send notification: ${response.body}');
      }

      // 6. Update UI
      setState(() {
        applicants[index]["accepted"] = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You have accepted $applicantName!"),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF2252A1),
        ),
      );
    } catch (e) {
      print("Error accepting applicant: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to accept applicant")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Students Info", style: TextStyle(color: Color(0xFF2252A1), fontSize: 21, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Icon(Icons.hourglass_empty, size: 60, color: Color(0xFF2252A1)),
              );
            },
          ),
        )
            : Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: applicants.isEmpty
                  ? Center(child: Text("No applicants found for this internship"))
                  : ListView.builder(
                itemCount: applicants.where((a) => a["name"].toLowerCase().contains(searchQuery)).length,
                itemBuilder: (context, index) {
                  final filtered = applicants.where((a) => a["name"].toLowerCase().contains(searchQuery)).toList();
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: buildApplicantBox(filtered, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildApplicantBox(List<Map<String, dynamic>> list, int index) {
    final applicant = list[index];
    final isAccepted = applicant["accepted"];
    final cvType = applicant["cvType"];
    final uploadMethod = applicant["uploadMethod"];
    final cvData = applicant["cv"];
    final appliedAt = applicant["appliedAt"] as Timestamp;
    final appliedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(appliedAt.toDate());

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isAccepted ? Colors.grey : Color(0xFF2252A1)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF2252A1).withOpacity(0.1),
                child: Icon(Icons.person, color: Color(0xFF2252A1)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant["name"],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      applicant["email"],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Applied on: $appliedDate",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0x5490CAF9),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                cvType == 'built' ? 'Built CV' : 'Uploaded CV (PDF)',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: isAccepted ? null : () => acceptApplicant(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAccepted ? Colors.grey : Color(0xFF2252A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Text(
                    isAccepted ? "Accepted" : "Accept",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CvViewerPage(
                        applicantData: {
                          "cvType": cvType,
                          "uploadMethod": uploadMethod,
                          "cv": cvData,
                          "userId": applicant["userId"],
                          "name": applicant["name"],
                          "userData": applicant["userData"],
                          "assessmentResults": applicant["assessmentResults"],
                          "interestedFields": applicant["interestedFields"],
                          "appliedAt": applicant["appliedAt"],
                          "gpa": applicant["cvDetails"]["gpa"] ?? "N/A",
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2252A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Text("View CV", style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }
}