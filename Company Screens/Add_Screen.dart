import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Student Screens/Features/home_screen.dart';

class AddScreen extends StatefulWidget {
  final String Id;
  const AddScreen({Key? key, required this.Id}) : super(key: key);

  @override
  _AddInternshipScreenState createState() => _AddInternshipScreenState();
}
class _AddInternshipScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers to handle validation and text field state
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _whatYouWillBeDoingController = TextEditingController();
  final _whatWeAreLookingForController = TextEditingController();
  final _preferredQualificationsController = TextEditingController();

  // Form values
  String internship = 'Internship';
  String type = 'On-site';
  String selectedField = 'Artificial Intelligence';
  bool _isLoading = false;

  // Error flags for form validation
  bool _titleErrorVisible = false;
  bool _locationErrorVisible = false;
  bool _durationErrorVisible = false;
  bool _whatYouWillBeDoingErrorVisible = false;
  bool _whatWeAreLookingForErrorVisible = false;
  bool _preferredQualificationsErrorVisible = false;

  final List<String> fieldsList = [
    'Artificial Intelligence',
    'Cloud Computing',
    'Cyber Security',
    'Data Analysis',
    'Data Science',
    'Embedded Systems',
    'Game Development',
    'Graphic Designer',
    'Internet Of Things (IOT)',
    'IT Project Management',
    'IT Support',
    'Machine Learning (ML)',
    'Mobile Application Development',
    'Network Management',
    'Software Development',
    'Systems Administration',
    'UI/UX Design',
    'Web Development',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    initOneSignal();
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _whatYouWillBeDoingController.dispose();
    _whatWeAreLookingForController.dispose();
    _preferredQualificationsController.dispose();
    super.dispose();
  }

  void initOneSignal() {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("a7907370-789c-4b08-b75d-88a68dd2490a");

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null && data['internshipId'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddScreen(Id: data['internshipId']),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add New Internship",
          style: GoogleFonts.poppins(
            color: const Color(0xFF2252A1),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Form content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDEE9FF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF2252A1)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This page allows companies to add new internship opportunities to the application, "
                                  "enabling students to register for these internships.",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic information section
                    sectionHeader("Basic Information"),
                    const SizedBox(height: 16),

                    buildModernTextField(
                      controller: _titleController,
                      label: "Internship Title",
                      icon: Icons.work_outline,
                      errorVisible: _titleErrorVisible,
                      errorText: "Please enter the internship title",
                    ),

                    buildModernTextField(
                      controller: _locationController,
                      label: "Location",
                      icon: Icons.location_on_outlined,
                      errorVisible: _locationErrorVisible,
                      errorText: "Please enter the location",
                    ),

                    buildModernDropdown(
                      label: "Internship Field",
                      icon: Icons.category_outlined,
                      value: selectedField,
                      items: fieldsList,
                      onChanged: (value) {
                        setState(() {
                          selectedField = value!;
                        });
                      },
                    ),

                    buildModernDropdown(
                      label: "Internship Type",
                      icon: Icons.business_outlined,
                      value: type,
                      items: const ["On-site", "Remote", "Hybrid"],
                      onChanged: (value) {
                        setState(() {
                          type = value!;
                        });
                      },
                    ),

                    buildModernTextField(
                      controller: _durationController,
                      label: "Duration (e.g., 3 months)",
                      icon: Icons.access_time_outlined,
                      errorVisible: _durationErrorVisible,
                      errorText: "Please enter the internship duration",
                    ),

                    const SizedBox(height: 24),
                    sectionHeader("Detailed Description"),
                    const SizedBox(height: 16),

                    buildModernTextArea(
                      controller: _whatYouWillBeDoingController,
                      label: "What You Will Be Doing",
                      icon: Icons.description_outlined,
                      errorVisible: _whatYouWillBeDoingErrorVisible,
                      errorText: "Please describe what interns will be doing",
                    ),

                    buildModernTextArea(
                      controller: _whatWeAreLookingForController,
                      label: "What We Are Looking For",
                      icon: Icons.person_search_outlined,
                      errorVisible: _whatWeAreLookingForErrorVisible,
                      errorText: "Please describe what you're looking for",
                    ),

                    buildModernTextArea(
                      controller: _preferredQualificationsController,
                      label: "Preferred Qualifications",
                      icon: Icons.verified_outlined,
                      errorVisible: _preferredQualificationsErrorVisible,
                      errorText: "Please enter preferred qualifications",
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : validateAndSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2252A1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : Text(
                          "Submit Internship",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFF2252A1),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool errorVisible,
    required String errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(
                color: errorVisible ? Colors.red.shade300 : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: errorVisible
                  ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
                  : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: errorVisible ? Colors.red.shade300 : const Color(0xFF2252A1),
                  size: 22,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (errorVisible)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Text(
                errorText,
                style: GoogleFonts.inter(
                  color: Colors.red.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildModernTextArea({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool errorVisible,
    required String errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(
                color: errorVisible ? Colors.red.shade300 : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: errorVisible
                  ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
                  : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: TextFormField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 12),
                  child: Icon(
                    icon,
                    color: errorVisible ? Colors.red.shade300 : const Color(0xFF2252A1),
                    size: 22,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                border: InputBorder.none,
                alignLabelWithHint: true,
              ),
            ),
          ),
          if (errorVisible)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Text(
                errorText,
                style: GoogleFonts.inter(
                  color: Colors.red.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildModernDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2252A1)),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF2252A1),
              size: 22,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: InputBorder.none,
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.black87,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void validateAndSubmit() {
    // Reset error flags
    setState(() {
      _titleErrorVisible = _titleController.text.trim().isEmpty;
      _locationErrorVisible = _locationController.text.trim().isEmpty;
      _durationErrorVisible = _durationController.text.trim().isEmpty;
      _whatYouWillBeDoingErrorVisible = _whatYouWillBeDoingController.text.trim().isEmpty;
      _whatWeAreLookingForErrorVisible = _whatWeAreLookingForController.text.trim().isEmpty;
      _preferredQualificationsErrorVisible = _preferredQualificationsController.text.trim().isEmpty;
    });

    // Check if any errors exist
    if (_titleErrorVisible ||
        _locationErrorVisible ||
        _durationErrorVisible ||
        _whatYouWillBeDoingErrorVisible ||
        _whatWeAreLookingForErrorVisible ||
        _preferredQualificationsErrorVisible) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Proceed with form submission
    _submitForm();
  }

  void _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentReference docRef = _firestore.collection('interns').doc();

      await docRef.set({
        "internshipId": docRef.id,
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'field': selectedField,
        'internship': internship,
        'type': type,
        'duration': _durationController.text.trim(),
        'whatYouWillBeDoing': _whatYouWillBeDoingController.text.trim(),
        'whatWeAreLookingFor': _whatWeAreLookingForController.text.trim(),
        'preferredQualifications': _preferredQualificationsController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'companyId': widget.Id,
      });

      // Success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                "Internship Added Successfully!",
                style: GoogleFonts.inter(),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );

      // Send notification
      await sendOneSignalNotification(
        title: "New Internship in $selectedField!",
        message: "${_titleController.text} - ${_locationController.text}",
        data: {
          "internshipId": docRef.id,
          "title": _titleController.text,
          "location": _locationController.text,
          "field": selectedField,
        },
      );

      // Reset form
      _titleController.clear();
      _locationController.clear();
      _durationController.clear();
      _whatYouWillBeDoingController.clear();
      _whatWeAreLookingForController.clear();
      _preferredQualificationsController.clear();

    } catch (e) {
      // Error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text("Failed to add internship: $e")),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> sendOneSignalNotification({
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    final String oneSignalAppId = dotenv.get('ONESIGNAL_APP_ID', fallback: '');
    final String oneSignalApiKey = dotenv.get('ONESIGNAL_API_KEY', fallback: '');

    if (oneSignalAppId.isEmpty || oneSignalApiKey.isEmpty) {
      print('❌ OneSignal API credentials are missing!');
      return;
    }

    try {
      QuerySnapshot interestedUsers = await _firestore
          .collection('User_Field')
          .where('Interested_Fields', arrayContains: selectedField)
          .get();

      if (interestedUsers.docs.isEmpty) {
        print('No users interested in $selectedField');
        return;
      }

      List<String> playerIds = [];
      for (var doc in interestedUsers.docs) {
        var userDoc = await _firestore.collection('users').doc(doc['userId']).get();
        if (userDoc.exists && userDoc['playerId'] != null) {
          playerIds.add(userDoc['playerId']);
        }
      }

      if (playerIds.isEmpty) {
        print('No player IDs found for interested users');
        return;
      }

      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Basic $oneSignalApiKey',
        },
        body: jsonEncode({
          'app_id': oneSignalAppId,
          'include_player_ids': playerIds,
          'contents': {'en': message},
          'headings': {'en': title},
          'data': data,
        }),
      );

      print('Notification sent to ${playerIds.length} users interested in $selectedField');
      print('Response status: ${response.statusCode}');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}