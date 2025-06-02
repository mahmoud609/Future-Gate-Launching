import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ApplicantsScreen extends StatefulWidget {
  final String internshipId;
  final String internshipTitle;
  static const String routeName = "/ApplicantsScreen";

  const ApplicantsScreen({
    Key? key,
    required this.internshipId,
    required this.internshipTitle,
  }) : super(key: key);

  @override
  _ApplicantsScreenState createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final List<String> _statusFilters = ['All', 'Pending', 'Accepted', 'Rejected'];
  String _currentFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Applicants', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF196AB3),
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildStatusFilter(),
          Expanded(
            child: _buildApplicantsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.internshipTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Student_Applicant')
                .where('internshipId', isEqualTo: widget.internshipId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Loading applicants...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                );
              }

              final applicantsCount = snapshot.data?.docs.length ?? 0;
              return Text(
                '$applicantsCount Total Applicants',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((filter) {
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: _currentFilter == filter,
                onSelected: (selected) {
                  setState(() {
                    _currentFilter = selected ? filter : 'All';
                  });
                },
                selectedColor: Color(0xFF196AB3),
                labelStyle: TextStyle(
                  color: _currentFilter == filter ? Colors.white : Colors.black87,
                ),
                backgroundColor: Colors.grey[200],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildApplicantsList() {
    Query query = FirebaseFirestore.instance
        .collection('Student_Applicant')
        .where('internshipId', isEqualTo: widget.internshipId);

    if (_currentFilter != 'All') {
      query = query.where('status', isEqualTo: _currentFilter.toLowerCase());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading applicants'));
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No applicants found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final applicant = snapshot.data!.docs[index];
            final data = applicant.data() as Map<String, dynamic>;

            return _buildApplicantCard(
              name: data['studentName'] ?? 'No Name',
              university: data['university'] ?? 'Unknown University',
              applicationDate: data['applicationDate']?.toDate() ?? DateTime.now(),
              status: data['status'] ?? 'pending',
              onStatusChanged: (newStatus) {
                _updateApplicantStatus(applicant.id, newStatus);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildApplicantCard({
    required String name,
    required String university,
    required DateTime applicationDate,
    required String status,
    required Function(String) onStatusChanged,
  }) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(applicationDate);
    Color statusColor = Colors.grey;

    if (status == 'accepted') {
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF196AB3),
                  child: Text(
                    name.substring(0, 1),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        university,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Applied on $formattedDate',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      onStatusChanged('rejected');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Color(0xFF196AB3), // تم تغيير primary إلى backgroundColor
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Reject'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onStatusChanged('accepted');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF196AB3), // تم تغيير primary إلى backgroundColor
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateApplicantStatus(String applicantId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('Student_Applicant')
          .doc(applicantId)
          .update({'status': newStatus});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }
}