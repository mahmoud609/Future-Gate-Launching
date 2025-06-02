import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../details/internship_details_screen.dart';

class SavedInternshipScreen extends StatefulWidget {
  const SavedInternshipScreen({Key? key}) : super(key: key);

  @override
  State<SavedInternshipScreen> createState() => _SavedInternshipScreenState();
}

class _SavedInternshipScreenState extends State<SavedInternshipScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _savedInternships = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSavedInternships();
  }

  Future<void> _fetchSavedInternships() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not logged in';
        });
        return;
      }

      final snapshot = await _firestore
          .collection('Saved_Internships')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> tempList = [];
      for (var doc in snapshot.docs) {
        String internshipId = doc['internshipId'];
        var internshipDoc =
        await _firestore.collection('interns').doc(internshipId).get();
        if (internshipDoc.exists) {
          var data = internshipDoc.data()!;
          data['id'] = internshipId;
          data['savedDocId'] = doc.id;
          tempList.add(data);
        }
      }

      setState(() {
        _savedInternships = tempList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching internships: $e';
      });
    }
  }

  // 🔥 نفس الدالة من صفحة ChangePassword
  Future<void> _showCustomDialog(
      BuildContext context,
      String title,
      String message,
      Color color,
      ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  title == 'Success' ? Icons.check_circle : Icons.error,
                  color: color,
                  size: 50,
                ),
              ),
              SizedBox(height: 15),
              // العنوان
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 10),
              // الرسالة
              Text(
                message,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // زر التأكيد
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2252A1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSavedInternship(String savedDocId) async {
    try {
      await _firestore.collection('Saved_Internships').doc(savedDocId).delete();

      // Update state to remove the deleted internship
      setState(() {
        _savedInternships.removeWhere(
                (internship) => internship['savedDocId'] == savedDocId);
      });

      // ✅ رسالة نجاح
      await _showCustomDialog(
        context,
        'Success',
        'Internship removed successfully!',
        Colors.green,
      );

    } catch (e) {
      // ❌ رسالة خطأ
      await _showCustomDialog(
        context,
        'Error',
        'Failed to delete internship: $e',
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Saved Internships",
          style: TextStyle(
              color: Color(0xFF2252A1),
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoadingView() : _buildBody(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF2252A1),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading your internships...",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70, color: Colors.redAccent),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchSavedInternships,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2252A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }

    if (_savedInternships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 80,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No saved internships yet",
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Internships you bookmark will appear here for easy access",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSavedInternships,
      color: const Color(0xFF2252A1),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _savedInternships.length,
        itemBuilder: (context, index) {
          return InternshipCard(
            internship: _savedInternships[index],
            onDelete: _deleteSavedInternship,
          );
        },
      ),
    );
  }
}

class InternshipCard extends StatelessWidget {
  final Map<String, dynamic> internship;
  final Function(String) onDelete;

  const InternshipCard({
    Key? key,
    required this.internship,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasStipend =
        internship["stipend"] != null && internship["stipend"].toString().isNotEmpty;
    final bool hasPostedDate = internship["postedDate"] != null &&
        internship["postedDate"].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InternshipDetailsScreen(
                  internshipData: internship,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company logo placeholder
                      _buildCompanyLogo(),
                      const SizedBox(width: 12),
                      // Internship details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              internship["title"] ?? "Unknown Position",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF2A2D3E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              internship["company"] ?? "Unknown Company",
                              style: const TextStyle(
                                color: Color(0xFF2252A1),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    internship["location"] ?? "Remote",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Bookmark remove button
                      IconButton(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(
                          Icons.bookmark_remove,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Remove from saved',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tags row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (hasStipend)
                          _buildTag(
                              Icons.payments_outlined,
                              internship["stipend"],
                              Colors.green.shade50,
                              Colors.green.shade700),
                        if (hasPostedDate)
                          _buildTag(
                              Icons.calendar_today_outlined,
                              "Posted: ${internship["postedDate"]}",
                              Colors.blue.shade50,
                              Colors.blue.shade700),
                        _buildTag(
                            Icons.watch_later_outlined,
                            internship["duration"] ?? "Duration N/A",
                            Colors.purple.shade50,
                            Colors.purple.shade700),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // View details button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InternshipDetailsScreen(
                              internshipData: internship,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2252A1),
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2252A1),
            Colors.blue.shade300,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        _getCompanyInitials(internship["company"] ?? "Unknown"),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String? text, Color bgColor, Color textColor) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber,
                  color: Colors.red,
                  size: 50,
                ),
              ),
              SizedBox(height: 15),
              // العنوان
              Text(
                "Remove Internship",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              // الرسالة
              Text(
                "Are you sure you want to remove this internship from your saved list?",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // أزرار التأكيد والإلغاء
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete(internship['savedDocId']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text("Remove"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCompanyInitials(String companyName) {
    if (companyName.isEmpty) return "?";
    final words = companyName.split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}